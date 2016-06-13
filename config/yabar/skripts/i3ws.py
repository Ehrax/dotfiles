#!/bin/python
import json
import subprocess

command = ["i3-msg", "-t", "get_workspaces"]
p = subprocess.Popen(command, stdout=subprocess.PIPE)
