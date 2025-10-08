# Dice Hold & Lock Validation Log

**Objective:** Assess current implementation against Luckitown-style dice ergonomics before development of Story 4.6.  
**Date:** 2025-10-08  
**Reviewer:** Codex orchestrator

## Scope
- Inspect existing Godot scripts to understand lock/hold mechanics.
- Draft validation checklist for future builds once holds implemented.
- Document current gaps.

## Findings
1. `scripts/systems/dice_subsystem.gd` maintains per-die state (`locked`, `exhausted`) but does not expose a distinct “hold” status. Lock toggles are driven via `_dice_subsystem.set_die_locked`.  
2. `scripts/ui/run_hud_controller.gd` emits `lock_requested` with `should_lock` but no workflow for a separate hold action; all UI tokens map to lock/unlock.  
3. Dice overlay currently shows “Locked” badge only (no hold indicator) and auto-rerolls unlocked dice on `request_roll()`.  
4. Telemetry/tutorial hooks (`run_hud_controller.gd` tutorial signals) make no mention of holding dice.

## Validation Checklist (for future build)
- [ ] Holding a die (press-and-hold or dedicated button) toggles “Hold” state distinct from “Lock”.  
- [ ] Held dice are visually tagged (badge + color) and excluded from rerolls.  
- [ ] Converting hold → lock (and vice versa) updates UI without desync.  
- [ ] Quick action prompts appear when held die matches build/spell requirement.  
- [ ] Telemetry captures hold usage; tutorial includes guidance.

## Manual Test Plan (post-implementation)
1. Roll dice with all unlocked; verify results change.  
2. Hold Die A via overlay; reroll → Die A value persists, others reroll.  
3. Release hold; reroll now changes Die A.  
4. Lock Die A, hold Die B → confirm commit/exhaust consumes locked die only.  
5. Attempt spend with insufficient resources → check hold tooltip shows reason.  
6. Controller navigation: hold action reachable via dedicated button; tooltips accessible.

## Status
- **Current build:** Hold mechanic not present; only lock/unlock available.  
- **Action:** Story 4.6 must introduce hold state in `DiceSubsystem`, update overlay UI, and extend tutorial/test coverage per checklist.

## Notes
- Once implementation lands, rerun checklist in target mobile build and capture screenshots for documentation.
