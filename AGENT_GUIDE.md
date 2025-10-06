# Agent Reference Notes

## Hidden Agent Packs
- `.bmad-core/` — base BMAD agent set referenced by Codex CLI
- `.bmad-godot-game-dev/` — Godot game-development expansion pack containing all game-focused personas under `agents/`

## Discovering Game Agents
- List available definitions with `rg --hidden --files -g '*.md' .bmad-godot-game-dev/agents`
- Search for a specific agent ID with `rg --hidden '<agent-id>' .bmad-godot-game-dev`
- Each agent file includes activation instructions; many reference the shared config in `.bmad-godot-game-dev/config.yaml`

## Tips for Future Agents
- Only load dependency files when prompted by the active workflow
- Follow the activation sequence precisely: read the agent definition, load required configs, greet, run `*help`, then wait for direction
- Document newly discovered agent packs here so collaborators know where to look
