# Bermuda Sector Godot Product Requirements Document (PRD)

## Goals and Background Context

### Goals
- Deliver quick yet high-stakes dungeon runs that feel like tense solo board game sessions.
- Provide meaningful resource juggling across health, materials, oxygen, and the escalating threat meter every turn.
- Make dice-driven turns and action spending feel rewarding—each roll acts as a discrete turn where players decide which dice to spend, lock, or exhaust.
- Layer Arkham Horror–style room exploration, where a limited room queue offers variable search difficulty, threat, and rewards (especially critical clues/parts) that drive progress toward escape.
- Design threat encounters that “latch” onto the player and attack on their own cadence, forcing choices between attrition combat and risky evasions.
- Support build diversity via distinct Strength, Intellect, and Agility dice (with later wild/unique faces) and a Resident Evil–style equipment matrix that shapes tactics.
- Keep runs short enough for mobile play while preserving strategic depth and replayability.
- Build a distinctive sci-fi horror mood around the Bermuda Sector’s mystery and isolation.

### Background Context
Bermuda Sector follows a stranded spacefarer trying to escape a derelict station trapped in a cursed pocket of space. Each roll of the dice acts as a turn, echoing Luckitown’s cadence and Arkham Horror’s tension: spent dice slide into an exhausted pool that refreshes on the next roll, and players choose which results to bank or reroll via scarce actions. Exploration revolves around a limited queue of room cards—some safer, others lethal. Every room presents unique search difficulties, bespoke rewards, and lurking events. Chief among the rewards are clues/parts: assembling enough clues is the primary path to victory, mirroring Arkham Horror’s clue economy. Players must weigh burning time to cycle the queue for better opportunities against pushing their luck with the rooms they have to keep the escape plan alive.

Threats emerge from rooms and latch onto the player, much like Arkham Horror, Aeon’s End, or Marvel Champions. Latched threats operate on their own timer: at fixed intervals they roll their own dice to inflict damage or negative effects. Players respond by either whittling the threat down through combat—spending attack symbols to destroy it, reduce global threat, and earn experience—or by executing evasions that demand specific symbol sets, typically agility-oriented. Combat decisions feed directly into the Resident Evil–style equipment matrix; modules in the inventory grid consume dice to unleash attacks, convert symbols, mint temporary dice, gather resources, or trigger exploratory gambits. Every choice balances dwindling health, scavenged materials, and limited oxygen reserves against the rising threat meter that governs forced encounters. Targeting mobile dungeon-crawl fans, the game emphasizes short, replayable sessions blending calculated risk, clue hunting, and relentless threat pressure, all built in Godot 4.5 for iOS and Android landscape play.

### Change Log
| Date       | Version | Description                                                                                                             | Author           |
|------------|---------|-------------------------------------------------------------------------------------------------------------------------|------------------|
| 2025-10-05 | v0.2    | Added problem statement, player personas, KPIs, MVP validation plan, NFRs, risk register, timeline, and post-launch strategy. | Codex (game-po)  |
| 2025-10-02 | v0.1    | Initial PRD skeleton draft; documented dice loop, room queue/clue system, threat latching combat, equipment matrix, oxygen. | game-pm (AI)     |

## Problem Statement & Opportunity
- Mobile roguelike fans lack a tense, session-length friendly experience that blends dice-driven tactics with Arkham Horror style threat escalation.
- Existing board game conversions skew toward premium price points or heavy UX, leaving a gap for a focused mobile-first experience with short runs.
- Bermuda Sector positions itself as a premium $4.99 launch with optional cosmetic expansions, targeting players who enjoy calculated risk and strategic loadout planning.

## Player Personas & Motivations
- **Persona A: Tactician on the Go** – Age 28-40, plays Marvel Snap, Slay the Spire, and Dicey Dungeons. Motivated by quick yet deep sessions during commutes. Seeks meaningful choices each turn and transparent odds. Expects polished UX on modern phones and controller optionality.
- **Persona B: Atmospheric Story Seeker** – Age 24-38, enjoys Arkham Horror, Into the Breach, and narrative roguelikes. Values ambience, lore snippets, and steady progression between runs. Looks for mobile games that respect her time and provide accessibility toggles.

## Success Metrics & KPIs
- Launch KPI targets: D1 retention >= 35%, D7 >= 15%, average session length 8-12 minutes, 3 runs per day within first week.
- Monetization targets: 8% cosmetic attachment rate within 90 days, breakeven with 30k paid downloads.
- Quality targets: Apple App Store and Google Play rating >= 4.5, crash-free sessions >= 98%, average frame time <= 16.67 ms on reference devices (A13, Snapdragon 765G).

