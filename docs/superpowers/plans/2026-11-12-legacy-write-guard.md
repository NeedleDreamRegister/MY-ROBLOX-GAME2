# Legacy-profile write guard

Continue the existing game. Live Studio is version 80, with additional work absent from local src. Routine implementation is delegated by the user; do not overwrite that newer work with yesterday's files.

Goal: prevent the observed 165-to-455 startup branch from replacing a profile before validation or lease acquisition.

Scope: ServerScriptService.SandPrototypePlots only. Keep its new scene/UI additions. Replace the legacy-reset branch with an explicit load failure; remove the associated SetAsync path. Existing-size and fresh-profile paths remain unchanged. This is containment until a non-destructive progression migration is implemented, not a finished migration.

- [ ] Capture all live script sources, template metadata and pre-edit local files.
- [ ] Execute the actual initialization block with fake services. Demonstrate legacy profiles reach SetAsync before the fix; require no writes after the fix, for unlocked and active-lease profiles, with an explicit migration-needed error.
- [ ] Apply the smallest patch with a compare-before-write guard; preserve newer unrelated Studio work.
- [ ] Verify fresh and current-size initialization still return their initial state without writes; run no real profile/Play test.
- [ ] Save Studio through save_place, then archive the patched source, tests and drift report. Do not publish or reconnect Rojo with stale files.

Review focus: active lease, expired lease, missing record, current geometry, local/Studio source divergence. No real DataStore calls are needed to test the unsafe initialization branch.
