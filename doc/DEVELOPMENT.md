# Development Guide

This document describes the architecture and implementation of **togodx-mcp**, an MCP server that lets AI agents build TogoDX/Human filter conditions and fetch results through the public REST APIs.

## Goals

The server supports two main workflows described in `doc/Instructions.md`:

1. **Conditions JSON** — Translate a user's natural-language query into a TogoDX preset JSON file that can be uploaded via the web UI.
2. **Map your IDs** — Apply a user-provided ID list (`queries`) and optionally map IDs to breakdown nodes via `/locate`.

The design prioritizes **explainable AI**: every condition is grounded in live API responses and can be verified in the TogoDX UI.

## Technology Stack

| Component | Choice |
|-----------|--------|
| Language | Ruby >= 3.1 |
| MCP framework | [`mcp`](https://github.com/modelcontextprotocol/ruby-sdk) gem (~> 0.18) |
| Transport | stdio (`MCP::Server::Transports::StdioTransport`) |
| HTTP | stdlib `Net::HTTP` (no Faraday dependency) |
| Attribute metadata | `attributes.dx-server.json` from [togodx-config-human](https://github.com/togodx/togodx-config-human) |

## Project Layout

```
togodx-mcp-cursor/
├── exe/togodx-mcp              # Entry point (stdio server)
├── lib/togodx_mcp/
│   ├── config.rb               # Environment variable defaults
│   ├── http_client.rb          # Shared JSON HTTP client
│   ├── catalog.rb              # Attribute catalog loader and search
│   ├── preset_builder.rb       # Preset JSON assembly and validation
│   ├── node_resolver.rb        # Natural-language term → node ID resolution
│   ├── tool_helpers.rb         # JSON/text MCP responses
│   ├── client/
│   │   ├── togodx.rb           # TogoDX REST API wrapper
│   │   └── togoid.rb           # TogoID /convert wrapper
│   ├── tools/                  # MCP::Tool subclasses
│   │   ├── guide.rb
│   │   ├── catalog_tools.rb
│   │   ├── node_tools.rb
│   │   ├── id_tools.rb
│   │   ├── condition_tools.rb
│   │   └── registry.rb
│   └── server.rb               # MCP::Server bootstrap
├── doc/                        # Project documentation
├── Gemfile
├── togodx-mcp.gemspec
└── Rakefile                    # smoke / MCP protocol tests
```

## Architecture

```
AI Agent (Cursor, etc.)
        │  MCP (stdio / JSON-RPC)
        ▼
┌───────────────────────────────────────┐
│  TogodxMcp::Server                    │
│  server_context:                      │
│    catalog, togodx client, togoid client│
└───────────────────────────────────────┘
        │
        ├── Catalog ──► attributes.dx-server.json (GitHub)
        ├── Client::Togodx ──► TogoDX API (togodx.dbcls.jp/human)
        └── Client::Togoid ──► TogoID API (api.togoid.dbcls.jp)
```

At startup, `Catalog.load` fetches the attribute configuration once and builds an in-memory index used by all tools.

## External APIs

### TogoDX API

Base URL: `https://togodx.dbcls.jp/human` (override with `TOGODX_BASE_URL`)

| Endpoint | MCP tools | Purpose |
|----------|-----------|---------|
| `GET /breakdown/{attribute}` | `breakdown`, `resolve_nodes` | List hierarchy nodes |
| `GET /suggest/{attribute}?term=` | `suggest_nodes`, `resolve_nodes` | Keyword search (term ≥ 3 chars) |
| `POST /locate/{attribute}` | `locate_ids` | Map user IDs to nodes |
| `POST /aggregate` | `preview_aggregate` | Preview matching entry count |
| `POST /dataframe` | `get_dataframe` | Fetch result table |

See [togodx-server README](https://github.com/togodx/togodx-server) for request/response schemas.

### TogoID API

Base URL: `https://api.togoid.dbcls.jp` (override with `TOGOID_BASE_URL`)

| Endpoint | MCP tool | Purpose |
|----------|----------|---------|
| `GET /convert` | `convert_ids` | Convert IDs between databases |

## Preset JSON Format

`PresetBuilder` produces an array with a single entry:

```json
[
  {
    "condition": {
      "dataset": "uniprot",
      "filters": [
        { "attribute": "gene_specific_expression_in_tissues_hpa", "nodes": ["Lung", "Intestine"] }
      ],
      "annotations": [
        { "attribute": "structure_data_existence_uniprot" }
      ]
    },
    "attributeSet": ["gene_biotype_ensembl", "..."]
  }
]
```

Rules enforced by `PresetBuilder`:

- `filters` — at least one; each attribute must exist in the catalog.
- `annotations` — optional; used for Projection columns, not narrowing.
- `queries` — included only when a non-empty user ID list is provided.
- `attributeSet` — always the full list of attribute IDs from the catalog (currently fixed).

Reference example: `doc/togodx-preset_example_case1.json`

## MCP Tools

Tools are registered in `TogodxMcp::Tools::Registry.all`. Each tool subclasses `MCP::Tool` and receives `server_context` with `:catalog`, `:togodx`, and `:togoid`.

| Layer | Tools |
|-------|-------|
| Guide | `togodx_usage_guide` |
| Catalog | `list_categories`, `get_attribute`, `search_attributes` |
| Node resolution | `breakdown`, `suggest_nodes`, `resolve_nodes` |
| ID mapping | `convert_ids`, `locate_ids` |
| Conditions | `preview_aggregate`, `build_preset`, `get_dataframe`, `export_preset` |

### filters vs annotations

- **filters** — AND across filters; OR within `nodes`. Narrows the result set.
- **annotations** — attributes shown in Projection without narrowing.

Agents should call `togodx_usage_guide` first and never invent node IDs without API grounding.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TOGODX_BASE_URL` | `https://togodx.dbcls.jp/human` | TogoDX API base |
| `TOGODX_CONFIG_URL` | GitHub raw URL for `attributes.dx-server.json` | Attribute catalog source |
| `TOGOID_BASE_URL` | `https://api.togoid.dbcls.jp` | TogoID API base |
| `TOGODX_UI_URL` | `https://togodx.dbcls.jp/human` | Shown in `export_preset` instructions |

## Setup

```bash
# Ruby 3.1+ required
bundle config set --local path vendor/bundle
bundle install
```

## Running Locally

```bash
# Start stdio server (used by Cursor)
ruby exe/togodx-mcp

# Smoke test (live API)
bundle exec ruby -e "require_relative 'lib/togodx_mcp'; puts TogodxMcp::Catalog.load.all_attribute_ids.length"

# MCP protocol test (requires rake)
rake test
rake smoke
```

### Manual MCP probe

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
| bundle exec ruby exe/togodx-mcp
```

## Adding a New Tool

1. Create a class under `lib/togodx_mcp/tools/` inheriting from `MCP::Tool`.
2. Set `tool_name`, `description`, and `input_schema`.
3. Implement `self.call(..., server_context:)` returning `MCP::Tool::Response`.
4. Register the class in `Tools::Registry.all`.
5. Update `Rakefile` expected tool list if using `rake test`.

Note: the `mcp` gem rejects `required: []` in input schemas — omit `required` when there are no required fields.

## Known Limitations

- **UI auto-upload** — not implemented; use `export_preset` and manual JSON upload in TogoDX.
- **`/locate`** — may return 404 on the public Human instance depending on deployment.
- **Ruby version** — macOS system Ruby (2.6) is unsupported; use Ruby 3.1+ (rbenv, mise, or Homebrew).

## Related Projects

- [TogoDX](https://togodx.dbcls.jp/human/) — web application
- [togodx-server](https://github.com/togodx/togodx-server) — backend API
- [togodx-config-human](https://github.com/togodx/togodx-config-human) — attribute configuration
- [TogoMCP](https://github.com/dbcls/togomcp) — complementary MCP for SPARQL / knowledge-graph exploration
