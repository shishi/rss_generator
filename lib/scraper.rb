# frozen_string_literal: true

require "playwright"

# Scraper: Playwrightを使ってWebサイトからエピソード情報を取得する
#
# site_config の構造:
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
        browser.new_context do |context|
          page = context.new_page
          page.goto(@config["url"], timeout: 60000, waitUntil: "domcontentloaded")
          page.wait_for_selector(@config["wait_for"], timeout: 30000)

          elements = page.query_selector_all(@config["selectors"]["episode_list"])
          episodes = extract_episodes(page, elements)
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
