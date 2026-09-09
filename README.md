# togodx-mcp

An [MCP](https://modelcontextprotocol.io/) server that connects AI agents to [TogoDX/Human](https://togodx.dbcls.jp/human/), a platform for exploring integrated life-science data by attributes.

Agents can build filter conditions from natural language, export uploadable preset JSON for the TogoDX UI, map user ID lists, and fetch result tables — enabling **explainable, verifiable AI-assisted data exploration**.

A public instance is hosted at **<https://togodx.dbcls.jp/human/mcp/>** — see [Public Server](#public-server) to connect without installing anything.

## Features

- **Attribute discovery** — Search and browse 65 TogoDX/Human attributes across 8 categories (Gene, Protein, Structure, Interaction, Compound, Glycan, Disease, Variant).
- **Node resolution** — Ground filter values in live `/breakdown` and `/suggest` API responses; never guess node IDs.
- **Preset JSON builder** — Produce the exact JSON format accepted by TogoDX's Conditions upload feature.
- **ID conversion** — Convert external identifiers to TogoDX-compatible datasets via the [TogoID](https://togoid.dbcls.jp/) API.
- **Result preview** — Check match counts with `/aggregate` and fetch tables with `/dataframe`.
- **Explainable workflow** — Export JSON with `export_preset` so researchers can verify conditions in the TogoDX web UI.

## Public Server

DBCLS hosts a public instance of this server, so you do not need to install
anything to use it:

```
https://togodx.dbcls.jp/human/mcp/
```

- **Transport:** Streamable HTTP (MCP). Register it by URL in any client that
  supports remote MCP servers — Claude Desktop / Claude Code custom connectors,
  ChatGPT custom connectors, Cursor, and so on.
- **Authentication:** none. No API key or token is required.
- Trailing slash optional; both `.../human/mcp` and `.../human/mcp/` work.

Claude Code:

```bash
claude mcp add --transport http togodx https://togodx.dbcls.jp/human/mcp/
```

Clients that take a URL in their JSON config (e.g. Cursor's `.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "togodx": {
      "url": "https://togodx.dbcls.jp/human/mcp/"
    }
  }
}
```

In Claude Desktop or ChatGPT, add it from the connector / MCP settings UI by
pasting the same URL.

> The public endpoint is a shared, best-effort service intended for interactive
> use. For heavy or production workloads, run your own instance — see
> [Installation](#installation) for the local stdio server and
> [Self-hosting the Remote (HTTP) Server](#self-hosting-the-remote-http-server).

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

## MCP Client Setup (Cursor / Claude Desktop / etc.)

Add the following to your client's MCP settings (e.g. Cursor's `.cursor/mcp.json`,
or Claude Desktop's `claude_desktop_config.json`). **Use absolute paths for every
value** — GUI MCP clients do not inherit your shell `PATH`, your rbenv/rvm shims,
or a working directory, so relative paths and a bare `bundle` command will fail.

```json
{
  "mcpServers": {
    "togodx": {
      "command": "/absolute/path/to/bundle",
      "args": ["exec", "ruby", "/absolute/path/to/togodx-mcp-ruby/exe/togodx-mcp"],
      "env": {
        "BUNDLE_GEMFILE": "/absolute/path/to/togodx-mcp-ruby/Gemfile"
      }
    }
  }
}
```

How to fill in the paths:

- **`command`** — the absolute path to `bundle` for a Ruby 3.1+ install.
  With rbenv, run `rbenv which bundle` (e.g. `~/.rbenv/versions/3.4.5/bin/bundle`);
  otherwise `which bundle`.
- **`args`** — the absolute path to `exe/togodx-mcp` in your clone.
- **`env.BUNDLE_GEMFILE`** — the absolute path to the `Gemfile` in your clone.
  This replaces `cwd`, which some clients (notably Claude Desktop) ignore, and is
  what lets Bundler find the gems regardless of the working directory.

> If your client honors `cwd` and `bundle` is on its `PATH`, a shorter form
> (`"command": "bundle"`, `"cwd": "/path/to/togodx-mcp-ruby"`) can work, but the
> absolute-path form above is the portable one that works everywhere.

> **This setup is for local stdio clients only.** It launches the server as a
> process via `command`/`args`, which ChatGPT connectors do not support — they
> expect a remote HTTP MCP server registered by URL. For ChatGPT, and for any
> other URL-registered client, use the [public server](#public-server) at
> `https://togodx.dbcls.jp/human/mcp/` instead.

## Self-hosting the Remote (HTTP) Server

The server also runs as a remote MCP over the Streamable HTTP transport, so
clients that register MCP servers by URL (e.g. Claude Desktop connectors,
ChatGPT custom connectors) can use it. This is how
<https://togodx.dbcls.jp/human/mcp/> is deployed; follow this section only if
you want to run your own instance.

```bash
bundle config set --local with http   # include the http group (rack + puma)
bundle install
export TOGODX_MCP_AUTH_TOKEN=your-secret-token
bundle exec puma -p 9292 config.ru
```

- The MCP endpoint is served at `/`; `GET /health` returns `200` for liveness checks.
- Clients send `Authorization: Bearer <token>` on every request. If
  `TOGODX_MCP_AUTH_TOKEN` is unset the endpoint is **unauthenticated** — only do
  that on a private/local network.
- Terminate TLS with a reverse proxy (nginx / Caddy / cloud load balancer) in front of Puma.
- The catalog is fetched once at boot and reused across requests.

HTTP-related environment variables:

| Variable | Default | Purpose |
|----------|---------|---------|
| `TOGODX_MCP_AUTH_TOKEN` | (unset) | Require this bearer token; unset means no auth |
| `TOGODX_MCP_STATELESS` | `false` | Stateless mode (no per-session SSE) for load-balanced/serverless deploys |
| `TOGODX_MCP_JSON_RESPONSE` | `false` | Reply with plain JSON instead of an SSE stream for clients that do not read SSE |

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
| `build_share_link` | Build a shareable TogoDX/Human URL that opens the UI with the preset applied |
| `run_preset` | Run a preset end-to-end (aggregate → dataframe) and return the final result table |

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
| `TOGODX_CONFIG_URL` | URL for `attributes.json` |
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
