# RSS Generator 設計書

## 概要

RSSフィードを提供していない漫画サイトをスクレイピングし、RSSフィードを自動生成するツール。

## 要件

- **目的**: RSSがない漫画サイトの更新をRSSリーダーで購読可能にする
- **ターゲットサイト**: manga-one.com, yanmaga.jp, corocoro.jp（拡張可能）
- **実行環境**: GitHub Actions（1日1回定期実行）
- **公開方法**: GitHub Pages（RSSフィード + インデックスページ）
- **言語**: Ruby + playwright-ruby-client
- **設定管理**: YAML形式

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│                    GitHub Actions                        │
│                   (1日1回 cron実行)                       │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐    ┌───────────┐ │
│  │ config/      │───▶│ Ruby Script  │───▶│ docs/     │ │
│  │ sites.yml    │    │ + Playwright │    │ *.xml     │ │
│  │              │    │              │    │ index.html│ │
│  └──────────────┘    └──────────────┘    └───────────┘ │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │  GitHub Pages   │
                     │ (docs/ を公開)   │
                     └─────────────────┘
```

**フロー:**
1. `config/sites.yml` に監視したい漫画サイトの情報を定義
2. GitHub Actions が1日1回 Ruby スクリプトを実行
3. Playwright でサイトにアクセスし、エピソード情報をスクレイピング
4. RSS XML ファイルと index.html を `docs/` に生成
5. 変更があれば自動コミット＆プッシュ
6. GitHub Pages が `docs/` を公開

## ディレクトリ構成

```
rss_generator/
├── .github/
│   └── workflows/
│       └── generate.yml      # GitHub Actions ワークフロー
├── config/
│   └── sites.yml             # 監視サイト設定
├── lib/
│   ├── rss_generator.rb      # メインエントリーポイント
│   ├── scraper.rb            # Playwrightでスクレイピング
│   ├── feed_builder.rb       # RSS XML生成
│   └── index_builder.rb      # index.html生成
├── docs/                     # GitHub Pages公開ディレクトリ
│   ├── index.html            # フィード一覧ページ（自動生成）
│   └── *.xml                 # 各漫画のRSSフィード（自動生成）
├── spec/                     # テスト
│   └── ...
├── Gemfile
├── Gemfile.lock
└── README.md
```

## 設定ファイル

```yaml
# config/sites.yml
sites:
  - name: "雷雷雷"
    id: "manga-one-rairai"           # ファイル名に使用
    url: "https://manga-one.com/manga/2341"
    selectors:
      episode_list: ".episode-list li"    # エピソード一覧のセレクタ
      episode_title: ".title"              # 各エピソードのタイトル
      episode_url: "a"                     # リンク要素
      episode_date: ".date"                # 更新日（あれば）
    wait_for: ".episode-list"             # このセレクタが出るまで待機

  - name: "聖巡エクスタシー"
    id: "yanmaga-seijun"
    url: "https://yanmaga.jp/comics/..."
    selectors:
      episode_list: ".episode-item"
      episode_title: ".episode-title"
      episode_url: "a"
      episode_date: ".update-date"
    wait_for: ".episode-item"

  - name: "NIKKE すいーとえんかうんと"
    id: "corocoro-nikke"
    url: "https://www.corocoro.jp/title/29"
    selectors:
      episode_list: ".chapter-item"
      episode_title: ".chapter-title"
      episode_url: "a"
      episode_date: ".chapter-date"
    wait_for: ".chapter-item"
```

**設定項目:**
- `name`: 漫画タイトル（RSSのタイトルに使用）
- `id`: 一意の識別子（ファイル名・RSS IDに使用、英数字・ハイフン）
- `url`: スクレイピング対象のURL
- `selectors`: サイトごとのHTML構造に対応したCSSセレクタ
- `wait_for`: JSレンダリング完了を待つセレクタ（Playwright用）

## コード構成

### lib/scraper.rb
Playwrightでサイトをスクレイピング

```ruby
class Scraper
  def initialize(site_config)
    @config = site_config
  end

  def fetch_episodes
    # Playwrightでページを開く
    # wait_for セレクタを待機（JSレンダリング対応）
    # セレクタに従ってエピソード情報を抽出
    # => [{ title: "第6話", url: "...", date: "2026-01-23" }, ...]
  end
