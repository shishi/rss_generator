# frozen_string_literal: true

require "playwright"

# Scraper: Playwrightを使ってWebサイトからエピソード情報を取得する
#
# site_config の構造:
#
# 【標準モード: CSS セレクターベース】
#   {
#     "name" => "漫画タイトル",
#     "id" => "manga-id",
#     "url" => "https://example.com/manga/1",
#     "selectors" => {
#       "episode_list" => ".episode-list li",
#       "episode_title" => ".title",
#       "episode_url" => "a",
#       "episode_date" => ".date"
#     },
#     "wait_for" => ".episode-list",
#     "exclude_selector" => "[data-is-free='false']"  # optional: 除外する要素のCSSセレクタ
#   }
#
# 【JavaScript評価モード: SPAサイト向け】
#   {
#     "name" => "漫画タイトル",
#     "id" => "manga-id",
#     "url" => "https://example.com/manga/1",
#     "user_agent" => "Mozilla/5.0 ...",  # optional: User-Agent偽装
#     "wait_seconds" => 8,                 # optional: ページ読み込み待機秒数
#     "extraction_script" => "() => { ... }"  # JavaScript関数（episodes配列を返す）
#   }
#
# 戻り値: [{ title: "第1話", url: "https://...", date: "2026-01-25" }, ...]
class Scraper
  def initialize(site_config)
    @config = site_config
  end

  # サイトからエピソード一覧を取得する
  # @return [Array<Hash>] エピソード情報の配列。エラー時は空配列
  def fetch_episodes
    episodes = []

    Playwright.create(playwright_cli_executable_path: "npx playwright") do |playwright|
      launch_options = { headless: true }
      launch_options[:executablePath] = ENV["CHROME_PATH"] if ENV["CHROME_PATH"]

      playwright.chromium.launch(**launch_options) do |browser|
        context_options = build_context_options
        browser.new_context(**context_options) do |context|
          page = context.new_page
          page.goto(@config["url"], timeout: 60000, waitUntil: "domcontentloaded")

          if @config["extraction_script"]
            # JavaScript評価モード（SPAサイト向け）
            episodes = fetch_with_script(page)
          else
            # 標準モード（CSSセレクターベース）
            episodes = fetch_with_selectors(page)
          end
        end
      end
    end

    episodes
  rescue Playwright::TimeoutError => e
    warn "[ERROR] #{@config["name"]}: タイムアウト - #{e.message}"
    []
  rescue => e
    warn "[ERROR] #{@config["name"]}: #{e.message}"
    []
  end

  private

  # User-AgentやViewportなどのブラウザコンテキストオプションを構築
  def build_context_options
    options = {}
    options[:userAgent] = @config["user_agent"] if @config["user_agent"]
    options[:viewport] = { width: 1280, height: 720 } if @config["user_agent"]
    options
  end

  # 標準モード: CSSセレクターでエピソード一覧を取得
  def fetch_with_selectors(page)
    page.wait_for_selector(@config["wait_for"], timeout: 30000)
    elements = page.query_selector_all(@config["selectors"]["episode_list"])
    extract_episodes(page, elements)
  end

  # JavaScript評価モード: カスタムスクリプトでエピソード一覧を取得
  def fetch_with_script(page)
    wait_seconds = @config["wait_seconds"] || 5
    sleep wait_seconds

    result = page.evaluate(@config["extraction_script"])
    normalize_episodes(result)
  end

  # JavaScript評価結果をRubyのシンボルキー形式に正規化
  def normalize_episodes(episodes)
    return [] unless episodes.is_a?(Array)

    episodes.map do |ep|
      {
        title: ep["title"]&.strip || "",
        url: ep["url"]&.strip || "",
        date: ep["date"]&.strip || ""
      }
    end.reject { |ep| ep[:title].empty? && ep[:url].empty? }
  end

  def extract_episodes(page, elements)
    elements = filter_excluded_elements(elements) if @config["exclude_selector"]

    elements.map do |element|
      title_el = element.query_selector(@config["selectors"]["episode_title"])
      url_el = element.query_selector(@config["selectors"]["episode_url"])
      date_el = element.query_selector(@config["selectors"]["episode_date"])

      {
        title: title_el&.text_content&.strip || "",
        url: url_el&.get_attribute("href") || "",
        date: date_el&.text_content&.strip || ""
      }
    end.reject { |ep| ep[:title].empty? && ep[:url].empty? }
  end

  def filter_excluded_elements(elements)
    exclude_selector = @config["exclude_selector"]
    elements.reject do |element|
      element.evaluate("el => el.matches(#{exclude_selector.to_json})")
    end
  end
end
