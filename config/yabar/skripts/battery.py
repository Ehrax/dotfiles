#!/bin/python
BAT_PATH = "/sys/class/power_supply/{}/".format("BAT1")
CAPACITY_PATH = BAT_PATH + "capacity"
STATUS_PATH = BAT_PATH + "status"

output = ""

with open(STATUS_PATH) as f:
    bat_status = f.read()

with open(CAPACITY_PATH) as f:
    bar_capacity = int(f.read())

if bat_status == "Charging\n":
    output = " {}%".format(bar_capacity)

if bat_status == "Discharging\n":
    if bar_capacity >= 75:
        output = " {}%".format(bar_capacity)
    elif bar_capacity >= 50:
        output = " {}%".format(bar_capacity)
    elif bar_capacity >= 25:
        output = " {}%".format(bar_capacity)
    elif bar_capacity >= 10:
        output = " {}%".format(bar_capacity)

print(output)
