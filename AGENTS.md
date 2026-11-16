# Instructions for Codex

Current full-map checkout: this directory, branch codex/resume-2026-11-15. The outer root's codex/terrain-chunks and its Rojo configs are historical. Do not run either outer default.project.json or rojo.current-place.project.json against this map: an alternate server caused repeated verified stale Source overwrites. Both are locally blocked for Place0/123243510098281. The active cloud Place123243510098281 now uses this checkout's `rojo-full.project.json` on localhost:34874 for 88 mapped scripts. One Rojo server and one Studio integrator at a time; disk `src` pushes to the cloud Studio, while the separate file-backed RBXL is not automatically updated. Read PROGRESS.md for verification and outstanding work. Preserve all older useful instructions below.

This is an existing Roblox game. Read README.md and HANDOFF.md before making changes.

This package now combines the related project chats. Also read START_HERE_RU.md, TECHNICAL_MAP.md, CHANGELOG.md and KNOWN_ISSUES.md. The latest explicit request and current implementation override historical reports.

- Speak Russian, explain simply, and execute one relevant step at a time.
- The finite mountain has 67525 runtime cells / 36 logical layers. Its 455-part Edit preview is intentionally different. Never add regeneration.
- Five standalone benches and the pergola with its bench were removed from the active map. Preserve ServerStorage.QuarryGardenFurnitureArchive and do not enable IncludeFurniture without a request.
- Keep the original distant dunes, mesas, oases and sand character. Keep the mountain visible; do not add large close rock formations or new hills as an unsolicited change.
- Studio loading was fixed by the owner enabling File > Experience Settings > Security > Enable Studio Access to API Services. The current cloud game loaded 67525 cells and reached Saved / revision 1. Do not reset profiles or replace the mountain to treat this configuration error.
- This package's primary RBXL is the latest downloaded local copy from D:/Projects/сад.rbxl. The previous Quarry Transit file is a backup. Confirm which actual Studio place is connected before edits.
- Existing cloud PlaceId: 123243510098281; UniverseId: 10776747096. Existing DataStore: DigMountainPlots_v1, player_<UserId>. No new wallet/store or silent migration to another experience.
- Existing Studio-only 10-million test balance for the owner is deliberate; do not make it a reward for all live players.

- The authoritative complete place is MY-ROBLOX-GAME.rbxl. Open that file in Roblox Studio.
- src/ is mapped to the cloud Studio by `rojo-full.project.json` (88 scripts, checked 16 November 2026). `script-manifest.json` records the instance paths. Studio edits do not automatically write back to disk.
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

## Общение — постоянное правило владельца, 16 ноября
Во время работы писать очень кратко: только действие или существенный результат. Не тратить текст на подробные планы и повторы. В конце небольшой отчёт: что добавлено/изменено, ошибки, непроверенное и следующий шаг.

Актуально после пакета комфорта:91скрипт вrojo-full.project.json/script-manifest.json, включая PlayerComfort server/client и QuarryCartoonStyle. Tab удерживать; спринтCtrl/Shift серверный, с тачкой/спуском не смешивать скорость. Не возвращать широкие автоматические HUD-панели и всплывающее+песок на каждый удар.

Конвейер — только ручнаязагрузка, перевозка и продажа. Автодобыча4/5удалена16ноября; не восстанавливатьизисторическихкопий. Балансv2:docs/BALANCE_V2.md, источникчиселUpgradeConfig.lua; не сбрасыватькошельки/покупки, не удалятьстарыйпереполненныйгруз.
