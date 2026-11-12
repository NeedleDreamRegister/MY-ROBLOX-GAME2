# HUD availability and narrow-screen verification

Continue the existing shovel/usability stage; no economy, sand or save-schema changes.
User delegated routine design and execution without questions.

- Reproduce contradictory digging hints for LockLost and overflowing full-bag hint at 245px card width.
- Keep the current HUD structure. Override interaction hints for Loading, Locked, LoadFailed, SaveFailed and LockLost. Shorten the full-bag hint; highlight Locked as an unavailable world.
- Add a Client-only smoke check that restores locally changed attributes, verifies halted hints, checks all labels fit for empty/partial/full bags across all nine statuses, and preserves inventory values.
- Run before/after on portrait phone, then landscape and desktop. Run the existing 17 snapshot and 9 save-session cases.
- Restore PersistenceEnabled=true and default simulator, compare Studio/source files, regenerate the recovery installer and document publication limits.
