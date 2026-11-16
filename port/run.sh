#!/bin/sh
# Undertale on FakeR36S-OS: the game's own data.win run by gmloader-next (armhf) with the GameMaker
# Android runner from PortMaster's Undertale port, packed by undertale-port.sh on a computer.
# https://github.com/Eeman1113/FakeR36S-Undertale
# The game reads the gamepad itself. Select+Start quits. Saves stay in this folder.
D=$(cd "$(dirname "$0")" && pwd)
cd "$D" || exit 1
[ -f undertale.port ] || { echo "Undertale: no undertale.port in $D (run undertale-port.sh from FakeR36S-Undertale)"; exit 1; }
LOG=/home/player/.config/fakers36s/undertale.log
mkdir -p "$D/save" "${LOG%/*}"
[ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 300000 ] && : > "$LOG"

export HOME=/home/player SDL_VIDEODRIVER=kmsdrm
. /etc/profile.d/sdl_controller.sh 2>/dev/null
chmod +x ./gmloadernext.armhf 2>/dev/null

echo "=== undertale start $(date)" >> "$LOG"
doas /usr/local/bin/cpuprofile max 2>/dev/null
/usr/bin/fr-padwatch ./gmloadernext.armhf -c gmloader.json >> "$LOG" 2>&1
rc=$?
doas /usr/local/bin/cpuprofile normal 2>/dev/null
echo "=== undertale exit $rc" >> "$LOG"
exit $rc
