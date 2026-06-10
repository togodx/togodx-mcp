# togodx-mcp

An [MCP](https://modelcontextprotocol.io/) server that connects AI agents to [TogoDX/Human](https://togodx.dbcls.jp/human/), a platform for exploring integrated life-science data by attributes.

Agents can build filter conditions from natural language, export uploadable preset JSON for the TogoDX UI, map user ID lists, and fetch result tables — enabling **explainable, verifiable AI-assisted data exploration**.

## Features

- **Attribute discovery** — Search and browse 65 TogoDX/Human attributes across 8 categories (Gene, Protein, Structure, Interaction, Compound, Glycan, Disease, Variant).
- **Node resolution** — Ground filter values in live `/breakdown` and `/suggest` API responses; never guess node IDs.
- **Preset JSON builder** — Produce the exact JSON format accepted by TogoDX's Conditions upload feature.
- **ID conversion** — Convert external identifiers to TogoDX-compatible datasets via the [TogoID](https://togoid.dbcls.jp/) API.
- **Result preview** — Check match counts with `/aggregate` and fetch tables with `/dataframe`.
- **Explainable workflow** — Export JSON with `export_preset` so researchers can verify conditions in the TogoDX web UI.

## Requirements

- Ruby **3.1 or later**
- Network access to `togodx.dbcls.jp` and `api.togoid.dbcls.jp`

## Installation

```bash
git clone https://github.com/ktym/togodx-mcp-ruby.git
cd togodx-mcp-ruby
bundle config set --local path vendor/bundle
bundle install
```

## Cursor Setup

Add to your Cursor MCP settings (`.cursor/mcp.json` or global settings).
Replace `/path/to/togodx-mcp-ruby` with your clone directory.

```json
{
  "mcpServers": {
    "togodx": {
      "command": "bundle",
      "args": ["exec", "ruby", "exe/togodx-mcp"],
      "cwd": "/path/to/togodx-mcp-ruby"
    }
  }
}
```

Ruby 3.1+ is required. If `bundle` is not on your PATH, use the full path to a Ruby 3.1+ `bundle` executable.

## MCP Tools

Call **`togodx_usage_guide`** first in every conversation.

| Tool | Description |
|------|-------------|
| `togodx_usage_guide` | Workflow guide for agents |
| `list_categories` | List attribute categories |
| `get_attribute` | Metadata for one attribute |
| `search_attributes` | Keyword search over attributes |
| `breakdown` | List nodes in an attribute hierarchy |
| `suggest_nodes` | Keyword search for classification nodes |
| `resolve_nodes` | Map natural-language terms to node IDs |
| `convert_ids` | Convert IDs via TogoID |
| `locate_ids` | Map user IDs to breakdown nodes |
| `preview_aggregate` | Preview matching entry count |
| `build_preset` | Build uploadable preset JSON |
| `get_dataframe` | Fetch result table |
| `export_preset` | Write JSON file and return upload instructions |

## Typical Workflow

A user asks:

> *"Show human proteins highly expressed in lung and intestine, localized to the plasma membrane, with ChEMBL interaction assay data, related to anti-infective drugs — including structure and drug phase annotations."*

The agent should:

1. Call `togodx_usage_guide`.
2. Use `search_attributes` to propose expression, localization, and interaction attributes; confirm with the user.
3. Resolve tissue names (`Lung`, `Intestine`) and GO terms (`GO_0005886`) via `resolve_nodes` or `suggest_nodes`.
4. Put narrowing criteria in **filters**; put display-only attributes in **annotations**.
5. Call `build_preset` → `preview_aggregate` → `get_dataframe`.
6. Call `export_preset` and instruct the user to upload the JSON in [TogoDX/Human](https://togodx.dbcls.jp/human/).

See `doc/togodx-preset_example_case1.json` for a reference preset.

### filters vs annotations

| Type | Role | Example |
|------|------|---------|
| **filters** | Narrow the result set | tissue expression, plasma membrane, assay existence |
| **annotations** | Add Projection columns | structure existence, drug development phase |

## Environment Variables

| Variable | Default |
|----------|---------|
| `TOGODX_BASE_URL` | `https://togodx.dbcls.jp/human` |
| `TOGODX_CONFIG_URL` | GitHub URL for `attributes.dx-server.json` |
| `TOGOID_BASE_URL` | `https://api.togoid.dbcls.jp` |
| `TOGODX_UI_URL` | `https://togodx.dbcls.jp/human` |

## Development

See [doc/Development.md](doc/Development.md) for architecture, API mapping, and contribution notes.

```bash
rake smoke   # live API smoke test
rake test    # MCP protocol test
```

## License

MIT

## Related

- [TogoDX/Human](https://togodx.dbcls.jp/human/)
- [togodx-server](https://github.com/togodx/togodx-server)
- [Instructions](doc/Instructions.md) — original project requirements
