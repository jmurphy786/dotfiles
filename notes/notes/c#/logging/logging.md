# Logging

I've recently been looking into how to setup good logs in c sharp, typically you can use serilog, or if they dont have that this custom Logger seems to do the job

```cs

using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Logging.Console;
using System.Diagnostics;
using System.Text.Json;

namespace Shared.Logging;

public sealed class CompactJsonFormatter : ConsoleFormatter
{
    public CompactJsonFormatter() : base("compact") { }

    public override void Write<TState>(
        in LogEntry<TState> logEntry,
        IExternalScopeProvider? scopeProvider,
        TextWriter textWriter)
    {
        var log = new
        {
            ts = DateTime.UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'"),
            level = GetLevelString(logEntry.LogLevel),
            msg = logEntry.Formatter?.Invoke(logEntry.State, logEntry.Exception),
            loc = GetCallerInfo(logEntry.Category),
            data = GetData(logEntry.State),
            err = GetError(logEntry.Exception)
        };

        textWriter.WriteLine(JsonSerializer.Serialize(log, new JsonSerializerOptions
        {
            WriteIndented = false,
            DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
        }));
    }

    private static string GetLevelString(LogLevel level) => level switch
    {
        LogLevel.Trace => "TRACE",
        LogLevel.Debug => "DEBUG",
        LogLevel.Information => "INFO",
        LogLevel.Warning => "WARN",
        LogLevel.Error => "ERROR",
        LogLevel.Critical => "CRITICAL",
        _ => "UNKNOWN"
    };

    private static string? GetCallerInfo(string? category)
    {
        // Try to get file:line from stack trace
        var stackTrace = new StackTrace(true);

        for (int i = 0; i < Math.Min(stackTrace.FrameCount, 15); i++)
        {
            var frame = stackTrace.GetFrame(i);
            if (frame == null) continue;

            var method = frame.GetMethod();
            var fileName = frame.GetFileName();
            var lineNumber = frame.GetFileLineNumber();

            if (method == null || string.IsNullOrEmpty(fileName)) continue;

            var declaringType = method.DeclaringType?.FullName ?? "";

            // Skip logging infrastructure frames
            if (declaringType.Contains("Microsoft.Extensions.Logging") ||
                declaringType.Contains("Shared.Logging") ||
                declaringType.Contains("System.Diagnostics") ||
                declaringType.StartsWith("System."))
                continue;

            // Simplify file path
            var simplifiedPath = SimplifyPath(fileName);

            if (!string.IsNullOrEmpty(simplifiedPath))
                return $"{simplifiedPath}:{lineNumber}";
        }

        // Fallback to category (class name)
        if (!string.IsNullOrEmpty(category))
        {
            var parts = category.Split('.');
            return parts.Length > 0 ? parts[^1] : category;
        }

        return null;
    }

    private static string SimplifyPath(string filePath)
    {
        // Try to extract from src/ onwards
        var srcIndex = filePath.IndexOf("/src/", StringComparison.OrdinalIgnoreCase);
        if (srcIndex >= 0)
            return filePath.Substring(srcIndex + 5);

        srcIndex = filePath.IndexOf("\\src\\", StringComparison.OrdinalIgnoreCase);
        if (srcIndex >= 0)
            return filePath.Substring(srcIndex + 5).Replace('\\', '/');

        // Just return filename
        return Path.GetFileName(filePath);
    }

    private static object? GetData<TState>(TState state)
    {
        if (state is not IReadOnlyList<KeyValuePair<string, object>> values)
            return null;

        var dict = new Dictionary<string, object>();
        foreach (var kvp in values)
        {
            if (kvp.Key != "{OriginalFormat}")
                dict[kvp.Key] = kvp.Value;
        }

        return dict.Count > 0 ? dict : null;
    }

    private static object? GetError(Exception? exception)
    {
        if (exception == null) return null;

        return new
        {
            message = exception.Message,
            stack = exception.StackTrace
        };
    }
}


```

This gives you good feedback and will give you logs that look like this

```json


{
  "ts": "2025-12-24T00:44:17.138Z",
  "level": "DEBUG",
  "msg": "Initialising the call",
  "loc": "UltraApiClient.cs:83"
}


```

Using this logger, you have to update the Program.cs and add it as a builder, also make sure you have console on as shown

```cs

builder.Logging.AddJsonConsole();
builder.Logging.ClearProviders();
builder.Logging.AddConsoleFormatter<CompactJsonFormatter, ConsoleFormatterOptions>();
builder.Logging.AddConsole(options => options.FormatterName = "compact");


```

Seems very useful!
