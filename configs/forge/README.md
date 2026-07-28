# Forge registry

`~/Projects` keeps its physical name. “Forge” is only the internal territory
name.

The production state lives in `~/Projects/.forge/`:

- `projects.generated.json` is scanner-owned and may be replaced at any time;
- `aliases.yaml` is human-owned and is initialized only when absent;
- `territories.yaml` is the small stable territory contract.

The `.yaml` files use JSON syntax deliberately. JSON is a valid YAML subset and
keeps the resolver dependency-free on the macOS system Python.

Commands:

```bash
python3 ~/Projects/ehrax.dev/Dotfiles/scripts/forge.py scan
python3 ~/Projects/ehrax.dev/Dotfiles/scripts/forge.py resolve "bikepark api"
python3 ~/Projects/ehrax.dev/Dotfiles/scripts/forge.py doctor
```

A `resolved` result is safe to use. `ambiguous`, `not_found`, and
`invalid_registry` require clarification; never guess a project path.