## MVP Scope & Validation Plan
- MVP includes: dice roll core loop, resource ledger, room queue with 12 baseline rooms, single threat archetype with latching behavior, basic equipment matrix with starter gear, tutorialized first run, analytics + crash reporting, iOS/Android exports.
- Deferred to post-MVP: remote config tuning, multiple threat archetypes, seasonal live ops, advanced accessibility suite, controller UX polish.
- Validation: closed alpha with 50 players sourced from roguelike communities, instrumented telemetry dashboards tracking run length, failure reasons, tutorial drop-off.
- Success exit criteria: 3 consecutive builds meeting KPI proxies (>=10 runs/user, average frame time within budget, tutorial completion >= 70%) and qualitative feedback highlighting tension satisfaction.

## Research & Assumptions
- Competitive scan (Luckitown, Dicey Dungeons, Tainted Grail) indicates appetite for dice tactics but gaps in sci-fi horror theme.
- Players accept premium pricing when content depth justifies; plan for no gacha or stamina mechanics to maintain trust.
- Assume single-player offline is sufficient for MVP; online leaderboards considered later.
- Localization limited to English at launch; architecture must remain localization-ready for expansion.

## Requirements

### Functional
- FR1: Maintain a persistent queue of discoverable rooms, each with defined search difficulty, reward tables (including clues/parts), and potential threat/event triggers.
- FR2: Treat every dice roll as a discrete turn where players spend, lock, or exhaust Strength/Intellect/Agility dice, with exhausted dice automatically refreshing on the following roll.
- FR3: Drive all skill checks (explore, search, hack, unlock, evade) via symbol-matching tests against the player’s current dice pool and any equipment modifiers.
- FR4: Implement a Resident Evil–style equipment matrix that houses modules able to consume dice for effects such as damage, symbol conversion, temporary dice creation, resource gains, or exploration boosts.
- FR5: Spawn threats that latch onto the player, roll their own attack dice on scheduled intervals, and can be neutralized either through damage thresholds or symbol-based evasions.
- FR6: Track and update core resources—health, materials, oxygen, and the global threat meter—after every action or encounter resolution, reflecting gains, losses, and escalating pressure.
- FR7: Require players to collect a configurable number of clues/parts to trigger the endgame escape sequence and determine victory conditions.
- FR8: Support action economy mechanics that let players spend limited actions/time to reroll selected dice, cycle the room queue, or trigger equipment abilities, with appropriate penalties for inaction.
- FR9: Render dice rolls within a 3D viewport embedded atop the 2D HUD, allowing drag-and-drop placement of rolled dice into a lock area, and highlight dice slated for exhaustion with a shader-driven edge glow when confirming actions.

### Non-Functional Requirements
- NFR1: Maintain a steady 60 FPS on mid-range iOS and Android devices (Apple A13, Snapdragon 765G) in landscape orientation even during dice physics spikes.
- NFR2: Keep cold-start load times under 8 seconds and resume-from-background under 2 seconds on reference devices.
- NFR3: Preserve crash-free sessions above 98% with health metrics reported through Sentry.
- NFR4: Provide high-contrast UI elements, scalable typography (up to 140%), and color-blind friendly palettes for key symbols.
- NFR5: Ensure all interactions remain touch-first, with optional controller parity tracked as a backlog item.
- NFR6: Allow uninterrupted offline play for core loop; analytics batches must gracefully queue until connectivity returns.
- NFR7: Keep battery consumption under 12% per 30-minute session on reference devices through pooling and frame budget monitoring.
- NFR8: Conform to GDPR/CCPA requirements by supporting opt-in analytics and secure local storage encryption.

## Game UI/UX Design Goals

### Overall Game UX Vision
- Provide a “tactical control deck” feel: quick access to dice, equipment matrix, and room queue in a single landscape view so players can assess options at a glance.
- Lean into tense sci-fi horror ambience with subdued palette, dynamic lighting, and subtle motion cues that do not obscure critical symbols or timers.
- _Assumption:_ Prioritizing one-screen clarity over cinematic presentation; horror tone relies more on UI mood than heavy cutscenes.

