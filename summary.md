## Current State
- Core systems are in place: `ResourceLedger`, `TurnManager`, `RoomQueueService`, `ThreatService`, and `EventResolver` coordinate rooms, threats, and milestone events with telemetry hooks.
- Equipment matrix backend exists (`EquipmentInventoryModel`) with resource-driven modules, rotation and collision checks, and burden tracking; HUD exposes a basic grid and inventory list without drag interactions.
- HUD scaffolding covers rooms/threat lists, context pane, milestone banner, and equipment tab; tutorials, accessibility options, and advanced visuals remain placeholders.
- Automated GUT suite (`scripts/run_gut_tests.sh`) passes, covering ledger, turn, and equipment model logic.

## Outstanding Work
1. **Equipment UX & Feedback**  
   - Implement actual drag-and-drop interactions, hover previews, haptic/audio cues, and quick-remove radial menu per spec.  
   - Flesh out `EquipmentFeedbackService` with pooled overlays and integrate rotate/remove affordances across input modes.
2. **Dice/Economy Integration**  
   - Bind equipment to dice tray and action economy: consume dice costs, apply equipment effects through `TurnManager`, adjust burden penalties, and surface slot highlights in HUD.  
   - Extend telemetry to track equipment activations and dice usage.
3. **Tutorial & Onboarding**  
   - Build contextual tutorial flows with step resources, skip/replay support, and analytics on drop-off points.  
   - Populate HUD overlays with authored copy and integrate with gameplay triggers.
4. **Accessibility & Settings**  
   - Add settings scene for text scaling, colorblind palettes, reduced motion, vibration toggle, and simplified controls.  
   - Ensure HUD/equipment layouts respond to larger fonts and alternate themes without overlap.
5. **Atmosphere & Presentation**  
   - Deliver dynamic lighting, audio ambiance, particle/VFX treatments, and responsive dice viewport visuals aligned with PRD tone.  
   - Profile performance on target devices to maintain 60 FPS after visual upgrades.
6. **Progression & Content Depth**  
   - Implement loot tables, equipment effects, cooldowns, XP/level-up system, and meta progression unlocks.  
   - Author additional threats, rooms, and gear resources to showcase the inventory puzzle.
7. **Analytics & Platform Readiness**  
   - Integrate crash reporting/analytics SDK, wire TelemetryHub events (tutorial, accessibility toggles, equipment usage), and finalize export pipeline with QA checklists.

## Orchestrated Plan
1. **Equipment Interaction Prototype**  
   - Agents: game-ux-expert (drag/feedback UX spec), game-developer (Godot prototype wiring), game-qa (hover performance validation).  
   - Deliverables: Interaction spec, prototype scene with pooled overlays, telemetry timings.  
   - Success Gate: Drag/rotate/remove loop stable with hover cost ≤0.8 ms.
2. **Tutorial Flow Authoring**  
   - Agents: game-designer (step scripts + trigger map), game-po (acceptance alignment), game-developer (HUD hook-ups).  
   - Deliverables: Tutorial script assets, trigger matrix, integration checklist.  
   - Success Gate: Playable onboarding path with skip/replay plus analytics hooks defined.
3. **Accessibility Audit & Settings Layout**  
   - Agents: game-ux-expert (contrast/dynamic type audit), game-architect (responsive HUD layout plan), game-developer (settings scene scaffolding), game-qa (accessibility verification).  
   - Deliverables: Audit report, responsive layout spec, settings scene stub, QA acceptance grid.  
   - Success Gate: HUD adapts to large text/color palettes without overlap and settings toggles mapped to systems.