end
```

### lib/feed_builder.rb
RSS XMLを生成

```ruby
class FeedBuilder
  def initialize(site_config, episodes)
    @config = site_config
    @episodes = episodes
  end

  def build
    # RSS 2.0形式のXMLを生成
  end

  def save(path)
    # docs/#{id}.xml に保存
  end
end
```

### lib/index_builder.rb
フィード一覧HTMLを生成

```ruby
class IndexBuilder
  def initialize(sites)
    @sites = sites
  end

  def build
    # 全フィードへのリンクを含むシンプルなHTML
  end
end
```

### lib/rss_generator.rb
メイン処理

```ruby
class RssGenerator
  def run
    sites = load_config("config/sites.yml")
    errors = []

    sites.each do |site|
      episodes = Scraper.new(site).fetch_episodes

      if episodes.empty?
        errors << site["name"]
        next  # 0件の場合は更新スキップ、既存ファイル維持
      end

      FeedBuilder.new(site, episodes).save("docs/#{site['id']}.xml")
    end

    IndexBuilder.new(sites).save("docs/index.html")

    # エラーがあれば失敗ステータスで終了 → メール通知トリガー
    if errors.any?
      warn "⚠️ 取得失敗: #{errors.join(', ')}"
      exit 1
    end
  end
end
```

## GitHub Actions ワークフロー

```yaml
# .github/workflows/generate.yml
name: Generate RSS Feeds

on:
  schedule:
    - cron: '0 9 * * *'  # 毎日 18:00 JST (09:00 UTC)
  workflow_dispatch:      # 手動実行も可能

jobs:
  generate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Install Playwright
        run: npx playwright install chromium --with-deps

      - name: Generate feeds
        run: bundle exec ruby lib/rss_generator.rb

      - name: Commit and push if changed
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add docs/
          git diff --staged --quiet || git commit -m "Update RSS feeds"
          git push
```

## エラーハンドリング

**方針:**
- 1サイト失敗しても他のサイトは継続処理
- 取得0件の場合はXML更新をスキップ（既存ファイルを維持）
- エラーがあればワークフロー失敗 → GitHub からメール通知

**理由:**
- 0件でXML更新すると、RSSリーダー側で「全部消えた」と認識される問題を回避
- 次回成功時に同じ記事が再度「新着」扱いになる問題を回避

```ruby
class Scraper
  def fetch_episodes
    episodes = playwright_fetch

    if episodes.empty?
      warn "[WARN] #{@config['name']}: エピソードが取得できませんでした"
    end

    episodes
  rescue Playwright::TimeoutError => e
    warn "[ERROR] #{@config['name']}: タイムアウト - #{e.message}"
    []  # 空配列を返して他のサイトは継続
  end
end
```

## 生成されるページ

### index.html

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>RSS Feeds</title>
  <style>
    body { font-family: sans-serif; max-width: 600px; margin: 2rem auto; }
    .feed { padding: 1rem; border-bottom: 1px solid #eee; }
    .feed a { font-size: 1.2rem; }
    .updated { color: #666; font-size: 0.9rem; }
  </style>
</head>
<body>
  <h1>📚 漫画更新フィード</h1>

  <div class="feed">
    <a href="manga-one-rairai.xml">雷雷雷</a>
    <div class="updated">最終更新: 2026-01-25</div>
  </div>
  <!-- ... -->
</body>
</html>
```

### 公開URL（例）
- `https://shishi.github.io/rss_generator/` → フィード一覧
- `https://shishi.github.io/rss_generator/yanmaga-seijun.xml` → 個別RSS

## テスト戦略

```ruby
# spec/feed_builder_spec.rb
RSpec.describe FeedBuilder do
  it "generates valid RSS 2.0 XML" do
    episodes = [{ title: "第1話", url: "https://...", date: "2026-01-25" }]
    builder = FeedBuilder.new(site_config, episodes)

    xml = builder.build

    expect(xml).to include("<rss version=\"2.0\">")
    expect(xml).to include("<title>第1話</title>")
  end
end

# spec/scraper_spec.rb
RSpec.describe Scraper do
  it "extracts episodes from HTML" do
    # モックしたHTMLでセレクタのロジックをテスト
  end
end
```

## 依存関係

```ruby
# Gemfile
source "https://rubygems.org"

gem "playwright-ruby-client"
gem "builder"  # XML生成用

group :test do
  gem "rspec"
end
```