### Control Schemes and Input Methods
- Tap-to-select dice and drag to slot them into actions/equipment; swipe gestures cycle room queue or switch to secondary panels (codex, map).
- Context-sensitive buttons for rerolls, action spending, and threat responses to minimize menu diving during short sessions.
- _Assumption:_ Players prefer minimal gesture vocabulary; no external controllers planned.

### Core Game Screens and Menus
- Main Menu (resume run, new run, settings, codex).
- Run HUD (central playfield showing dice tray, equipment matrix grid, room queue, threat tracker, resource meters).
- Threat Detail Overlay (latched enemies, attack timers, combat/evasion options).
- Inventory & Loadout (matrix arrangement, equipment management, dice upgrades).
- Event/Encounter Resolver (focuses on narrative text, required symbols, possible outcomes).
- Post-Run Debrief (stats, XP earned, unlocks).
- _Assumption:_ Keeping overlays lightweight rather than separate full-screen transitions to preserve pace.

### Accessibility: Basic
- Include adjustable text size, symbol labels/tooltips, and color-blind-safe palette presets for dice symbols.
- _Assumption:_ Starting with “Basic” toolkit; more advanced features (e.g., full remapping, narration) to be scoped later.

### Branding
- Stark sci-fi horror aesthetic: deep blues/teals contrasted with warning reds and glitch motifs; typography inspired by naval HUDs.
- Die faces use crisp iconography that reads well at small sizes; equipment cards styled like salvaged ship schematics.
- _Assumption:_ No existing IP/style guide; drawing from thematic references.

### Target Platforms: Mobile Only
- iOS (landscape, MFi controller optional in backlog).
- Android (landscape, Play Store focus).
- _Assumption:_ No plans for PC/console; could revisit if scope widens.

## Godot Technical Assumptions

### Godot Version: Godot 4.5
- Target stable release for shipping; keep 4.4 as fallback branch if regressions surface.

### Game Architecture
- Single-player, offline-focused roguelike with no real-time networking.
- 2D tile/room-based presentation using Godot 4’s 2D renderer plus lightweight 3D lighting overlays for atmosphere (_assumption to confirm_).
- Primary scripting in statically typed GDScript for rapid iteration, covering all gameplay, systems, and tooling to avoid cross-language overhead.

### Testing & QA Requirements
- Manual playtesting loops for balance, dice odds, and UX friction on key devices (A13, Snapdragon 765G).
- Automated unit tests covering dice logic, threat timers, resource math, and room queue randomization.
- Integration smoke tests scripted via Godot’s testing toolkit to verify save/load persistence and equipment matrix operations.
- Performance profiling for 60 FPS target; automated frame-time capture in CI for critical scenes on 4.5.
- Mobile certification prep: iOS TestFlight and Android internal testing with crash reporting (Sentry/Firebase).

### Additional Godot Technical Assumptions
- Save system uses Godot’s JSON-based persistence with encrypted slots for run state; cross-platform save parity required.
- UI built with Godot Control nodes optimized for landscape mobile; virtual cursor avoided.
- Audio pipeline via Godot’s AudioServer with lightweight dynamic music layers for tension escalation.
- Localization-ready text pipeline using built-in translation server; start with English but structure for later languages.
- Dependence on open-source plugins limited to vetted mobile-stable assets (e.g., BetterInput?)—confirm licensing before lock-in.
- Memory budget target < 450 MB peak on mid-range devices to prevent OS kills.

## Epic List
1. **Epic 1: Crash Survivor Foundation** — Stand up the Godot 4.5 project, core dice engine, resource trackers, and first batch of room/threat cards so players can complete a minimal escape run.
2. **Epic 2: Threat Escalation & Room Depth** — Expand the room queue, add diverse threat behaviors (latching, timers, evasion patterns), and layer clue-driven objectives to deepen the push-your-luck loop.
3. **Epic 3: Equipment Matrix & Progression** — Implement the Resident Evil–style inventory grid, gear acquisition, dice upgrades, and experience/clue rewards that unlock deeper builds.
4. **Epic 4: Atmosphere, UX Polish & Live Ops Hooks** — Refine UI/UX, audio/visual mood, accessibility, analytics hooks, and post-run/meta progression needed for launch readiness.

## Epic 1 Crash Survivor Foundation
Goal: Deliver a functional Bermuda Sector prototype that proves the dice-turn loop, core resource tracking, and a minimal room/threat encounter on mobile. Establish project scaffolding in Godot 4.5 with touch-ready HUD so players can complete a single short escape attempt end-to-end. Lay groundwork for future content by making the dice engine, resource systems, and save hooks modular.

