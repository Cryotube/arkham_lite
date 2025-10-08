# Luckitown Alignment Story Review

**Context:** Review of newly drafted UX stories (4.5, 4.6, 4.7) against Luckitown board-first experience and existing Bermuda Sector PRD/front-end spec.  
**Reviewer:** UX/PM hybrid (Codex orchestrator)  
**Date:** 2025-10-08

## Summary Assessment
- Stories capture the right themes—board-centric HUD, tactile dice loop, threat telegraphing—and map to concrete scene/script updates.  
- Scope overlaps exist with Story 4.3 Accessibility & UX Refinements; ensure layout changes coordinate with accessibility requirements.  
- Risks: engineering effort spans UI refactor + gameplay wiring. Each story should include cross-team dependencies (systems, UI, audio).

## Story Feedback

### 4.5 Board-Centric Run HUD Layout
- ✅ Clearly states conversion to overlay-based room/threat access and board-first layout.  
- ⚠️ Missing reference to responsive behaviour when popups coincide (e.g., room overlay + wave timeline). Add acceptance criteria for interaction stacking and controller navigation loops.  
- Recommendation: include design deliverables (mockups, interaction map) as explicit subtasks before implementation.

### 4.6 Dice Loop Clarity & Holds
- ✅ Addresses Luckitown-style holding and per-face affordances.  
- ⚠️ Current code lacks concept of “hold” separate from “lock”; story should call out need for new state in `DiceSubsystem` and telemetry updates when holds used.  
- Recommendation: add acceptance criterion for tutorial/tooltips introducing holds and integrate with existing PRD tutorial beats.

### 4.7 Threat Wave Telegraph & Board Signals
- ✅ Targets replacement of banner alerts with board-integrated signaling.  
- ⚠️ Need to confirm data availability from `threat_service`; timeline depends on predictive threat data. Include dependency and fallback plan if data missing.  
- Recommendation: add accessibility check (contrast/animation toggle) to align with Story 4.3.

## Prioritisation Notes
- Suggested sequence: 4.5 (layout foundation) → 4.6 (dice ergonomics) → 4.7 (threat timeline) to avoid rework.  
- Consider splitting 4.5 into layout refactor vs. overlay content to reduce risk.

## Next Actions
1. Update stories with added acceptance criteria/dependencies above.  
2. Produce design prototypes (wireframes/flows) for overlays and quick actions (tracked separately).  
3. Socialise with dev/QA leads before sprint planning.
