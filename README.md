# FakeR36S-Undertale: Undertale on a fake R36S

UNDERTALE on the fake R36S / GA36-MB handheld (Allwinner A23, 32-bit ARM, Mali-400, 512 MB) under [FakeR36S-OS](https://github.com/Eeman1113/FakeR36S-OS). It runs the PC version's own GameMaker bytecode, not an emulator.

PortMaster's [Undertale port](https://github.com/PortsMaster/PortMaster-New/tree/main/ports/undertale) is 64-bit only. All the pieces for 32-bit already existed though: [gmloader-next](https://github.com/PortsMaster/gmloader-next) builds for armhf, and the GameMaker runner in PortMaster's package carries a 32-bit ARM copy. This repo puts them together:

- **CI** builds gmloader-next for armhf with PortMaster's own recipe, pinned to one commit, with the patches in `patches/`, and publishes it with an ARMv7 `libm.so` on the [gmloader release](https://github.com/Eeman1113/FakeR36S-Undertale/releases/tag/gmloader).
- **`undertale-port.sh`** packs your copy of the game with the 32-bit runner on your computer and puts it on the card with a menu entry.
- **`port/run.sh`** is the launcher on the handheld: full CPU while playing, Select+Start quits.

**No game files are included.** You need your own Undertale from Steam or GOG (the Windows or Linux version; the folder with `data.win` and the `.ogg` music).

## Install

With the card's HOME partition mounted on your computer:

```sh
git clone https://github.com/Eeman1113/FakeR36S-Undertale
cd FakeR36S-Undertale
./undertale-port.sh ~/Downloads/Undertale /Volumes/HOME
```

It checks that `data.win` is GameMaker bytecode (the Steam and GOG PC versions are), packs it with the music and the runner (Windows files are left out), and adds `ports/undertale/` plus an **Undertale** entry in **Ports**. About 160 MB on the card. Needs bash, python3 and curl. Your game files only go to the card; nothing is uploaded.

## Controls

The game reads the gamepad itself, no keyboard mapping needed.

| Button | What it does |
|---|---|
| D-pad / stick | Move |
| A | Confirm |
| B | Cancel |
| Y | Menu |
| Select + R1 | Save state |
| Select + L1 | Load state |
| Select + B | Show / hide the FPS counter |
| Select + Start | Quit (back to EmulationStation) |

Save states use GameMaker's own `game_save` / `game_load` (rooms, characters and story flags), one slot, kept in `ports/undertale/save/fakers36s.state` so they survive a restart. The game's own save points work as normal next to them. Saves are in `ports/undertale/save`, the log in `.config/fakers36s/undertale.log`.

## Why a different libm

gmloader-next ships Android's `libm.so` from an arm64 build, and its 32-bit code uses ARMv8-only instructions (`vrinta`, `vselgt` and friends). Every other handheld PortMaster targets has an ARMv8 CPU, so nobody noticed. The A23 is a real ARMv7 Cortex-A7, and Undertale died with an illegal instruction as soon as it set up sound. CI pulls bionic's `libm.so` built for ARMv7 out of Google's Android 7.0 armeabi-v7a emulator image, checks it has no ARMv8 instructions, and publishes it next to the loader.

## Patches to gmloader-next

`patches/` is applied to gmloader-next before the build: the save state and FPS buttons (`0001`), a log line showing the audio format the game asks for and gets (`0002`), and the legacy joystick buttons mapped from GameMaker 1.x's old DirectInput numbering, so confirm is A, cancel is B and menu is Y (`0003`; without it Undertale confirmed on X).

## Credits

- **Toby Fox** for UNDERTALE. Buy it, it's wonderful.
- **[gmloader-next](https://github.com/PortsMaster/gmloader-next)** (GPL-2.0) by **JohnnyOnFlame** and the PortMaster community. The armhf binary on the release is built unchanged from their source, at the commit named in the workflow and release notes.
- **[PortMaster](https://portmaster.games)** and the authors of its Undertale port: **Jeod**, **curious_idiot** and **krishenriksen**. The runner and splash come from their package, fetched at install time.

The scripts in this repo are MIT licensed. gmloader-next is GPL-2.0, and UNDERTALE belongs to Toby Fox.
