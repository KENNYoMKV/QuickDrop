# Dynamic QuickDrop 0.3 Combined Preview

Combined Dynamic QuickDrop + Favorites build, based on ReSkate **2.1.1** for skate. Steam build
**25414733**, content head **625200**. Use the companion DLL and data mod together.

## Controls

- **Insert → Addons → Dynamic QuickDrop:** one menu with **Physics**, **Marker**
  and **Favorites** tabs.
- **Favorites:** search and check individual object variants. Choices save to
  the active profile using the existing `ReSkate.QuickDropFavorites` settings.
  Close/reopen the native Object Dropper to show Favorites as its first category.
  Unchecking returns an object to its original category; missing mod objects stay
  remembered. Favorites work independently of the dynamic physics switch.
- Placing a prop automatically includes its position in the marker snapshot.
- Face a nearby prop and **hold RB / R1 for 600 ms** to pin/unpin it from the
  marker. Range is approximately **2.6 m**. Release before another toggle.
- A marker pin does **not** freeze a prop. Included and excluded props both
  simulate normally. Re-pinning remembers the current physical position.
- Saving the game’s session marker updates included object poses; returning
  restores them. Excluded props retain their current physical positions.
- Default marker controls are **hold D-pad Up to save, tap Up to return**.
  The adapter observes native marker actions rather than guessed button bindings.
- Grabbing, forced grip locomotion and procedural grip IK have been removed.

Membership lasts for the level/session, follows placement identity across body
replacement, and clears on deletion/reset. Deleted objects are not recreated.
Committed editor transforms update included snapshots; cancelled previews should
retain the preceding snapshot. Off fixes props at their current poses and restores
their original masses. Preferences are stored in `dynamic-quickdrop.json`.

## Combined build verification

MSVC x64 Release build, marker/physics policy checks, Favorites category ordering,
exact variants, missing assets, removal and profile persistence/isolation tests.
Installer checks exercise fresh installation, migration from both layered previews,
one enabled mod entry, uninstall restoration and retention of unrelated settings.
This menu/package consolidation does not repeat the earlier live grind sessions.

## Historical r4 gameplay verification

The earlier accepted recordings use runtime SHA-256
`18ff4eb8549f811e9f56740cd5189f998e64004a248b3c7c89160992f44b8831`.

| Low stock round rail | Nosegrind | Smith |
| --- | ---: | ---: |
| Stationary dynamic | 562 ms | 593 ms |
| Moving dynamic | 781 ms | 796 ms |
| Fixed-body control | 578 ms | 593 ms |

The successful runs display **BS Nose Grind / BS Smith**, have no intervening
non-grind frames, and use native grind solving. Moving trials include approximately
**0.51 m / 0.47 m** of real rail travel during contact. A bounded diagnostic
velocity impulse starts the motion. Disabling edge continuity reproduces eight
contact interruptions in each control run. The tall imported black rail was
unsuitable for this approach and is not accepted grind evidence.

The complete 12-object fixture loaded, including Skate 3 props. Recorded marker
checks passed automatic enrollment, tap rejection, one toggle per hold, exclusion
from save/return, re-pin pose capture, dynamic-body behavior and absence of dragging.
Native policy checks cover membership lifecycle, input rearming, edge transforms,
metadata preservation and mass/speed response. The validated 558-asset data patch
and existing 651-prefab Skate 3 audit are retained.

## Remaining gameplay coverage

The r4 live editor
commit/cancel and weighted-impact regression passes were not completed. These
features have earlier r3 evidence, not a new r4 certification. Imported-rail named
grinds, sustained downhill trashcan-lid stalls, grouped edits, hardware-specific
input/reconnect, remapped inputs and multiplayer remain unverified. Favorites'
native category rendering/placement and the combined menu require user playtesting.

`Evidence/acceptance.json` records current automated checks and provenance;
`Evidence/r4-acceptance-historical.json` retains earlier gameplay evidence. Full recordings
remain under `evidence/native/r4-release` in the development workspace.

## Installation

Extract the whole ZIP and run `Install.ps1`, including when upgrading either old
preview. It installs and enables one **Dynamic_QuickDrop** mod, archives standalone
Favorites files and installation records, and retains existing profile choices.
Enable the separate Skate 3 prop pack if desired. Keep runtime updates off.
Uninstall restores the prior installation and update setting; backups are retained.
