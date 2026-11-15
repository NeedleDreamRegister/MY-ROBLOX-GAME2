# Instructions for Codex

This is an existing Roblox game. Read README.md and HANDOFF.md before making changes.

- The authoritative complete place is MY-ROBLOX-GAME.rbxl. Open that file in Roblox Studio.
- src/ is an exported snapshot, NOT an already configured Rojo project. script-manifest.json maps exported files to Studio instances.
- Do not rebuild the game, mountain, roads, transport, or player systems from scratch.
- Scope changes to the user's current request. Preserve unrelated mechanics and map objects.
- The latest vehicle is QG Touring (DesignVersion 2), with 5 native passenger Seats and an empty driver position.
- Space immediately exits the moving cart onto the nearby footway. Do not restore the old wait-for-stop restriction. F queues/cancels exit at the boarding place.
- There is one unsigned boarding place near spawn. No rear stop. Default dwell is 4 seconds.
- The green plot borders were deliberately removed.
- Runtime gardens and carts are regenerated per player. Updating only the Edit preview is insufficient; update CartTemplate/controller or the relevant builder as appropriate.
- Keep the existing reliable SeatWeld carriage and synchronized server/client exit. AlignPosition.ApplyAtCenterOfMass must remain false.
- Preserve the windshield's positive X inclination of 6.37 degrees relative to BodyPivot.
- After edits, save the actual repository place and keep its corresponding src/ exports current. Do not claim a Lua-only edit was applied in Studio unless it really was.
- Before a handoff, update HANDOFF.md with changes, outstanding work and checks actually performed. Do not repeat long gameplay checks unless relevant.
- The owner explicitly asked not to spend time testing unrelated mining/economy/gameplay mechanics.
- Use normal commits/pushes; preserve remote history and collaborators' work.
