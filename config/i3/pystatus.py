from i3pystatus import Status

status = Status(standalone=True)

# Displays clock
status.register("clock", hints = {"markup": "pango"},
    format = "<span color=\"#3498DB\"> %a %-d %b</span><span color=\"#E74C3C\"> | </span> %X",
    color = "#E74C3C",
    on_leftclick = "google-chrome-stable https://calendar.google.com/calendar/",)

# Battery Status
status.register("battery",
    format = "{status} {percentage: .1f}%",
    alert = True,
    full_color = "#2ECC71",
    critical_color = "#E74C3C",
    charging_color = "#9B59B6",
    interval = 10,
    status={
        "DIS":  "",
        "CHR":  "",
        "FULL": "",
    },)

# Memory status
status.register("mem",
    format = " {used_mem} M",
    color = "#F1C40F",
    warn_color = "#e66e21", alert_color = "#eb654f",
    interval = 5,
    warn_percentage = 80,
    alert_percentage = 95,
    on_leftclick="xfce4-taskmanager",)

# CPU status
status.register("cpu_usage",
    format = " {usage:02}%",
    color = "#1ABC9C",)

# Volume Status
status.register("pulseaudio",
    format = " {volume}%",
    color_unmuted = "#3498DB",
    color_muted = "#E74C3C",)

# Pacman Updates Count
status.register("shell",
    command="/home/alex/Dotfiles/config/i3/scripts/pacman_update.sh",
    color = "#E67E22",
    interval = 500)

# current song
status.register("shell",
    command="/home/alex/Dotfiles/config/i3/scripts/now_playing.sh",
    color = "#BDC3C7",
    interval = 10)


status.run()
