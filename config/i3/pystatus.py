from i3pystatus import Status

status = Status(standalone=True)

# Displays clock
status.register("clock", hints = {"markup": "pango"},
    format = "<span color=\"#81a2be\"> %a %-d %b</span><span color=\"#373b41\"> | </span> %X",
    color = "#cc6666",
    on_leftclick = "google-chrome-stable https://calendar.google.com/calendar/",)

# Battery Status
status.register("battery",
    format = "{status} {percentage: .1f}%",
    alert = True,
    full_color = "#b5bd68",
    critical_color = "#cc6666",
    charging_color = "#e0e0e0",
    interval = 10,
    status={
        "DIS":  "",
        "CHR":  "",
        "FULL": "",
    },)

# Memory status
status.register("mem",
    format = " {used_mem} M",
    color = "#f0c674",
    warn_color = "#de935f",
    alert_color = "#cc6666",
    interval = 5,
    warn_percentage = 80,
    alert_percentage = 95,
    on_leftclick="xfce4-taskmanager",)

# CPU status
status.register("cpu_usage",
    format = " {usage:02}%",
    color = "#81a2be",)

# Volume Status
status.register("pulseaudio",
    format = " {volume}%",
    color_unmuted = "#8abeb7",
    color_muted = "#cc6666",)

# Pacman Updates Count
status.register("shell",
    command="/home/alex/Dotfiles/config/i3/scripts/pacman_update.sh",
    color = "#de935f",
    interval = 500)

# current song
status.register("shell",
    command="/home/alex/Dotfiles/config/i3/scripts/now_playing.sh",
    color = "#e0e0e0",
    interval = 10)


status.run()
