# Instructions

2026-06-08

## Introduction

TogoDXとは [https://togodx.dbcls.jp/human/](https://togodx.dbcls.jp/human/) で私たちが公開しているデータ統合と探索的データ解析のためのプラットフォームで、概要は下記：

生命科学分野では、遺伝子、タンパク質、疾患、化合物、バリアントなど多様なデータを対象とした膨大な数のデータベースが構築されており、それらを活用したデータ駆動型研究が広く行われている。一方で、これらのデータベースはそれぞれ独立に開発されてきた背景から、データ形式、識別子体系、語彙、アクセス方法が異なっており、複数データベースを横断して利用することは依然として研究者に大きな負担を強いている。近年、RDFや知識グラフ、FAIR原則に基づくデータ統合基盤の整備により、異種生命科学データの相互運用性は向上しつつあるが、それらを研究者が直感的に探索し、俯瞰し、新たな知識発見へとつなげるためのインターフェースは十分に整備されていない。
我々はこの課題を解決するため、統合生命科学データを属性ベースで探索・俯瞰・抽出するウェブアプリケーションフレームワーク TogoDX (Togo Data eXplorer) を開発した。本フレームワークは、統合知識グラフ上に存在する多様な生命科学データを、データセット間の識別子変換を透過的に行いながら、統一的なインターフェースで探索可能にする。ショーケース実装としてヒト関連データを対象とした TogoDX/Human を構築し、8カテゴリ、20データベース、64種類の属性情報を統合した。
TogoDX/Human では、属性による絞り込み検索、属性マッピング、ユーザー所有IDリストの統合的解析という3つの探索様式を提供し、従来は複数の専門データベースを横断しなければ実現困難であった複雑なデータ探索を単一のアプリケーション上で可能にした。本研究は、統合知識グラフを研究者の知識発見へと接続する新たな探索インターフェースの実装事例を示すものである。

## Mission

ここでは、TogoDXをAIエージェントから利用できるMCPサーバを構築します。

1. ユーザの自然言語クエリからTogoDXのフィルタリング条件を指定するJSONを生成し、ConditionsのJSONアップロード機能を用いて条件を適用する

2. もしあれば、ユーザが持っているIDのリストをMap your IDsに適用する

この２つの機能で画面を更新し、AIが検討した条件をTogoDXのUIで表示し、検証可能なExplainableなAI利用という位置づけで論文化したいと考えています。

## Specification

TogoDX では裏でAPIが動いています。これらは [togodx/togodx-server](https://github.com/togodx/togodx-server) にあるAPIで実装されています。

1. Conditions指定用
* /aggregate は属性ごとに指定された中間ノードのリストから、リーフノードにあるデータベースIDの積集合を取得

2. Map your IDs指定用
* /locate/属性 は属性ごとに該当する中間ノードを取得

その他、入力と出力に関係するAPI
* /dataframe 1と2いずれかの条件から他の属性における結果の対応表を取得
* /suggest/属性 は属性ごとに中間ノードを確定するためのキーワード検索を提供（曖昧検索用でMCPからインタラクティブに呼び出すことを期待）
* /breakdown/属性 は属性ごとに内訳を取得（表示用でウェブUIが自動的に呼び出して可視化）

API自体は https://togodx.dbcls.jp/human/breakdown/属性 のようにURLプレフィックスをつければ呼び出すことができます。

TogoDX/Humanが利用できる「属性」はGene, Protein, Structure, Interaction, Compound, Glycan, Disease, Variantのカテゴリごとに複数準備されています。各属性はclassificationの場合は木構造のデータ、distributionの場合はbinごとに分けられたデータ集合で、木構造の中間ノードやbinのラベルを要素とし、リーフノードがDBのエントリのIDです。

https://github.com/togodx/togodx-config-human/blob/develop/config/attributes.dx-server.json

この JSON ファイルの "categories" にカテゴリの一覧と対応する属性のリストがあります。またこのファイルの "attributes" に属性ごとに、ラベル名label, 説明description, 呼び出す /brakedown/属性 のapi、その属性が対象とするデータベースのID (ensembl_geneなど)を示すdataset、属性の内訳がカテゴリカルclassificationか数値分布distributionかを示すdatamodel, データソースの概要 sourceが記載されています。

TogoDXの対象としているDBはEnsembl gene ID, Ensembl transcript ID, NCBI gene ID, UniProt ID, PDB ID, ChEBI compound ID, ChEMBL compound ID, PubChem compound ID, GlyTouCan ID, MONDO ID, MeSH ID, NANDO ID, Human Phenotype Ontology IDで、TogoDXのAPIが受容するDB名の識別子は"dataset"に書かれているものになります。

このため、ユーザの持っているIDがこれらのDBのものではない場合、どれに変換するかユーザの指示を聞いて、TogoIDのAPI https://togoid.dbcls.jp/apidoc/ にある /convert 機能を用いて変換する機能を持たせます。

これらの情報をもとに、TogoDXにアップロードできる下記の構造のJSONを生成するMCPサーバを設計・開発してください。

* "condition":　配列になっているのはヒストリに含まれる条件の異なる履歴を同じ形式で記載するためで、本MCPでは１つだけ作れば良い
    * "dataset": （必須）ユーザが選択する主として注目する ensembl_gene などデータベースの識別子を記載
    * "filters": （１つ以上必須）属性名と、その中で選択した中間ノードのIDリスト
      * 中間ノードのリストはbreakdown APIから取得できる
        * まず /breakdown/属性名 でトップダウンの中間ノードのリストが返ってくる
        * 次に /breakdown/属性名?node=中間ノードID でその階層以下の中間ノードのリストが返ってくる
    * "annotations": （オプショナル）ウェブUIのProjectionで指定する属性名のリストと、ユーザに問い合わせて指定があれば中間ノードのID
    * "queries": （オプショナル）もしあれば、ユーザが指定した dataset の ID リスト、なければ "queries" 自体をJSONに含めない
    * "attributeSet": （必須）表示する属性のリストをコントロールするものだが、いったん常に固定で attributes.dx-server.json にある全てのリストを含める

```
[
  {
    "condition": {
      "dataset": "ensembl_gene",
      "filters": [
        {
          "attribute": "structure_data_existence_uniprot",
          "nodes": [
            "1"
          ]
        },
        {
          "attribute": "protein_biological_process_uniprot",
          "nodes": [
            "GO_0008152"
          ]
        },
        {
          "attribute": "disease_diseases_mesh",
          "nodes": [
            "C18.452.394.750"
          ]
        },
        {
          "attribute": "protein_number_of_phosphorylation_sites_uniprot",
          "nodes": [
            "1",
            "2"
          ]
        }
      ],
      "annotations": [
        {
          "attribute": "variant_clinical_significance_togovar"
        },
        {
          "attribute": "compound_drug_indication_mesh_chembl",
          "node": "C18"
        }
      ],
      "queries": [
        "ENSG00000148584",
        "ENSG00000164398",
        "ENSG00000127914",
        ：
        "ENSG00000183579"
      ]
    },
    "attributeSet": [
      "gene_biotype_ensembl",
      "gene_chromosome_ensembl",
      "gene_number_of_paralogs_homologene",
      "gene_ortholog_existence_homologene",
:
      "variant_clinical_significance_togovar"
    ]
  }
]
```

## Implementation

ユーザがAIエージェントに、例として「肺および腸で組織特異的に高い遺伝子発現が確認され、タンパク質として細胞膜表面に局在し、また何らかのタンパク質と化合物の直接の相互作用を検出する方法のデータが存在し、さらに「感染」に対する薬効がある化合物に関わる、ヒトのタンパク質の一覧と立体構造や既存の薬剤の有無」を取得するように依頼した場合、MCPサーバは

* 高い遺伝子発現を見るにふさわしい属性として gene_high_level_expression_refex, gene_specific_expression_in_tissues_hpa などを候補として示して、ユーザに選択させます
* 指定された属性のbreakdownを取得し、ユーザの指定した肺や腸に該当する中間ノードを推定して指定します
* 次に細胞膜表面に局在という条件から protein_cellular_component_uniprot などを選び、細胞膜に該当する中間ノードを調べます
  * ここは /suggest APIを使うとよいでしょう
* さらに相互作用検出にふさわしいAPIとしてinteraction_chembl_assay_existence_uniprotなどを候補とします
* ターゲットとなるタンパク質の立体構造があるかどうかなどを比較検討するために structure_data_existence_uniprot のような属性を "annotation" に含めます。

この条件にあうJSONは下記のものになります。

https://raw.githubusercontent.com/togodx/togodx-config-human/develop/docs/togodx-preset_example_case1.json

このようなやり取りを実現しJSONを出力するMCPサーバを設計・開発し、最終的に /dataframe APIから結果の表を取得する機能をつけてください。できれば自動でTogoDXのUIにアップロードして画面に反映されるとよいです。

