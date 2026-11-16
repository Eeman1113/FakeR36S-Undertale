#!/bin/bash
# undertale-port.sh: put YOUR copy of Undertale (Steam/GOG, Windows or Linux) on a FakeR36S-OS card.
#   ./undertale-port.sh <Undertale folder> /Volumes/HOME
# The game's data.win and music are packed with the GameMaker Android runner from PortMaster's
# Undertale port (github.com/PortsMaster/PortMaster-New, ports/undertale, pinned commit) and run by
# gmloader-next (GPL-2.0) built for 32-bit ARM by this repo's CI ('gmloader' release).
# https://github.com/Eeman1113/FakeR36S-Undertale
# Your game files are only copied to the card; nothing is uploaded. Needs bash, python3, curl.
set -euo pipefail
PM_COMMIT=bb316802350f706b835417b9e22a6956b577346c
GML_COMMIT=2a9aa04580f98d2a26cd3afb51eb9d2e3042ee88
PM_RAW=https://raw.githubusercontent.com/PortsMaster/PortMaster-New/$PM_COMMIT/ports/undertale
GML_RAW=https://raw.githubusercontent.com/PortsMaster/gmloader-next/$GML_COMMIT
REL=https://github.com/Eeman1113/FakeR36S-Undertale/releases/download/gmloader
SRC=${1:?usage: undertale-port.sh <Undertale folder> <HOME mount>}
HOMEDIR=${2:?usage: undertale-port.sh <Undertale folder> <HOME mount>}
HERE=$(cd "$(dirname "$0")" && pwd)
[ -f "$HOMEDIR/.romdirs" ] || { echo "$HOMEDIR doesn't look like a FakeR36S-OS HOME partition" >&2; exit 1; }

# the folder with the .ogg files: Windows has data.win, Linux has assets/game.unx
GAME=
for d in "$SRC" "$SRC/Undertale" "$SRC/assets" "$SRC/Undertale/assets"; do
    if [ -f "$d/data.win" ] || [ -f "$d/game.unx" ]; then GAME=$d; break; fi
done
[ -n "$GAME" ] || { echo "no data.win (Windows) or game.unx (Linux) found under $SRC" >&2; exit 1; }

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
echo "Fetching the runner (PortMaster ${PM_COMMIT:0:7}) and gmloader-next (${GML_COMMIT:0:7})..."
curl -fsSL -o "$WORK/undertale.port" "$PM_RAW/undertale/undertale.port"
curl -fsSL -o "$WORK/gmloadernext.armhf" "$REL/gmloadernext.armhf"
curl -fsSL -o "$WORK/gmloadernext.armhf.sha256" "$REL/gmloadernext.armhf.sha256"
( cd "$WORK" && sha256sum -c gmloadernext.armhf.sha256 2>/dev/null || shasum -a 256 -c gmloadernext.armhf.sha256 ) >/dev/null \
    || { echo "gmloadernext.armhf checksum mismatch" >&2; exit 1; }
curl -fsSL -o "$WORK/LICENSE.gmloader-next.md" "$REL/LICENSE.gmloader-next.md"
mkdir -p "$WORK/lib/armeabi-v7a"
for f in libc++_shared.so libcompiler_rt.so libm.so; do
    curl -fsSL -o "$WORK/lib/armeabi-v7a/$f" "$GML_RAW/lib/armeabi-v7a/$f"
done

echo "Packing your game with the 32-bit runner..."
python3 - "$WORK/undertale.port" "$GAME" "$WORK/out.port" <<'PY'
import os, struct, sys, zipfile
runner, game, out = sys.argv[1:]
data = os.path.join(game, 'data.win')
if not os.path.exists(data): data = os.path.join(game, 'game.unx')
with open(data, 'rb') as f:
    head = f.read(8)
    if head[:4] != b'FORM': sys.exit('data.win is not a GameMaker data file')
    size = struct.unpack('<I', head[4:])[0]; pos = 8; chunks = {}
    while pos < size + 8:
        f.seek(pos); h = f.read(8)
        if len(h) < 8: break
        chunks[h[:4]] = struct.unpack('<I', h[4:])[0]; pos += 8 + chunks[h[:4]]
if not chunks.get(b'CODE'):
    sys.exit('this data.win has no bytecode (a YYC build); only the Steam/GOG PC version works')
skip_ext = ('.dll', '.exe', '.cdx', '.so')
skip = {'steam_emu.ini', 'steam_appid.txt', '.DS_Store', 'data.win', 'game.unx'}
with zipfile.ZipFile(runner) as r, zipfile.ZipFile(out, 'w', zipfile.ZIP_STORED) as o:
    for i in r.infolist():                       # keep only the 32-bit ARM runner and the splash
        if i.filename.startswith('lib/') and not i.filename.startswith('lib/armeabi-v7a/'): continue
        if i.filename.startswith('assets/') and os.path.isfile(os.path.join(game, i.filename[7:])):
            continue                             # the game's own file wins, as in PortMaster's port
        o.writestr(i, r.read(i.filename))
    o.write(data, 'assets/game.droid')
    n = 0
    for name in sorted(os.listdir(game)):
        p = os.path.join(game, name)
        if not os.path.isfile(p) or name in skip or name.lower().endswith(skip_ext): continue
        o.write(p, 'assets/' + name); n += 1
print(f'  game data + {n} files ({sum(1 for x in os.listdir(game) if x.endswith(".ogg"))} music tracks)')
PY

D=$HOMEDIR/ports/undertale
mkdir -p "$D/save" "$D/lib/armeabi-v7a" "$D/licenses" "$HOMEDIR/.local/share/applications" "$HOMEDIR/.local/share/icons"
cp "$WORK/out.port" "$D/undertale.port"
cp "$WORK/gmloadernext.armhf" "$D/"; chmod +x "$D/gmloadernext.armhf"
cp "$WORK"/lib/armeabi-v7a/*.so "$D/lib/armeabi-v7a/"
cp "$HERE/port/run.sh" "$D/run.sh"; chmod +x "$D/run.sh"
cat > "$D/gmloader.json" <<'JSON'
{
    "save_dir" : "save",
    "apk_path" : "undertale.port",
    "show_cursor" : false,
    "disable_controller" : false,
    "disable_joystick" : false,
    "disable_depth" : false,
    "force_platform" : "os_linux"
}
JSON
cp "$WORK/LICENSE.gmloader-next.md" "$D/licenses/"
cat > "$D/licenses/README.txt" <<TXT
UNDERTALE (c) Toby Fox: your own copy (data.win and music), packed on your computer.
gmloader-next: GPL-2.0, https://github.com/PortsMaster/gmloader-next (commit $GML_COMMIT), built for
armhf by https://github.com/Eeman1113/FakeR36S-Undertale (.github/workflows/gmloader.yml).
Runner and splash: from PortMaster's Undertale port, https://github.com/PortsMaster/PortMaster-New
(ports/undertale, commit $PM_COMMIT). Thanks to JohnnyOnFlame, Jeod, curious_idiot and krishenriksen.
TXT
curl -fsSL -o "$HOMEDIR/.local/share/icons/undertale.png" "$PM_RAW/cover.png" || true
cat > "$HOMEDIR/.local/share/applications/undertale.puppy" <<PUP
NAME=Undertale
CATEGORY=Ports
COMMAND=/home/player/ports/undertale/run.sh
DESCRIPTION=The friendly RPG where nobody has to die. A confirms, B cancels, X/Y menu. Select+Start quits.
ICON=/home/player/.local/share/icons/undertale.png
PUP
echo "Done: Undertale is in Ports on the card."
