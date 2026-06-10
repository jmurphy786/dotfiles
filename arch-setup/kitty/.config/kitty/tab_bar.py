from kitty.fast_data_types import get_boss


def draw_title(data):
    mode = data.get("keyboard_mode", "")
    index = data.get("index", "")
    title = data.get("title", "")
    tab_id = data.get("tab_id", -1)

    is_active = False
    try:
        boss = get_boss()
        active_tab = boss.active_tab if boss else None
        is_active = active_tab is not None and getattr(active_tab, "id", None) == tab_id
    except Exception:
        pass

    if is_active and mode == "leader":
        prefix = "󰓎 "
    elif is_active and mode == "resize":
        prefix = "󰩨 "
    else:
        prefix = ""

    return f"{prefix}{index}: {title}"
