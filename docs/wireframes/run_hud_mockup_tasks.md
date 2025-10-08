# Run HUD Mockup Task List

**Goal:** Track design deliverables needed to support Stories 4.5–4.7 prior to development handoff.

## Deliverables
1. **Overlay Layout Mockups**
   - Room overlay (list + card detail)
   - Threat overlay (list + lane highlight)
   - Context action chip variants (room vs. threat)
   - Responsive states: 16:9, 18:9, ultrawide monitor
2. **Dice Hold & Quick Action Visuals**
   - Held vs locked badge styling
   - Per-face iconography grid with tooltip annotations
   - Quick action chip placement states
3. **Wave Timeline & Board Signals**
   - Timeline default, expanded, and reduced modes
   - Lane pulse treatments for standard/high contrast
   - Reduced-motion alternative (fade vs. pulse)

## Workflow
- Build high-fidelity mockups in Figma with component variants.
- Export annotated PNG/WEBP slices for engineering reference.
- Document interaction notes alongside each frame (hover, focus, animation cues).

## Owners & Dependencies
- **Primary Designer:** TBD (assign UX owner)
- **Collaborators:** Systems (threat data), Audio (alert cues), Accessibility (contrast & motion)
- Coordinate with Story 4.3 team for shared theme assets.

## Timeline
- Week 1: Draft wireframes + review with UX/Prod.
- Week 2: Finalise interactions, produce assets, attach to story tickets.
- Week 3: Engineering walkthrough & acceptance tweak cycle.

## Open Questions
- Should context chips auto-collapse on cursor move or require explicit dismiss?
- Do we integrate tutorial callouts directly into overlays or separate walkthrough?
- Controller iconography: standard Xbox/PlayStation prompts or custom glyphs?
