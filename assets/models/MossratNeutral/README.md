# Neutral Mossrat rigs

User-supplied straight-pose source meshes, preserved in each `Source.glb`.

| Variant | Triangles | Source height | Studio height | Uploaded MeshId |
| --- | ---: | ---: | ---: | --- |
| S1 hunt | 3,122 | 0.70 m | 2.5 studs | 103834814949704 |
| S1 social | 10,411 | 0.70 m | 2.5 studs | 92191779453302 |
| S3 social | 10,329 | 1.20 m | 4.25 studs | 86180924790549 |

Run `tools/rig_neutral_mossrat.py`, then `tools/prepare_neutral_import.py` to prepare Studio glTF imports. The authoring rig has 34 named bones; Studio retains 23 effective skin bones, including upper/lower/paw chains on all four legs. At most four influences per vertex. Original geometry, UVs, normals, and source textures remain unchanged. Import copies limit textures to 1024 for hunt and 2048 for social models.

`NeutralMossratInstaller` installs the imported V2 models with backups. Imported Studio orientation is already forward; do not add a 180-degree body rotation or old head-only corrections. The S3 source has two tails; this is preserved.

`NeutralMossratAnimator` shares `QuadrupedAnimator` and `QuadrupedMotion`, with per-model pose caches and distance-based update rates. Only the first appearance tier uses idle tail motion. This is procedural flat-ground locomotion, not terrain foot-placement IK.

Validation: `tests/check_neutral_skin.py`, `tests/check_shared_motion.py`, and saved-place checks `check_ride_installed.py` / `check_hunt_lod_installed.py`. Play-only diagnostics live in `tools/review_neutral_companion.client.luau` and `tools/review_rider_visibility.client.luau`.
