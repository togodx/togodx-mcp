# 開発ガイド

本ドキュメントは、AI エージェントが TogoDX/Human のフィルタ条件を構築し、公開 REST API 経由で結果を取得するための MCP サーバ **togodx-mcp** のアーキテクチャと実装について説明します。

## 目的

`doc/Instructions.md` に記載された 2 つのワークフローを支援します。

1. **Conditions JSON** — ユーザの自然言語クエリを、TogoDX Web UI にアップロード可能なプリセット JSON に変換する。
2. **Map your IDs** — ユーザが持つ ID リストを `queries` に適用し、必要に応じて `/locate` で breakdown ノードへマッピングする。

設計の核心は **Explainable AI** です。すべての条件はライブ API レスポンスに基づき、TogoDX UI 上で人間が検証できます。

## 技術スタック

| 項目 | 選定 |
|------|------|
| 言語 | Ruby >= 3.1 |
| MCP フレームワーク | [`mcp`](https://github.com/modelcontextprotocol/ruby-sdk) gem (~> 0.18) |
| トランスポート | stdio (`MCP::Server::Transports::StdioTransport`) |
| HTTP | 標準ライブラリ `Net::HTTP`（Faraday 非依存） |
| 属性メタデータ | [togodx-config-human](https://github.com/togodx/togodx-config-human) の `attributes.dx-server.json` |

## プロジェクト構成

```
togodx-mcp-ruby/
├── exe/togodx-mcp              # エントリポイント（stdio サーバ）
├── lib/togodx_mcp/
│   ├── config.rb               # 環境変数のデフォルト値
│   ├── http_client.rb          # 共通 JSON HTTP クライアント
│   ├── catalog.rb              # 属性カタログのロード・検索
│   ├── preset_builder.rb       # プリセット JSON の組み立て・検証
│   ├── node_resolver.rb        # 自然言語 → ノード ID 解決
│   ├── tool_helpers.rb         # MCP レスポンスヘルパー
│   ├── client/
│   │   ├── togodx.rb           # TogoDX REST API ラッパー
│   │   └── togoid.rb           # TogoID /convert ラッパー
│   ├── tools/                  # MCP::Tool サブクラス群
│   └── server.rb               # MCP::Server 起動処理
├── doc/                        # プロジェクトドキュメント
├── Gemfile
├── togodx-mcp.gemspec
└── Rakefile                    # smoke / MCP プロトコルテスト
```

## アーキテクチャ

```
AI エージェント（Cursor 等）
        │  MCP（stdio / JSON-RPC）
        ▼
┌───────────────────────────────────────┐
│  TogodxMcp::Server                    │
│  server_context:                      │
│    catalog, togodx client, togoid client│
└───────────────────────────────────────┘
        │
        ├── Catalog ──► attributes.dx-server.json（GitHub）
        ├── Client::Togodx ──► TogoDX API（togodx.dbcls.jp/human）
        └── Client::Togoid ──► TogoID API（api.togoid.dbcls.jp）
```

起動時に `Catalog.load` が属性設定を一度取得し、全ツールが参照するインメモリ索引を構築します。

## 外部 API

### TogoDX API

ベース URL: `https://togodx.dbcls.jp/human`（`TOGODX_BASE_URL` で上書き可）

| エンドポイント | MCP ツール | 用途 |
|----------------|------------|------|
| `GET /breakdown/{attribute}` | `breakdown`, `resolve_nodes` | 階層ノード一覧 |
| `GET /suggest/{attribute}?term=` | `suggest_nodes`, `resolve_nodes` | キーワード検索（3 文字以上） |
| `POST /locate/{attribute}` | `locate_ids` | ユーザ ID のノードマッピング |
| `POST /aggregate` | `preview_aggregate` | マッチ件数のプレビュー |
| `POST /dataframe` | `get_dataframe` | 結果テーブル取得 |

リクエスト／レスポンスの詳細は [togodx-server README](https://github.com/togodx/togodx-server) を参照してください。

### TogoID API

ベース URL: `https://api.togoid.dbcls.jp`（`TOGOID_BASE_URL` で上書き可）

| エンドポイント | MCP ツール | 用途 |
|----------------|------------|------|
| `GET /convert` | `convert_ids` | データベース間の ID 変換 |

## プリセット JSON 形式

`PresetBuilder` は単一エントリの配列を生成します。

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

`PresetBuilder` が適用するルール:

- `filters` — 1 つ以上必須。各属性はカタログに存在すること。
- `annotations` — 任意。Projection 列の指定用（絞り込みには使わない）。
- `queries` — ユーザ ID リストがある場合のみ含める。
- `attributeSet` — カタログの全属性 ID を固定で含める（現時点）。

参考例: `doc/togodx-preset_example_case1.json`

## MCP ツール

ツールは `TogodxMcp::Tools::Registry.all` に登録されます。各ツールは `MCP::Tool` を継承し、`server_context` から `:catalog`、`:togodx`、`:togoid` を受け取ります。

| レイヤ | ツール |
|--------|--------|
| ガイド | `togodx_usage_guide` |
| カタログ | `list_categories`, `get_attribute`, `search_attributes` |
| ノード解決 | `breakdown`, `suggest_nodes`, `resolve_nodes` |
| ID マッピング | `convert_ids`, `locate_ids` |
| 条件構築 | `preview_aggregate`, `build_preset`, `get_dataframe`, `export_preset` |

### filters と annotations の区別

- **filters** — フィルタ間は AND、`nodes` 内は OR。結果集合を絞り込む。
- **annotations** — Projection に表示する属性。絞り込みには使わない。

エージェントは毎ターン最初に `togodx_usage_guide` を呼び、API レスポンスなしにノード ID を捏造しないこと。

## 環境変数

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `TOGODX_BASE_URL` | `https://togodx.dbcls.jp/human` | TogoDX API ベース URL |
| `TOGODX_CONFIG_URL` | GitHub raw URL | 属性カタログの取得元 |
| `TOGOID_BASE_URL` | `https://api.togoid.dbcls.jp` | TogoID API ベース URL |
| `TOGODX_UI_URL` | `https://togodx.dbcls.jp/human` | `export_preset` の案内文に使用 |

## セットアップ

```bash
# Ruby 3.1 以上が必要
bundle config set --local path vendor/bundle
bundle install
```

## ローカル実行

```bash
# stdio サーバ起動（Cursor 連携用）
ruby exe/togodx-mcp

# smoke テスト（ライブ API）
bundle exec ruby -e "require_relative 'lib/togodx_mcp'; puts TogodxMcp::Catalog.load.all_attribute_ids.length"

# MCP プロトコルテスト（rake 必要）
rake test
rake smoke
```

### 手動 MCP プローブ

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
| bundle exec ruby exe/togodx-mcp
```

## 新しいツールの追加手順

1. `lib/togodx_mcp/tools/` に `MCP::Tool` を継承したクラスを作成する。
2. `tool_name`、`description`、`input_schema` を定義する。
3. `self.call(..., server_context:)` を実装し、`MCP::Tool::Response` を返す。
4. `Tools::Registry.all` にクラスを登録する。
5. `rake test` を使う場合は `Rakefile` の期待ツール一覧を更新する。

注意: `mcp` gem は `required: []` を拒否するため、必須パラメータがない場合は `required` キー自体を省略すること。

## 既知の制限

- **UI 自動アップロード** — 未実装。`export_preset` で JSON を出力し、TogoDX UI から手動アップロードする。
- **`/locate`** — 公開 Human インスタンスでは 404 になる場合がある。
- **Ruby バージョン** — macOS 標準の Ruby 2.6 は非対応。Ruby 3.1 以上（rbenv、mise、Homebrew 等）を使用すること。

## 関連プロジェクト

- [TogoDX](https://togodx.dbcls.jp/human/) — Web アプリケーション
- [togodx-server](https://github.com/togodx/togodx-server) — バックエンド API
- [togodx-config-human](https://github.com/togodx/togodx-config-human) — 属性設定
- [TogoMCP](https://github.com/dbcls/togomcp) — SPARQL / 知識グラフ探索用の補完 MCP
