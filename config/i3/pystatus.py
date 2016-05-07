from i3pystatus import Status

status = Status(standalone=True)

# Displays clock
status.register("clock", hints = {"markup": "pango"},
    format = "<span color=\"#624799\">: %a %-d %b</span><span color=\"#7b59c0\"> | </span>:%X",
    color = "#7b59c0",
    on_leftclick = "google-chrome-stable https://calendar.google.com/calendar/",)

# Battery Status
status.register("battery",
    format = "{status} {percentage: .1f}%",
    alert = True,
    full_color = "#67AA69",
    critical_color = "#bf616a",
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
    color = "#AA9267",
    warn_color = "#e66e21", alert_color = "#eb654f",
    interval = 5,
    warn_percentage = 80,
    alert_percentage = 95,
    on_leftclick="xfce4-taskmanager",)

# CPU status
status.register("cpu_usage",
    format = " {usage:02}%",
    color = "#624799",)

# Volume Status
status.register("pulseaudio",
    format = " {volume}%",
    color_unmuted = "#6179AE",
    color_muted = "#B25456",)

# Pacman Updates Count
status.register("shell",
    command="/home/alex/Dotfiles/config/i3/scripts/pacman_update.sh",
    color = "#887C88",
    interval = 500)

# current song
status.register("shell",
    command="/home/alex/Dotfiles/config/i3/scripts/now_playing.sh",
    color = "#A66C59",
    interval = 10)


status.run()
