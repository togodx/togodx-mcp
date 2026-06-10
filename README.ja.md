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
git clone <リポジトリURL>
cd togodx-mcp-cursor
bundle config set --local path vendor/bundle
bundle install
```

## Cursor への登録

Cursor の MCP 設定（`.cursor/mcp.json` またはグローバル設定）に追加します。

```json
{
  "mcpServers": {
    "togodx": {
      "command": "ruby",
      "args": ["/absolute/path/to/togodx-mcp-cursor/exe/togodx-mcp"]
    }
  }
}
```

PATH 上の `ruby` が 2.x の場合は、Ruby 3.1 以上の実行ファイルへの絶対パスを指定してください。

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
| `TOGODX_CONFIG_URL` | `attributes.dx-server.json` の GitHub URL |
| `TOGOID_BASE_URL` | `https://api.togoid.dbcls.jp` |
| `TOGODX_UI_URL` | `https://togodx.dbcls.jp/human` |

## 開発

アーキテクチャや API マッピングは [doc/DEVELOPMENT.ja.md](doc/DEVELOPMENT.ja.md) を参照してください。

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
