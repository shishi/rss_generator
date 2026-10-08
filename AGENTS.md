# リポジトリ概要

漫画サイトのエピソード一覧を Playwright で取得し、Ruby で作品別の RSS 2.0 フィードを生成します。
GitHub Actions が生成物を GitHub Pages に公開します。

## 構成

- `config/sites/*.yml`: ドメイン別の作品設定。各ファイルの `sites` 配列に作品を登録します。
- `bin/generate`: 実行入口。設定パスと出力先を引数で指定できます。既定値は `config/sites` と `output` です。
- `lib/rss_generator.rb`: 設定の読み込み、作品ごとの取得・生成、一覧ページの生成を担当します。
- `lib/scraper.rb`: CSS セレクターまたは `extraction_script` による JavaScript 評価でエピソードを抽出します。
- `lib/feed_builder.rb`: RSS を生成します。相対 URL を絶対 URL に変換し、掲載日を日本時間で解釈します。
- `lib/index_builder.rb`: ドメイン別のフィード一覧を生成します。
- `spec/`: RSpec のテスト。
- `docs/`: 設計文書。現在の挙動は実装・設定と照合してください。
- `output/`: 生成した `<id>.xml` と `index.html`。Git 管理対象外です。

## 開発・検証

リポジトリのルートで実行します。エージェントのシェルでは direnv を前提にせず、`nix develop -c` を使ってください。
`flake.nix` が Ruby の依存ライブラリー、Node.js、Chromium とブラウザー用の環境変数を用意します。
開発環境への初回起動時は、`node_modules` がなければ npm の依存パッケージもインストールします。

```bash
nix develop -c bundle exec rspec
nix develop -c xvfb-run ruby bin/generate
nix develop -c xvfb-run ruby bin/generate config/sites/yanmaga.yml output
```

## 作品の追加

対象ドメインの YAML に `name`、一意の `id`、作品ページの `url` と抽出設定を追加します。
同じサイトの既存設定を参考にし、実際のページでエピソードを取得できることを確認してください。
`id` はフィードのファイル名に使うため、既存作品の値は購読 URL に影響します。

ヤンマガの無料判定は `config/sites/yanmaga.yml` の説明に従います。
`data-is-free` は今すぐ無料で読める状態を表さないため、無料判定には使いません。

## 公開

実行条件とデプロイ手順は `.github/workflows/generate.yml` にあります。
いずれかの作品で取得結果が 0 件になると、生成処理は終了コード 1 を返します。
その場合、GitHub Actions はデプロイへ進まず、公開済みフィードを維持します。
