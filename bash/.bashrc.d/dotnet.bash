export DOTNET_ROOT=$HOME/.dotnet
export PATH=$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH

# Added by get-aspire-cli.sh
export PATH="$HOME/.aspire/bin:$PATH"

asplog() {
  local container="portalsdashboard"

  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    echo "Container $container is not running"
    echo "Start with: docker compose -f docker-compose.local.yml up -d"
    return 1
  fi

  rm -f /tmp/trace_*.json

  cat > /tmp/aspire_preview.sh << 'PREVIEW'
#!/bin/bash
tid=$(echo "$1" | tr -d '[:space:]')
file="/tmp/trace_${tid}.json"
if [ -f "$file" ]; then
    cat "$file"
else
    echo "File not found: $file"
    echo "Trace ID: '$tid'"
    ls /tmp/trace_*.json 2>/dev/null || echo "No trace files found"
fi
PREVIEW
  chmod +x /tmp/aspire_preview.sh

  local script="/tmp/aspire_parser.py"
  cat > "$script" << 'PYEOF'
# -*- coding: utf-8 -*-
import sys, re, json
from urllib.parse import urlparse

SKIP_TAGS = {
    'http.request.method', 'url.path', 'url.scheme',
    'http.response.status_code', 'network.protocol.version',
    'telemetry.sdk.name', 'telemetry.sdk.language', 'telemetry.sdk.version',
    'user_agent.original', 'server.address', 'server.port',
    '{OriginalFormat}',
    'SpanId', 'TraceId', 'ParentId',
    'RequestId', 'ConnectionId',
    'ElapsedMilliseconds', 'ExecutionTimeMs',
    'PipelineInstance', 'Attempt', 'Handled',
}

KIND_COLOR = {
    'Client':   '\033[36m',
    'Server':   '\033[34m',
    'Internal': '\033[90m',
    'Producer': '\033[33m',
    'Consumer': '\033[33m',
}

def parse_value(s):
    s = s.strip()
    m = re.match(r'\w+\((.+)\)$', s)
    return m.group(1) if m else s

def strip_prefix(line):
    return re.sub(r'^\d{4}-\d{2}-\d{2}T[\d:.Z]+\s+\w+\s+\S+\s*', '', line)

def parse_time_to_sortable(t):
    try:
        m = re.search(r'(\d{4}-\d{2}-\d{2})\s+(\d{2}):(\d{2}):(\d{2})\.(\d+)', t)
        if not m:
            return 0.0
        date, h, mi, s, frac = m.groups()
        date_parts = date.split('-')
        days = int(date_parts[0])*365*24*3600 + int(date_parts[1])*30*24*3600 + int(date_parts[2])*24*3600
        return days + int(h)*3600 + int(mi)*60 + int(s) + float(f"0.{frac}")
    except:
        return 0.0

def duration_s(start, end):
    try:
        return round(parse_time_to_sortable(end) - parse_time_to_sortable(start), 1)
    except:
        return ''

def truncate_url(url, max_len=45):
    if not url: return ''
    try:
        p = urlparse(url)
        path = p.path
        query = ('?' + p.query) if p.query else ''
        full = path + query
        if len(full) > max_len:
            full = full[:max_len] + '...'
        return full
    except:
        return url[:max_len] + '...' if len(url) > max_len else url

def sc_color(sc):
    try:
        sc_int = int(sc)
        if sc_int >= 500: return '\033[31m'
        if sc_int >= 400: return '\033[33m'
        if sc_int >= 200: return '\033[32m'
    except:
        pass
    return '\033[90m'

def clean_tags(tags):
    return {
        k: v for k, v in tags.items()
        if k not in SKIP_TAGS
        and not (k == 'Result' and v == '200')
        and not (k == 'StrategyName' and v == '')
    }

def find_root(trace_spans):
    span_ids = {s['SpanId'] for s in trace_spans}
    server_spans = [s for s in trace_spans if s['Kind'] == 'Server']
    if server_spans:
        return min(server_spans, key=lambda s: parse_time_to_sortable(s['StartTime']))
    orphans = [s for s in trace_spans if not s['ParentSpanId'] or s['ParentSpanId'] not in span_ids]
    if orphans:
        return min(orphans, key=lambda s: parse_time_to_sortable(s['StartTime']))
    return min(trace_spans, key=lambda s: parse_time_to_sortable(s['StartTime']))

lines_raw = sys.stdin.read().split('\n')
spans = []
current_service = ''
current_span = None
in_attrs = False
in_resource = False

for raw_line in lines_raw:
    line = strip_prefix(raw_line).strip()

    if line == 'Resource attributes:':
        in_resource = True
        continue

    if in_resource:
        m = re.match(r'-> service\.name:\s+(.+)', line)
        if m:
            current_service = parse_value(m.group(1))
        if line.startswith('ScopeSpans') or line.startswith('InstrumentationScope'):
            in_resource = False
        continue

    if re.match(r'^Span #\d+\s*$', line):
        if current_span and current_span.get('TraceId'):
            spans.append(current_span)
        current_span = {
            'ServiceName': current_service,
            'Tags': {},
            'TraceId': '', 'SpanId': '', 'ParentSpanId': '',
            'Name': '', 'Kind': '', 'StartTime': '', 'EndTime': '',
            'Duration': '', 'StatusCode': ''
        }
        in_attrs = False
        continue

    if current_span is None:
        continue

    patterns = [
        (r'Trace ID\s*:\s*(.+)',    'TraceId'),
        (r'Parent ID\s*:\s*(.+)',   'ParentSpanId'),
        (r'^ID\s*:\s*(.+)',         'SpanId'),
        (r'Name\s*:\s*(.+)',        'Name'),
        (r'Kind\s*:\s*(.+)',        'Kind'),
        (r'Start time\s*:\s*(.+)', 'StartTime'),
        (r'End time\s*:\s*(.+)',   'EndTime'),
        (r'Status code\s*:\s*(.+)','StatusCode'),
    ]

    matched = False
    for pattern, key in patterns:
        m = re.match(pattern, line)
        if m:
            current_span[key] = m.group(1).strip()
            matched = True
            break

    if matched:
        if current_span['StartTime'] and current_span['EndTime']:
            current_span['Duration'] = duration_s(current_span['StartTime'], current_span['EndTime'])
        continue

    if line == 'Attributes:':
        in_attrs = True
        continue

    if in_attrs:
        m = re.match(r'-> (.+?):\s+(.+)', line)
        if m:
            current_span['Tags'][m.group(1)] = parse_value(m.group(2))
        elif line and not line.startswith('->'):
            in_attrs = False

if current_span and current_span.get('TraceId'):
    spans.append(current_span)

traces = {}
for span in spans:
    tid = span['TraceId']
    if tid not in traces:
        traces[tid] = []
    traces[tid].append(span)

sorted_traces = sorted(
    traces.items(),
    key=lambda kv: parse_time_to_sortable(find_root(kv[1])['StartTime'])
)

for tid, trace_spans in sorted_traces:
    root = find_root(trace_spans)

    sc       = root['Tags'].get('http.response.status_code', '')
    name     = root['Name']
    kind     = root['Kind']
    service  = root['ServiceName']
    duration = root['Duration']
    url      = root['Tags'].get('url.full', root['Tags'].get('url.path', ''))

    tm = ''
    m = re.search(r'(\d{2}):(\d{2}):(\d{2})', root['StartTime'])
    if m:
        tm = ':'.join(m.groups())

    kind_col  = KIND_COLOR.get(kind, '\033[90m')
    sc_col    = sc_color(sc)
    kind_str  = f"{kind_col}{kind:<8}\033[0m"
    sc_str    = f"{sc_col}[{sc}]\033[0m" if sc else '\033[90m[---]\033[0m'
    dur_str   = f"\033[33m{str(duration) + 's':<7}\033[0m" if duration != '' else '\033[90m---s   \033[0m'
    tm_str    = f"\033[90m{tm}\033[0m" if tm else '\033[90m--:--:--\033[0m'
    svc_str   = f"\033[35m{service:<20}\033[0m" if service else ''
    count_str = f"\033[90m[{len(trace_spans)} spans]\033[0m"

    if name in ('GET', 'POST', 'PUT', 'DELETE', 'PATCH') and url:
        display_name = f"{name} {truncate_url(url, 40)}"
    else:
        display_name = name

    if len(display_name) > 55:
        display_name = display_name[:55] + '...'

    display = f"{kind_str} {sc_str} {tm_str}  {dur_str}  \033[1m{display_name:<55}\033[0m  {svc_str} {count_str}"

    sorted_spans = sorted(trace_spans, key=lambda s: parse_time_to_sortable(s['StartTime']))
    server_span = root
    server_url  = server_span['Tags'].get('url.full', server_span['Tags'].get('url.path', ''))
    server_sc   = server_span['Tags'].get('http.response.status_code', '')

    preview = {
        'TraceId':   tid,
        'Time':      tm,
        'Duration':  f"{root['Duration']}s" if root['Duration'] != '' else '',
        'SpanCount': len(trace_spans),
        'Entry': {
            'Kind':       server_span['Kind'],
            'Service':    server_span['ServiceName'],
            'Name':       server_span['Name'],
            'URL':        server_url,
            'StatusCode': server_sc,
            'Duration':   f"{server_span['Duration']}s" if server_span['Duration'] != '' else '',
            'Tags':       clean_tags(server_span['Tags']),
        },
        'Spans': [{
            'Kind':         s['Kind'],
            'Name':         s['Name'],
            'Service':      s['ServiceName'],
            'StatusCode':   s['Tags'].get('http.response.status_code', ''),
            'Duration':     f"{s['Duration']}s" if s['Duration'] != '' else '',
            'URL':          s['Tags'].get('url.full', s['Tags'].get('url.path', '')),
            'SpanId':       s['SpanId'],
            'ParentSpanId': s['ParentSpanId'],
            'StartTime':    s['StartTime'],
            'Tags':         clean_tags(s['Tags']),
        } for s in sorted_spans]
    }

    with open(f"/tmp/trace_{tid}.json", 'w') as f:
        json.dump(preview, f, indent=2)

    print(f"{display}\t{tid}", flush=True)
PYEOF

  local count
  count=$(docker logs "$container" 2>&1 | python3 "$script" | wc -l)
  echo "Found $count traces, loading search..."
  sleep 1

  trap "pkill -P $$; return" INT TERM

  while true; do
    clear
    printf "様様様様様様様様様様様様様様様様様様様様様様様様様様様様\n"
    printf "?? LIVE MODE: %s\n" "$container"
    printf "様様様様様様様様様様様様様様様様様様様様様様様様様様様様\n"
    printf "Press 's' to search | 'q' to quit\n"
    printf "様様様様様様様様様様様様様様様様様様様様様様様様様様様様\n\n"

    docker logs -f "$container" 2>&1 &
    local TAIL_PID=$!

    local key
    IFS= read -rsn1 key < /dev/tty

    kill -9 $TAIL_PID 2>/dev/null
    wait $TAIL_PID 2>/dev/null

    if [[ "$key" == "s" || "$key" == "S" ]]; then
      rm -f /tmp/trace_*.json
      docker logs "$container" 2>&1 | python3 "$script" | \
        fzf \
          --ansi \
          --no-sort \
          --layout=reverse \
          --border \
          --height=100% \
          --delimiter=$'\t' \
          --with-nth=1 \
          --preview '/tmp/aspire_preview.sh {2}' \
          --preview-window='right,50%,wrap,border-left' \
          --bind 'ctrl-r:reload(rm -f /tmp/trace_*.json && docker logs portalsdashboard 2>&1 | python3 /tmp/aspire_parser.py)' \
          --bind 'ctrl-/:toggle-preview' \
          --bind 'alt-up:preview-half-page-up' \
          --bind 'alt-down:preview-half-page-down' \
          --bind 'enter:execute(nvim -c "set ft=json" /tmp/trace_{2}.json)' \
          --header 'Ctrl-R: reload  |  Ctrl-/: toggle preview  |  Enter: open in nvim  |  Esc: back'

    elif [[ "$key" == "q" || "$key" == "Q" ]]; then
      echo ""
      echo "Exited log viewer"
      return 0
    fi
  done
}