### Story 1.1 Godot Project Spine & Dice Loop Skeleton
As a lone spacefarer who crash-landed in the Bermuda Sector,
I want the game to open into a playable Godot 4.5 scene with a working dice roll/exhaust loop,
so that every turn flows smoothly on mobile and I can feel the core board-game cadence.

#### Acceptance Criteria
1. Project builds in Godot 4.5 on iOS/Android with landscape splash and passes smoke test.
2. Dice tray UI shows Strength/Intellect/Agility dice, supports roll → spend/lock → exhaust → refresh cycle.
3. Exhausted dice automatically refill on the next roll and animations communicate the state change.
4. Touch inputs for rolling, locking, and spending dice respond within 150 ms and are logged for debugging.

### Story 1.2 Resource & Threat Track Meters
As the trapped survivor,
I want clear meters for health, materials, oxygen, and the global threat level,
so that I can judge whether to press forward or retreat before the station overwhelms me.

#### Acceptance Criteria
1. HUD displays four resource meters with numeric values and warning thresholds (yellow/red).
2. Dice spending and scripted events can modify each resource with immediate UI feedback.
3. Threat meter triggers a visual/audio cue when crossing defined escalation bands.
4. Resource state persists across scene reloads via provisional save data.

### Story 1.3 Prototype Room Queue & Exploration Actions
As the stranded explorer,
I want a room queue that feeds me two active rooms plus a backlog,
so that I can pick between exploring, cycling, or preparing before moving deeper into the station.

#### Acceptance Criteria
1. Room queue populates from JSON/Resource data with difficulty, rewards, and event hooks.
2. Selecting a room consumes an action, shows its details, and can queue a new room from the deck.
3. Exploration outcomes can award materials or clues and adjust threat based on room metadata.
4. Empty queue automatically replenishes from the deck and shuffles when exhausted.

### Story 1.4 First Threat Encounter & Escape Resolution
As the besieged spacefarer,
I want to face a single latched threat and either neutralize it or escape with enough clues,
so that a full minimal run proves the game loop end-to-end.

#### Acceptance Criteria
1. Threat card attaches after a scripted trigger, displays attack timer, and rolls its dice when timer expires.
2. Player can resolve the threat via combat (damage threshold) or evasion (Agility symbols) with appropriate resource costs.
3. Collecting a configured number of clues unlocks an escape prompt; failure triggers a defeat screen.
4. Post-run summary shows resources, time taken, and outputs telemetry stub for future analytics.

## Epic 2 Threat Escalation & Room Depth
Goal: Enrich the push-your-luck loop with a broader variety of rooms, evolving threat behaviors, and clue-driven progression beats. Introduce dynamic events, modifiers, and chained encounters so decisions about time spent cycling rooms versus tackling current options carry meaningful consequences. Reinforce the horror tension through escalating threat reactions and narrative snippets.

### Story 2.1 Advanced Room Decks & Events
As the stranded spacefarer,
I want diverse room archetypes with unique modifiers and narrative events,
so that every exploration choice feels fresh and risky.

#### Acceptance Criteria
1. Room data expanded to at least 30 unique cards with tags (hazard, cache, sanctuary, anomaly).
2. Each room type defines base difficulty, reward tables, and threat/event triggers.
3. Event resolver surfaces contextual story text and choices that alter resources or future rooms.
4. Deck-building rules ensure composition (e.g., max 3 anomalies) and shuffle weights configurable via data file.

### Story 2.2 Threat Timer Variants & Status Effects
As the beleaguered survivor,
I want threats that attack on different cadences and inflict varied debuffs,
so that I must prioritize targets and manage escalating pressure.

#### Acceptance Criteria
1. Threat cards support custom attack timers (immediate, every turn, delayed burst).
2. Threat dice can inflict status effects (bleed, oxygen leak, dice lock) with UI icons and durations.
3. Global threat meter reacts to unresolved threats (e.g., +1 threat each full cycle).
4. Combat log tracks threat actions for later tuning and QA review.

### Story 2.3 Clue Milestones & Mini Objectives
As the would-be escapee,
I want milestone events when collecting clues/parts,
so that progress feels tangible and opens mid-run twists.

#### Acceptance Criteria
1. Clue counter triggers scripted mini objectives at thresholds (e.g., power up beacon, decode map).
2. Mini objectives present optional challenges that can reward gear or lower threat.
3. Failing a mini objective carries consequences (threat spike, oxygen drain).
4. Victory sequence now requires final objective completion plus clue threshold.

