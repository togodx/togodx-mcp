# togodx-mcp

[TogoDX/Human](https://togodx.dbcls.jp/human/)（統合生命科学データの属性ベース探索プラットフォーム）を [MCP](https://modelcontextprotocol.io/) 経由で AI エージェントから利用するためのサーバです。

自然言語からフィルタ条件を構築し、TogoDX UI にアップロード可能なプリセット JSON を出力したり、ユーザの ID リストを適用したり、結果テーブルを取得したりできます。**Explainable AI** — AI が推論した条件を TogoDX UI 上で人間が検証できる — ことを目的としています。

## 機能

- **属性の探索** — 8 カテゴリ・65 属性の検索・参照
- **ノード解決** — `/breakdown` と `/suggest` のライブ API に基づくフィルタ値の確定（ノード ID の推測は禁止）
- **プリセット JSON 生成** — TogoDX の Conditions JSON アップロード機能が受け付ける形式での出力
- **ID 変換** — [TogoID](https://togoid.dbcls.jp/) API による外部識別子の変換
- **結果プレビュー** — `/aggregate` による件数確認、`/dataframe` によるテーブル取得
- **検証可能なワークフロー** — `export_preset` で JSON を出力し、研究者が Web UI で条件を確認

## 必要条件

- Ruby **3.1 以上**
- `togodx.dbcls.jp` および `api.togoid.dbcls.jp` へのネットワークアクセス

## インストール

```bash
git clone https://github.com/ktym/togodx-mcp-ruby.git
cd togodx-mcp-ruby
bundle config set --local path vendor/bundle
bundle install
```

## MCP クライアントへの登録（Cursor / Claude Desktop など）

各クライアントの MCP 設定（Cursor なら `.cursor/mcp.json`、Claude Desktop なら
`claude_desktop_config.json` など）に追加します。**すべての値を絶対パスで書いてください。**
GUI 系の MCP クライアントはシェルの `PATH`・rbenv/rvm の shim・カレントディレクトリを
引き継がないため、相対パスや `bundle` だけの指定では失敗します。

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

各パスの調べ方:

- **`command`** — Ruby 3.1 以上の `bundle` の絶対パス。
  rbenv なら `rbenv which bundle`（例: `~/.rbenv/versions/3.4.5/bin/bundle`）、
  それ以外は `which bundle` で取得します。
- **`args`** — クローン先の `exe/togodx-mcp` の絶対パス。
- **`env.BUNDLE_GEMFILE`** — クローン先の `Gemfile` の絶対パス。
  `cwd` を尊重しないクライアント（特に Claude Desktop）でも Bundler が gem を
  見つけられるようにするための指定で、`cwd` の代わりになります。

> クライアントが `cwd` を尊重し、かつ `bundle` が `PATH` にある場合は、短い形
> （`"command": "bundle"` ＋ `"cwd": "/path/to/togodx-mcp-ruby"`）でも動きますが、
> どの環境でも確実に動くのは上の絶対パス形式です。

> **ChatGPT は非対応です。** 本サーバはローカルの stdio トランスポート
> （`command`/`args` でプロセス起動する方式）で動作しますが、ChatGPT のコネクタは
> URL で登録するリモート HTTP（SSE / Streamable HTTP）MCP サーバを前提とします。
> Cursor や Claude Desktop など、ローカル stdio の MCP サーバを起動できるクライアントを
> ご利用ください。

## MCP ツール一覧

会話の最初に **`togodx_usage_guide`** を呼び出してください。

| ツール | 説明 |
|--------|------|
| `togodx_usage_guide` | エージェント向けワークフローガイド |
| `list_categories` | 属性カテゴリ一覧 |
| `get_attribute` | 単一属性のメタデータ |
| `search_attributes` | キーワードによる属性検索 |
| `breakdown` | 属性階層のノード一覧 |
| `suggest_nodes` | 分類属性のキーワード検索 |
| `resolve_nodes` | 自然言語 → ノード ID |
| `convert_ids` | TogoID による ID 変換 |
| `locate_ids` | ユーザ ID のノードマッピング |
| `preview_aggregate` | マッチ件数のプレビュー |
| `build_preset` | アップロード用プリセット JSON の生成 |
| `get_dataframe` | 結果テーブルの取得 |
| `export_preset` | JSON ファイル出力とアップロード手順 |
| `build_share_link` | プリセットを反映した TogoDX/Human の共有 URL を生成 |
| `run_preset` | プリセットを end-to-end 実行（aggregate → dataframe）し最終結果テーブルを取得 |

## 典型的なワークフロー

ユーザが次のように依頼した場合:

> 「肺および腸で組織特異的に高い遺伝子発現が確認され、細胞膜表面に局在し、ChEMBL の相互作用アッセイデータが存在し、感染症向け薬効化合物に関わるヒトタンパク質の一覧（立体構造・薬剤フェーズも表示）」

エージェントは次の手順で進めます。

1. `togodx_usage_guide` を呼ぶ
2. `search_attributes` で発現・局在・相互作用の候補属性を提示し、ユーザに確認する
3. `resolve_nodes` や `suggest_nodes` で組織名（`Lung`, `Intestine`）や GO term（`GO_0005886`）を解決する
4. 絞り込み条件は **filters**、表示のみの属性は **annotations** に入れる
5. `build_preset` → `preview_aggregate` → `get_dataframe` の順で実行する
6. `export_preset` で JSON を出力し、[TogoDX/Human](https://togodx.dbcls.jp/human/) の Conditions JSON アップロード機能で確認してもらう

参考プリセット: `doc/togodx-preset_example_case1.json`

### filters と annotations

| 種別 | 役割 | 例 |
|------|------|-----|
| **filters** | 結果集合を絞り込む | 組織特異的発現、細胞膜局在、アッセイデータの存在 |
| **annotations** | Projection 列として表示 | 立体構造の有無、薬剤開発フェーズ |

## 環境変数

| 変数 | デフォルト |
|------|-----------|
| `TOGODX_BASE_URL` | `https://togodx.dbcls.jp/human` |
| `TOGODX_CONFIG_URL` | `attributes.json` の URL |
| `TOGOID_BASE_URL` | `https://api.togoid.dbcls.jp` |
| `TOGODX_UI_URL` | `https://togodx.dbcls.jp/human` |

## 開発

アーキテクチャや API マッピングは [doc/Development.ja.md](doc/Development.ja.md) を参照してください。

```bash
rake smoke   # ライブ API の smoke テスト
rake test    # MCP プロトコルテスト
```

## ライセンス

MIT

## 関連リンク

- [TogoDX/Human](https://togodx.dbcls.jp/human/)
- [togodx-server](https://github.com/togodx/togodx-server)
- [Instructions](doc/Instructions.md) — プロジェクト要件
