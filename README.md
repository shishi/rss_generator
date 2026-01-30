# RSS Generator

漫画サイトをスクレイピングして RSS フィードを生成するツール。

## 機能

- JavaScript レンダリングが必要なサイトに対応（Playwright 使用）
- YAML 設定ファイルでサイトを管理
- GitHub Actions で毎日自動実行
- GitHub Pages で RSS フィードをホスティング

## 必要環境

- Ruby 3.3+
- Node.js 22+
- Chromium（ローカル実行時）

## セットアップ

### Nix 環境（推奨）

```bash
# 開発環境に入る
nix develop

# 依存関係をインストール
bundle install
```

### 手動セットアップ

```bash
# Ruby 依存関係
bundle install

# Playwright ブラウザ
npx playwright install chromium
```

## 使い方

### ローカル実行

```bash
# Nix 環境では xvfb-run が必要（WSL2/headless 環境）
xvfb-run bundle exec ruby bin/generate

# GUI 環境がある場合
bundle exec ruby bin/generate

# カスタム設定ファイル
bin/generate path/to/config.yml

# カスタム出力先
bin/generate config/sites.yml output_dir
```

### ヘルプ

```bash
bin/generate --help
```

## 設定ファイル

`config/sites.yml` にサイト情報を記載：

```yaml
sites:
  - name: "漫画タイトル"
    id: "manga-id"           # 出力ファイル名（manga-id.xml）
    url: "https://example.com/manga/1"
    selectors:
      episode_list: ".episode-list li"  # エピソード一覧のセレクター
      episode_title: ".title"           # タイトルのセレクター
      episode_url: "a"                  # リンクのセレクター
      episode_date: ".date"             # 日付のセレクター
    wait_for: ".episode-list"           # ページ読み込み完了を判定するセレクター
```

## 出力

- `output/*.xml` - 各サイトの RSS フィード
- `output/index.html` - フィード一覧ページ

## GitHub Actions

毎日 18:00 JST に自動実行され、RSS フィードを生成して GitHub Pages に自動デプロイ。

手動実行：Actions タブから "Run workflow" をクリック。

### GitHub Pages 設定

1. Settings → Pages
2. Source: "GitHub Actions"
3. ワークフローが自動的に `output/` ディレクトリをデプロイします

## 開発

### テスト実行

```bash
bundle exec rspec
```

### ディレクトリ構成

```
.
├── bin/
│   └── generate          # エントリーポイント
├── config/
│   └── sites.yml         # サイト設定
├── docs/                  # 設計ドキュメント
├── output/                # 生成された RSS フィード（GitHub Pages）
├── lib/
│   ├── feed_builder.rb   # RSS XML 生成
│   ├── index_builder.rb  # index.html 生成
│   ├── rss_generator.rb  # メイン処理
│   └── scraper.rb        # Playwright スクレイピング
├── spec/                  # テスト
├── flake.nix             # Nix 開発環境
└── Gemfile
```

## ライセンス

MIT