### Story 2.4 Push-Your-Luck Time Mechanics
As the cautious yet desperate survivor,
I want to spend actions/time to cycle room options or scout ahead,
so that I can manage risk instead of blindly diving into danger.

#### Acceptance Criteria
1. New actions allow discarding top room for a time/oxygen cost and drawing replacements.
2. Scouting action reveals upcoming room card with partial info and temporary modifier.
3. UI communicates action costs clearly and prevents negative resource states.
4. Telemetry captures time spent cycling vs. accepting rooms for balancing.

## Epic 3 Equipment Matrix & Progression
Goal: Deliver the Resident Evil–style inventory system, gear progression, and dice upgrades that let players craft distinct builds. Enable loot discovery, equipment crafting, and XP-driven leveling paths that unlock specialized dice faces or abilities, making long-term strategy pay off.

### Story 3.1 Equipment Matrix UI & Constraints
As the stranded survivor,
I want a grid-based equipment matrix with drag-and-drop placement,
so that I can manage limited space and plan my loadout.

#### Acceptance Criteria
1. Matrix grid supports rotating and placing equipment cards of varying shapes.
2. Collision/overlap rules prevent invalid placements and provide haptic/audio feedback on errors.
3. Equipped items can bind to dice slots or passive effects as defined in data.
4. UI shows total burden and quick-remove options without blocking combat flow.

### Story 3.2 Loot Generation & Gear Effects
As the scavenging survivor,
I want meaningful loot drops that slot into the matrix and consume dice to trigger effects,
so that gear collection changes my tactics.

#### Acceptance Criteria
1. Loot tables tie to room/threat types and progression depth.
2. Gear items define dice costs, effects (damage, conversion, resource gain), and cooldowns.
3. Consuming dice via equipment resolves immediately and updates exhaust pool.
4. Rare items introduce wild/unique symbols and representational visuals distinct from commons.

### Story 3.3 Experience & Level-Up Choices
As the growing expert survivor,
I want to gain XP from threats and objectives and choose upgrades that expand my dice pool,
so that my build reflects my preferred strategy.

#### Acceptance Criteria
1. XP system tallies rewards and offers level-up nodes after thresholds.
2. Level-up screen presents at least three upgrade options (new die, symbol modifier, passive perk).
3. Selected upgrades immediately modify dice tray and persist in saves.
4. Reject option allows banking level until next safe moment at minor cost.

### Story 3.4 Meta Progression & Unlocks
As a returning player,
I want persistent unlocks and codex entries that encourage repeated runs,
so that I feel motivated to dive back into the Bermuda Sector.

#### Acceptance Criteria
1. Complete runs (win/lose) log achievements and unlock new room/threat cards or equipment.
2. Meta progression screen showcases unlock tree with prerequisites.
3. Codex tracks discovered threats, rooms, and gear with lore snippets.
4. Save system supports multiple profiles and syncs unlocks across devices (if platform permits).

## Epic 4 Atmosphere, UX Polish & Live Ops Hooks
Goal: Elevate the presentation, usability, and retention layer for launch. Polish visual/audio mood, expand accessibility, tune onboarding, and integrate analytics/live ops scaffolding so the game is ready for store submission and post-release support.

### Story 4.1 Visual & Audio Atmosphere Pass
As the immersed survivor,
I want the station to feel eerie yet readable,
so that the tension is palpable without sacrificing clarity.

#### Acceptance Criteria
1. Implement dynamic lighting, particle, and shader effects tuned for mobile performance.
2. Add layered soundtrack that reacts to threat meter and ambient SFX per room type.
3. Provide graphics settings toggle (performance vs. fidelity) with real-time preview.
4. Ensure visual clarity of dice symbols and UI under atmospheric effects.

### Story 4.2 Onboarding & Tutorials
As a new recruit of the Bermuda Sector,
I want interactive onboarding that teaches dice management, room selection, and threat handling,
so that I can survive my first run without confusion.

#### Acceptance Criteria
1. Contextual tutorial prompts trigger during first run with optional replay.
2. Tutorial steps include skip/next controls and track completion state.
3. Provide “Learn More” codex entries for advanced mechanics (equipment matrix, status effects).
4. Analytics flag tutorial drop-off points for UX iteration.

### Story 4.3 Accessibility & UX Refinements
As a diverse audience of survivors,
I want accessibility options that let me tailor the interface to my needs,
so that the game remains playable in different conditions.

