from i3pystatus import Status

status = Status(standalone=True)

# Displays clock
status.register("clock", hints = {"markup": "pango"},
    format = " %X",
    color = "#be5046",
    on_leftclick = "google-chrome-stable https://calendar.google.com/calendar/",)

# Battery Status
status.register("battery",
    format = "{status} {percentage: .1f}%",
    alert = True,
    full_color = "#98c379",
    critical_color = "#d19a66",
    charging_color = "#e06c75",
    interval = 10,
    status={
        "DIS":  "",
        "CHR":  "",
        "FULL": "",
    },)

# Memory status
status.register("mem",
    format = " {used_mem} M",
    color = "#d19a66",
    warn_color = "#d19a66",
    alert_color = "e0675",
    interval = 5,
    warn_percentage = 80,
    alert_percentage = 95,)

# CPU status
status.register("cpu_usage",
    format = " {usage:02}%",
    color = "#61afef",)

# Volume Status
status.register("pulseaudio",
    format = " {volume}%",
    color_unmuted = "#56b6c2",
    color_muted = "#be5046",)

# Pacman Updates Count
status.register("shell",
    command="/home/alex/Dotfiles/config/i3/scripts/pacman_update.sh",
    color = "#d19a66",
    interval = 500)

# current song
status.register("shell",
    command="/home/alex/Dotfiles/config/i3/scripts/now_playing.sh",
    color = "#e0e0e0",
    interval = 10)


status.run()
