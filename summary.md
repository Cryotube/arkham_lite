## Current State
- Resource systems active: `ResourceLedger` autoload handles health/materials/oxygen/threat with threshold tracking, roll outcome hooks, and provisional persistence via `SaveServiceStub`.
- Run HUD mirrors the spec layout: left dock surfaces live room queue & active threats, right column hosts context details, milestone banner, action/equipment tabs, and a new onboarding tutorial overlay.
- Room & threat systems online: `RoomQueueService` feeds a 30-card deck, push-your-luck cycle/scout actions draw oxygen/threat costs, and `ThreatService` tracks timers, status effects, and attack patterns.
- Clue progression wired: `TurnManager` tallies clues, fires milestone mini-events via `EventResolver`, applies outcomes (resource deltas, scouting, threat spawns), and now routes telemetry + loot rewards to the equipment inventory grid.
- Telemetry stack in place: `TelemetryHub` autoload buffers loop/timing events from `TurnManager`, `ResourceLedger`, HUD tutorial flows, and game director lifecycle, ready for SDK integration.
- Headless test wrapper `scripts/run_gut_tests.sh` refreshes imports once and invokes GUT via CLI, so automated runs exit cleanly while surfacing current unit failures (ledger + turn manager).

## Outstanding Work
1. **Equipment Matrix & Action Economy**  
   - Implement equipment matrix UI, dice costs, and action economy hooks (Plan step 4).
2. **Threat & Room Content Polish**  
   - Author advanced threat behaviors (status decay, mini-objectives) and narrative events beyond milestones for soft launch depth.
3. **Mobile Readiness & Platform Hooks**  
   - Integrate analytics SDK/crash reporting, profile HUD on target devices, finalize export pipeline & controller/touch QA.

## Immediate Follow-Ups
- Profile HUD update cost in-editor (target <1 ms per update) and capture results.
- Wire TelemetryHub to preferred analytics SDK/crash reporter and verify event throughput.
- Run integration playthrough with milestone events + tutorial active, then update Story 1.2 to Ready for Review.
