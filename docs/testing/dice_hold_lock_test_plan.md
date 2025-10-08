# Dice Hold & Lock Test Plan (Post-Implementation)

**Purpose:** Establish engineering + QA handoff steps once Story 4.6 lands. Complements `dice_hold_lock_validation.md`.

## Entry Criteria
- Hold state implemented in `dice_subsystem.gd` and exposed via UI.
- Telemetry and tutorial updates merged.
- Mockups and UX specs reviewed (see `docs/wireframes/run_hud_mockup_tasks.md`).

## Engineering Handoff Checklist
1. Confirm API changes:
   - `DiceSubsystem` exposes `set_die_held`, `get_held_indices`.
   - `RunHudController` emits hold events separate from lock events.
2. Update documentation:
   - HUD interaction guide.
   - Telemetry schema changelog.
3. Provide dev build with logging toggles for hold/lock events.
4. Walkthrough with QA covering hold vs lock, quick action prompts, accessibility toggles.

## QA Test Matrix
| Scenario | Touch | Controller | Keyboard/Mouse | Notes |
| --- | --- | --- | --- | --- |
| Hold die via overlay | ✓ | ✓ | ✓ | Ensure die retains value on reroll |
| Convert hold ↔ lock | ✓ | ✓ | ✓ | Visual states switch without desync |
| Hold + quick action build | ✓ | ✓ | ✓ | Verify board placement confirmation |
| Hold tooltip reason | ✓ | ✓ | ✓ | Trigger resource shortfall message |
| Accessibility large text | ✓ | – | ✓ | Badges scale without clipping |
| Reduced motion | ✓ | – | ✓ | Animations swap to fade |

## Regression Areas
- Dice exhaust/refresh cycle.
- Tutorial prompts (skip/next flow).
- Telemetry event volume (ensure batching unaffected).

## Exit Criteria
- All matrix scenarios signed off.
- No critical defects in dice flow.
- Telemetry dashboards reflect hold usage.

## Post-Release Monitoring
- Track hold adoption rate per session.
- Monitor tutorial completion drop-offs related to new prompts.
- Collect qualitative feedback on quick action placement.
