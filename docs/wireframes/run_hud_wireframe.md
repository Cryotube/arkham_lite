# Run HUD Wireframe Refresh

## Current Implementation Findings
- **Context pane growth displaced dice tray** – Vertical VBox stacking let the context details expand without bounds, pushing the dice panel off-screen when long descriptions were shown. This violated the front-end spec’s “dice lock slots remain visible across the bottom strip” (spec §Turn Decision Loop) and PRD FR9 requirement for a persistent lock area.
- **Lock interaction mismatch** – HUD used per-die toggle buttons instead of the PRD-mandated drag-to-lock tray (FR9) and the DiceViewportPane spec, removing the tactile dice story experience.
- **Lack of drop affordances** – No dedicated lock slots or drag cues, so players had no visualization of which dice were banked vs available, conflicting with the spec’s lock slot guidance and accessibility heuristics.

## Revised Wireframe Layout
```
┌─────────────────────────────────────────────────────────────────────┐
│ Resource Panel (top stats bar)                                      │
├─────────────────────────────────────────────────────────────────────┤
│ Left Dock │ Context Pane │ Dice Viewport + Overlay Dice │ Lock Zone │
│           │               │  - 3D dice render            │  Slot 1   │
│           │               │  - Overlay tokens            │  Slot 2   │
│           │               │                               │  Slot 3   │
│           │               │ Action Buttons + Exhaust readout (stack) │
└─────────────────────────────────────────────────────────────────────┘
```
- Context pane now lives in a styled panel with internal scroll, preventing vertical growth from compressing the dice dock.
- Dice viewport overlay surfaces the draggable tokens so interactions originate from the rendered dice space; lock column sits directly beside it to reinforce the horizontal workflow.
- Lock zone exposes three dedicated slots (thumb-height 72 px) consistent with spec usage guidelines; lock label and teal highlight communicate interactivity.
- Dice tray messaging reinforces “drag into lock zone” behavior, aligning with spec callouts for onboarding clarity.

## Interaction Behaviors
- Dragging a die token into a lock slot locks it via `TurnManager.set_lock`, updates the slot visualization, and preserves position on subsequent rolls.
- Dragging a locked die back to the available row unlocks it; exhausted dice always return to the shelf with a dimmed state badge.
- Context pane actions (Enter/Cycle/Scout) remain thumb-accessible without affecting dice tray layout.

## Alignment Summary
- **PRD FR9** – 3D dice viewport + drag-to-lock tray implemented; locked dice highlighted and retained.
- **Front-End Spec: DiceViewportPane & LockedDiceSlot** – New `DiceDock` hierarchy mirrors the spec’s PanelContainer + lock tray structure, including slot sizing and visibility requirements.
- **Usability Goals** – Primary actions, lock zone, and dice results stay within simultaneous reach; context pane changes no longer displace the dice UX.
