# Cafe review assets

Unpublished layout draft. Final visual approval and a configured Cafe Place are pending.

- `SpaceCafeReview.rbxmx`: static cafe islands and a 3,600 × 3,600 stud riding garden. It contains no gameplay scripts.
- `CafeCuratedFurniture.rbxmx`: nine selected furniture templates from Roblox's [House Furniture Pack – Duvall Drive](https://create.roblox.com/store/asset/10847897579/House-Furniture-Pack-Duvall-Drive). Only geometry, seats and surface appearances are retained. The original pack's 101 script objects were removed before selection; the complete pack is not distributed here.
- `CafeTablePlant.rbxmx`: selected geometry from [Aesthetic Potted Table Plant](https://create.roblox.com/store/asset/12032209888/Aesthetic-Potted-Table-Plant), creator `reggiedi3d`. Creator Store reports 2,132 triangles and one MeshPart; the model also contains pot geometry. Used four times near the sofas.
- `CafeSky.rbxmx`: [Sombrero Galaxy Sky](https://create.roblox.com/store/asset/10725421130/Sombrero-Galaxy-Sky), creator `FrozenIIElsa12`.
- `CafeFurniture.rbxmx` / `CafeFurnitureOrigin.txt`: initial small templates from `brandonlouvetmich2`: [Classic Sofa](https://create.roblox.com/store/asset/16099816431/Classic-Sofa), [Wood Shelf](https://create.roblox.com/store/asset/16184405635/Wood-Shelf). Kept as authoring inputs; final placement replaces them with the selected Roblox furniture.

These were acquired as free Creator Store items through the user's signed-in account. Attribution records the source; it is not a claim that marketplace availability grants unrestricted rights outside Roblox.

Run `python tools/build_cafe_review.py` to generate `dist/ReviewModels/CafeGrandGarden-DesignReview.rbxlx`. The locally saved Studio review is `CafeGardenReady-DesignReview.rbxlx`. Neither is published, and the build does not change the main lobby or hunting place.

Distance streaming is enabled in the review place. The furniture's PBR textures, triangle totals, actual mobile memory, 20-player networking and 20 giant pets remain unmeasured. The garden's size is a layout proposal, not a performance guarantee.
