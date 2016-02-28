from i3pystatus import Status

status = Status(standalone=True)

# Displays clock
status.register("clock",
    hints = {"markup": "pango"},
    format = "<span color=\"#ff797b\"> %a %-d %b</span><span color=\"#565656\"> ❱ </span>%X",
    color = "#8BADF9",
    on_leftclick = "google-chrome-stable https://calendar.google.com/calendar/",)

# Battery Status
status.register("battery",
    format = "{status} {percentage: .1f}%",
    alert = True,
    full_color = "#94F397",
    critical_color = "#b30000",
    charging_color = "#8BC3E7",
    interval = 10,
    status={
        "DIS":  "",
        "CHR":  "",
        "FULL": "",
    },)

# Memory status
status.register("mem",
    format = " {used_mem} M",
    color = "#F3D194",
    warn_color = "#e66e21",
    alert_color = "#eb654f",
    interval = 5,
    warn_percentage = 80,
    alert_percentage = 95,
    on_leftclick="xfce4-taskmanager",)

# CPU status
status.register("cpu_usage",
    format = " {usage:02}%",
    color = "#B987D9",)

# Volume Status
status.register("pulseaudio",
    format = " {volume}%",
    color_unmuted = "#8BADF9",
    color_muted = "#ff797b",)

status.run()
