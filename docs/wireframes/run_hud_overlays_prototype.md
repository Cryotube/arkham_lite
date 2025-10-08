# Run HUD Overlay Prototype (Luckitown Alignment)

**Purpose:** Prototype interaction flow for board-first HUD refactor (Story 4.5) showing how players access room/threat info, context actions, and dice quick actions without persistent sidebars.

## Layout Overview
```
┌──────────────────────────────────────────────────────────────┐
│ Wave Timeline (collapse button)                              │
├──────────────┬─────────────────────────────┬─────────────────┤
│ Room Button  │ Encounter Board (focus)     │ Threat Button   │
│ (overlay)    │                             │ (overlay)       │
├──────────────┴─────────────────────────────┴─────────────────┤
│ Dice Overlay (floating shelf)   │ Lock Rail / Actions        │
└──────────────────────────────────────────────────────────────┘
```

- **Board** remains full width; overlays slide in as floating panels with 80% opacity background blur, leaving board visible.
- **Dice Overlay** sits inside board CanvasLayer; lock rail anchors bottom-right.

## Interaction Flows

### Room Overlay
1. Player taps “Rooms” badge (top-left) → `room_overlay_panel` animates from left with stack of room cards.
2. Selecting a room highlights target tile on board and opens contextual action chip near the tile.
3. Overlay auto-collapses on action or explicit close; pressing elsewhere retains selection but hides panel.

### Threat Overlay
1. Tap “Threats” badge (top-right) → vertical overlay listing active threats with timers.
2. Selecting threat spotlights lane using board pulses; context chip (Evade/Engage) appears adjacent to threat tile.
3. Overlay syncs with timeline; timeline tap also focuses corresponding threat entry.

### Context Action Chip
```
 ┌──────────────┐
 │ Enter Room   │
 │ Scout (L2)   │
 │ Cycle (O2)   │
 └──────────────┘
```
- Appears near selected room/threat; supports touch and controller (rotary focus).
- Chip auto-dismisses after action or board tap.

### Dice Quick Build
1. Holding a die promotes quick action icons near viable tiles (e.g., Build Beacon).
2. Drag die to tile or tap action icon → confirm modal appears if multiple costs.
3. Release returns die to shelf unless spent.

## States & Accessibility
- Overlays respect accessibility settings: large text mode increases card width; high-contrast uses solid backgrounds.
- Controller flow: shoulder buttons open overlays; D-pad navigates lists; `B` closes overlay.
- Timeline + overlays never overlap; timeline compresses when overlay open (animation spec TBD).

## Assets / Scenes
- `room_overlay_panel.tscn` (VBox cards, animated `AnimationPlayer`)
- `threat_overlay_panel.tscn`
- `context_action_popup.tscn` with pointer arrow anchored to board tile
- `dice_quick_action_chip.tscn` for hold interactions

## Open Questions
- Should timeline auto-expand on threat surge? (needs UX validation)
- How to persist overlay position on ultra-wide screens (consider using margins %).

## Next Steps
1. Translate flows into high-fidelity mockups (Figma) for dev handoff.
2. Align overlay animations with accessibility reduced-motion flag.
3. Coordinate with systems team on data hooks for quick actions and threat previews.