#### Acceptance Criteria
1. Settings include text scaling, color-blind palettes, vibration toggle, and simplified controls mode.
2. UI layouts adapt to larger fonts without overlapping elements.
3. Audio cues have caption equivalents where necessary.
4. Conduct heuristics review and address identified UX pain points.

### Story 4.4 Analytics & Live Ops Foundations
As the product team,
We want telemetry and live ops hooks to monitor engagement and support post-launch updates,
so that we can respond quickly to player behavior.

#### Acceptance Criteria
1. Integrate analytics SDK (platform-appropriate) capturing runs, session length, upgrade choices, and failure causes.
2. Implement remote config for balancing key parameters (threat timer, drop rates) without code pushes.
3. Add crash/error reporting tied to gameplay context (room, threat, dice state).
4. Prepare live ops dashboard prototype with data summaries for the first soft launch.

## Data & Telemetry Requirements
- Instrument core loop events: dice roll outcomes, threat triggers, room choices, equipment activations, resource deltas, tutorial progression, run completion.
- Batch telemetry through `TelemetryHub` every 10 events or 15 seconds, with offline queueing and retry backoff.
- Capture anonymized device info (OS, GPU tier) to compare performance against FPS targets.
- Store analytics in OpenGameAnalytics with dashboards highlighting funnel drop-offs and failure causes.
- Collect qualitative feedback at end of runs during alpha/beta builds via optional prompt.

## Platform & Deployment Plan
- Export templates: Godot 4.5 official iOS/Android; maintain nightly smoke export pipeline.
- CI/CD: GitHub Actions (macOS + Linux) running unit tests, GUT suites, and performance harness via `scripts/godot-cli.sh`.
- Distribution path: Internal QA -> Closed Alpha (TestFlight/Play Console) -> Soft Launch (Canada, Australia) -> Global release.
- Compliance: App Store privacy nutrition labels, Google data safety declarations, COPPA inapplicable (13+ rating).
- Support workflow: Crash and telemetry alerts piped to Slack channel with on-call rotation.

## Risk Register
| Risk | Probability | Impact | Mitigation | Owner |
| ---- | ----------- | ------ | ---------- | ----- |
| 3D dice performance spikes on mobile | Medium | High | Implement aggressive pooling, limit dice count per roll, measure on target hardware each sprint | Tech Lead |
| Godot 4.5 regressions or plugin instability | Medium | Medium | Pin engine to 4.5.0, keep 4.4 branch fallback, vet plugins and maintain upgrade checklists | Tech Lead |
| Content fatigue due to limited room/threat variety at launch | Medium | Medium | Build modular room/threat authoring pipeline, prioritize additional packs for first update | Design Lead |
| UX overwhelm on small screens | Low | High | Enforce HUD usability heuristics, run early usability tests with 7" devices | UX Lead |
| Analytics opt-out leaves gaps in balancing data | Low | Medium | Pair telemetry with qualitative surveys and manual playtest logs | Product |

## Team & Timeline
- Core team: 2 Godot engineers (GDScript), 1 technical designer/content author, 1 UX/visual designer, 0.5 QA contractor, part-time composer/sound designer.
- Phases & estimates:
  - Prototype (6 weeks): establish dice loop, room queue, threat skeleton, baseline HUD.
  - Vertical Slice (8 weeks): implement equipment matrix MVP, resource ledger, first threat archetype, tutorial stub.
  - Content Expansion (10 weeks): expand rooms to 30 cards, add threat variants, integrate analytics, refine UX.
  - Soft Launch Prep (6 weeks): polish, localization scaffolding, platform compliance, live ops hooks, marketing assets.
- Milestones reviewed bi-weekly with burn-up charts tracking story completion vs scope.

## Post-Launch Strategy
- First 30 days: monitor telemetry, hotfix critical crashes, release balance patch adjusting rooms/threat timers per data.
- 60-90 days: introduce new dice faces, equipment modules, and room pack DLC; enable seasonal challenge rotation.
- Long term: evaluate controller support, additional languages, and PC/console ports depending on traction.
- Live ops cadence: monthly anomaly events, quarterly expansion packs tied to new threat factions.

## Outstanding Questions
- Confirm pricing and monetization messaging for store listings; align with marketing assets timeline.
- Determine whether to add optional cloud save integration for launch or defer to live ops phase.
- Validate legal review for storing hashed device IDs and telemetry retention policy.
