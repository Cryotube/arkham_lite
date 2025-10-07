## Current State
- Resource systems active: `ResourceLedger` autoload handles health/materials/oxygen/threat with threshold tracking, roll outcome hooks, and provisional persistence via `SaveServiceStub`.
- Run HUD top bar implemented: `resource_panel.tscn` + controllers display meters, color-coded warnings, and threat cues aligned with PRD/UX.
- Turn flow integrates ledger updates; roll commits now drive resource changes.
- Headless test wrapper `scripts/run_gut_tests.sh` refreshes imports once and invokes GUT via CLI, so automated runs exit cleanly while surfacing current unit failures (ledger + turn manager).

## Outstanding Work
1. **Room & Threat Systems**  
   - Build room queue + baseline threat services and corresponding HUD/interaction panels (Plan step 3).
2. **Equipment Matrix & Action Economy**  
   - Implement equipment matrix UI, dice costs, and action economy hooks (Plan step 4).
3. **Tutorial, Telemetry, Mobile Readiness**  
   - Layer onboarding flow, analytics/crash hooks, export validate (Plan step 5).

## Immediate Follow-Ups
- Add `class_name TurnManager` (and adjust tests if needed) so `tests/unit/test_turn_manager.gd` can instantiate the system; fix follow-on nil errors.
- Investigate why `ResourceLedgerSingleton.set_health()` does not emit `health_changed` when clamping negatives (failing expectation in `tests/unit/test_resource_ledger.gd:26`); align signal behavior or update test.
- Profile HUD update cost in-editor (target <1 ms per update) and capture results.
- Run integration playthrough once room/threat systems exist, then update Story 1.2 to Ready for Review.
