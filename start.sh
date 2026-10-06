#!/usr/bin/env bash

# Kill any existing quickshell instances
pkill -f "(qs|quickshell).*shell\.qml"
for _ in {1..20}; do
    pgrep -f "(qs|quickshell).*shell\.qml" >/dev/null || break
    sleep 0.05
done

if pgrep -f "(qs|quickshell).*shell\.qml" >/dev/null; then
    pkill -9 -f "(qs|quickshell).*shell\.qml"
fi

# If -q is passed, we just quit here
if [[ "$1" == "-q" ]]; then
    exit 0
fi

# Prevent Qt 25-second blocking DBus timeout on xdg-desktop-portal
export QT_NO_XDG_DESKTOP_PORTAL=1

# Launch the unified ShellArie process as a detached daemon
qs -d -p "$(dirname "$(readlink -f "$0")")/shell.qml"
