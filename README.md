# Dynamic QuickDrop

## Combined Preview 0.3

**Dynamic QuickDrop 0.3 - Combined Preview.zip** consolidates Dynamic QuickDrop
and QuickDrop Favorites into one installation, one launcher mod and one menu:

**Insert → Addons → Dynamic QuickDrop**

- **Physics:** dynamic props and moving-surface support.
- **Marker:** automatic marker membership, pin/unpin and snapshot controls.
- **Favorites:** search installed objects and select exact variants for the first
  native Object Dropper category. Close and reopen the dropper after changes.

Existing favorites and physics preferences carry over automatically. Favorites
remain available when dynamic physics is off.

### Included behavior

- Immediate on/off toggle, saved with the active profile.
- Grabbing and its procedural animation have been removed.
- Placed props automatically join the session-marker snapshot and remain dynamic.
- **Hold RB / R1 for 0.6 seconds** near a prop (about 2.6 m) to exclude/include it.
  Release before toggling again. Re-pinning captures its current physical pose.
- Weight- and speed-sensitive impacts. Placeholder masses distinguish light props from dumpsters;
  authored non-placeholder masses are retained.
- Native dropper move/rotate/commit/cancel starts from the current physical pose.
- Native session-marker save/return actions save/restore included props. Default
  controls: **hold D-pad Up to save; tap Up to return**. Down opens the toolbox.
- Repaired native edge/chain continuity for stationary and moving dynamic rails,
  preserving actual rail motion and relative contact velocity.
- Compatibility with **Diplomatico-Skate3_CreateAPark_Props 1.1.0**. Its 651 prefabs
  were audited; representative rails and props were exercised in the private playtest.

The r4 physics build passed visibly labeled **BS Nose Grind** and **BS Smith** on the low
stock round rail, stationary and physically moving, without contact interruptions.
It also passed automatic marker enrollment, held-RB toggles, excluded-object
save/return, re-pin pose capture and removal of dragging with all 12 fixture props loaded.
The combined build adds category/profile checks and fresh/upgrade installer checks.
See `NATIVE-PLAYTEST.md` and `Evidence/acceptance.json` for current build verification;
the r4 live recordings are retained as historical evidence.

### Install the native preview

Close skate. and the ReSkate launcher, extract the **whole** native preview ZIP, then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\Install.ps1
```

Run this installer directly over an existing Dynamic QuickDrop and/or Favorites
preview. It validates and archives the existing installation, removes the separate
Favorites launcher entry and enables the combined **Dynamic_QuickDrop** entry.
Your profile's favorites, physics preferences and saved objects are preserved.

The installer backs up the current `ReSkate.dll` and `Mods\Dynamic_QuickDrop`
folder, then installs the companion and validated data mod. **Dynamic_QuickDrop**
is enabled automatically. Use only one copy of the data mod.
Enable the Skate 3 prop pack separately if installed; its content is not bundled here.
It also disables launcher runtime updates, which otherwise replace the custom
DLL; uninstall restores the previous update setting. Keep updates off for this preview.
The native preview is a modified ReSkate **2.1.1** runtime for skate. build
**25414733**; `.fbmod` / `.fbproject` alone cannot add its menu or controls.

Restore the previous installation with `Install.ps1 -Uninstall`, including the
earlier separate Favorites files/records if they were installed. Backups stay in
`C:\Games\ReSkate-1.0.0\DynamicQuickDrop-backup`. Full corresponding source,
licenses and build scripts are in `Source.zip`; `tools/build_native.ps1` builds
the companion with Visual Studio 2022 x64 and runs its native behavior tests.

---

## Original data mod 0.1

A native ReSkate data mod for Skate 3-style movable QuickDrop objects.

The build changes QuickDrop rigid bodies from **Fixed** to **Dynamic** and adds
the game's normal dynamic world/character contacts to the two gameplay BuildKit
collision presets. It retains each object's original geometry, materials,
grind surfaces, selection categories, and placement-query definitions.

### Data coverage

Version **0.1.0** targets **skate. Steam build 25414733 / content head 625200**,
with **ReSkate 2.1.1**. It patches **556 stock base prefabs**, the firework's
additional fixed-body override, and the shared collision database: **558 assets**.

**Verified:** Studio project/package parsing, native compilation, all 558 compiled
payloads and their 566 bundle occurrences, and loading the full mod in ReSkate
through to the skater/Hub screen.

The original standalone 0.1 package had asset/load validation. The native companion
companion adds the gameplay behavior and recorded checks described above.

The mod uses skate.'s native physics and original collision meshes. It targets
movable props rather than a complete recreation of Skate 3's physics or grabbing
controls. The data patch covers the stock QuickDrop catalogue; the runtime also
handles validated local Build Kit replicas, including the audited Skate 3 pack.

## Install the compiled package

1. Close the game.
2. Extract `Dynamic_QuickDrop` from the release ZIP into the `Mods` folder beside
   your ReSkate `Skate.exe`.
3. Enable **Dynamic_QuickDrop** in the launcher and start the game.
4. Place a fresh QuickDrop object. Test a small prop on flat ground first, then
   try a rail, ramp, and stacked props.

For this installation the target folder is:

```text
C:\Games\ReSkate-1.0.0\Mods\Dynamic_QuickDrop\layout.toc
```

Use one installed copy: the compiled folder **or** a copy exported through Studio.
The matching `.fbproject` is editable in ReSkate Studio; `.fbmod` is also supplied.
If another enabled mod edits the same prefabs or the physics category database,
load Dynamic QuickDrop after it to give these edits priority.

Disable the mod and restart to restore stock fixed-body behavior. ReSkate can save
the moved positions of placed objects, so disabling physics does not restore a
previous park layout. Multiplayer behavior requires separate validation.

## Build from your own game

Python 3.10+ and the installed ReSkate Studio CLI are required. The build reads
game assets and writes only the project and its temporary staging folder.

```powershell
python tools/inspect_quickdrop.py --game "C:\Games\ReSkate-1.0.0" --scan
python tools/build.py --game "C:\Games\ReSkate-1.0.0" --compile
python tools/validate.py "dist/Dynamic QuickDrop.fbproject" "$env:LOCALAPPDATA/Temp/opencode/dynamic-quickdrop-cache/compiled/Patch"
python tools/package.py
```

The authoring tools resolve enum and preset layouts from Studio reflection. Each
rigid-body edit is checked to change exactly one enum byte. The collision edit
is decoded independently by Studio and compared against the expected field-only
change. The validator locates every authored EBX in the compiled bundles, checks
its SHA-1, decompresses it, and compares its full contents to the Studio project.

`tools/playtest.py` creates a private offline data/profile directory under the
OpenCode temporary directory. `python tools/playtest.py launch` uses the private
executable, runtime, Steam edition marker and profile. `--source-executable` does
not fully relocate the engine's native asset mount, so use the private executable
for mod compatibility checks. Its fixture and screenshots are development-only.
