# Dig the Mountain — Visual Style Guide

**Visual direction:** SANDFORGE INDUSTRIAL — stylized, readable, polished Roblox quarry-industrial 3D.

**Primary approved visual reference:**
`references/Sandforge_Upgrade_Workshop/00_MASTER_compact_approved_3quarter.png`

Read `references/Sandforge_Upgrade_Workshop/REFERENCE_NOTES.md` before using the other views. The master image determines the overall look; the additional views are approximate AI-generated concept drawings, not guaranteed to be geometrically consistent.

## What the style is

A warm desert-sand quarry combined with distinctive yellow and graphite industrial machinery, believable modular mechanics and restrained bright technology. High-quality stylized forms rather than photorealism or extremely basic block geometry. Each object should look like it belongs to one cohesive game world without duplicating the approved upgrade station.

## Geometry and materials

- Distinct silhouettes and recognizable function at in-game viewing distance.
- Sturdy metal housings; slightly beveled corners; chunky beams and panels; selective bolts, gears, pistons and vents.
- Logical construction: components should appear mountable, serviceable, and functional.
- Use material hierarchy: painted construction metal, dark structural metal, exposed steel, transparent glass or tubes only where purpose-driven, stone, sand and occasional wood in environment.
- Keep details concentrated near player interaction points. Avoid excessively busy silhouettes.

## Approximate palette (adjust to source images and lighting)

| Function | Colour | Hex |
|---|---|---|
| Industrial accent | Construction yellow | `#F7B500` |
| Active highlights | Amber-orange | `#FF9A00` |
| Main housing | Dark graphite | `#2A2D34` |
| Secondary steel | Gray | `#6A6E77` |
| Digital UI | Cyan-blue | `#00DAFF` |
| Environment | Sand beige | `#D8B178` |

**Do not make every object yellow.** Machinery shares the accent palette; natural cliffs, wood, ground, buildings and roads keep their own appropriate materials and colours. Emission and glow should be restrained rather than blanket neon.

## World, machines, props

- Sand sale station: designed as a sand intake/processing machine rather than a generic cash register.
- Upgrade station: approved Sandforge Upgrade Workshop; keep its compact proportions, left sand reactor, central control UI and right single robot arm.
- Future connection: visible transparent sand transport tube from sale machine to upgrade machine; design intake flanges on individual stations, install tube later as a separate task.
- Future challenge module: concept reserved for a possible optional bonus trial unlocked by digging volume; it must not be modeled or added unless specifically requested.
- Shovels, conveyors, wheelbarrows, signs, storage, fences, workshops and other engineering equipment should use consistent shapes, edge radii, materials and scale. Preserve unique silhouettes and functional differences.
- World environment: natural sand, stone and excavation terrain with purposeful industrial structures, paths, work lights, gantries and safety marking. Avoid turning the entire world into a futuristic laboratory.

## UI and animation

- UI: dark panels with yellow/orange accents and cyan information displays, clear iconography and readable type; optimize readability for touch/mobile.
- Feedback: sand moving in equipment, gears and conveyor activity, short upgrade confirmation, readable status lights, responsive controls. Avoid long interruptions of repeated basic purchases.
- Prefer lightweight effects (UV animation, scrolling textures, small bounded particle systems) over physics simulations involving thousands of grains.
- Animation pivots, mechanical joints, and effects should be organized and independent for future scripting.

## Quality & performance

Target Roblox PC and mobile. Model with reasonable triangle counts and sensible materials; limit transparency overdraw, costly particles and excessive realtime lights; use meshes, simple collisions and level-of-detail strategies when helpful. Test actual appearance, proportions, collision, and performance in Roblox Studio rather than assuming Blender render appearance survives export.

## Codex operating rules

1. Before any visual/UI/map/asset task, read this file and the main reference if tool access to images is available.
2. Ask for the image or report limitation if you cannot access it; never claim to have viewed it when you haven't.
3. For a new model, first define its gameplay function and unique silhouette; then apply common visual language.
4. Check the existing repository, Rojo sync setup and object ownership before changing files or assets.
5. **Do not** automatically restyle or replace existing map objects or working mechanics. Plan and request approval for any broad redesign.
6. Preserve existing `AGENTS.md`, project settings, saves and scripts unless requested; make minimal, reversible changes.
7. If creating Blender assets, keep named parts/modifiers/materials organized; prepare appropriate FBX/GLB exports and verify actual render and import in Roblox Studio.
8. Judge visual results against the approved references, mobile readability, gameplay clarity and frame rate; distinguish assumptions from verified outcomes.

**Summary:** warm sandy quarry + strong industrial engineering + polished stylized Roblox models + functional motion + selective technological highlights.
