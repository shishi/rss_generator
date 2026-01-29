# spec/scraper_spec.rb
require_relative "../lib/scraper"

RSpec.describe Scraper do
  # 標準モード（CSSセレクターベース）の設定
  let(:selector_config) do
    {
      "name" => "テスト漫画",
      "id" => "test-manga",
      "url" => "https://example.com/manga/1",
      "selectors" => {
        "episode_list" => ".episode-list li",
        "episode_title" => ".title",
        "episode_url" => "a",
        "episode_date" => ".date"
      },
      "wait_for" => ".episode-list"
    }
  end

  # JavaScript評価モード（SPAサイト向け）の設定
  let(:script_config) do
    {
      "name" => "SPA漫画",
      "id" => "spa-manga",
      "url" => "https://spa-example.com/manga/1",
      "user_agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0",
      "wait_seconds" => 2,
      "extraction_script" => "() => [{ title: '第1話', url: '/ep/1', date: '2026-01-25' }]"
    }
  end

  describe "#fetch_episodes with selector mode" do
    it "returns an array of episode hashes" do
      mock_page = double("page")
      mock_playwright = double("playwright")
      mock_browser = double("browser")
      mock_context = double("context")

      allow(Playwright).to receive(:create).and_yield(mock_playwright)
      allow(mock_playwright).to receive(:chromium).and_return(mock_browser)
      allow(mock_browser).to receive(:launch).and_yield(mock_browser)
      # **{} は引数なしとして展開されるので、no_argsでマッチ
      allow(mock_browser).to receive(:new_context).with(no_args).and_yield(mock_context)
      allow(mock_context).to receive(:new_page).and_return(mock_page)
      allow(mock_page).to receive(:goto)
      allow(mock_page).to receive(:wait_for_selector)
      allow(mock_page).to receive(:query_selector_all).and_return([])

      scraper = Scraper.new(selector_config)
      result = scraper.fetch_episodes

      expect(result).to be_an(Array)
    end
  end

  describe "#fetch_episodes with script mode" do
    it "uses custom user_agent and extraction_script" do
      mock_page = double("page")
      mock_playwright = double("playwright")
      mock_browser = double("browser")
      mock_context = double("context")

      expected_context_options = {
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0",
        viewport: { width: 1280, height: 720 }
      }

      allow(Playwright).to receive(:create).and_yield(mock_playwright)
      allow(mock_playwright).to receive(:chromium).and_return(mock_browser)
      allow(mock_browser).to receive(:launch).and_yield(mock_browser)
      allow(mock_browser).to receive(:new_context).with(expected_context_options).and_yield(mock_context)
      allow(mock_context).to receive(:new_page).and_return(mock_page)
      allow(mock_page).to receive(:goto)
      allow(mock_page).to receive(:evaluate).and_return([
        { "title" => "第1話", "url" => "/ep/1", "date" => "2026-01-25" }
      ])

      # sleepをスタブ
      allow_any_instance_of(Scraper).to receive(:sleep)

      scraper = Scraper.new(script_config)
      result = scraper.fetch_episodes

      expect(result).to be_an(Array)
      expect(result.length).to eq(1)
      expect(result.first[:title]).to eq("第1話")
      expect(result.first[:url]).to eq("/ep/1")
    end

    it "normalizes JavaScript result to symbol keys" do
      mock_page = double("page")
      mock_playwright = double("playwright")
      mock_browser = double("browser")
      mock_context = double("context")

      allow(Playwright).to receive(:create).and_yield(mock_playwright)
      allow(mock_playwright).to receive(:chromium).and_return(mock_browser)
      allow(mock_browser).to receive(:launch).and_yield(mock_browser)
      allow(mock_browser).to receive(:new_context).with(anything).and_yield(mock_context)
      allow(mock_context).to receive(:new_page).and_return(mock_page)
      allow(mock_page).to receive(:goto)
      allow(mock_page).to receive(:evaluate).and_return([
        { "title" => "  第2話  ", "url" => "  /ep/2  ", "date" => "  2026-01-26  " }
      ])
      allow_any_instance_of(Scraper).to receive(:sleep)

      scraper = Scraper.new(script_config)
      result = scraper.fetch_episodes

      # 空白がtrimされてシンボルキーになることを確認
      expect(result.first[:title]).to eq("第2話")
      expect(result.first[:url]).to eq("/ep/2")
      expect(result.first[:date]).to eq("2026-01-26")
    end

    it "rejects episodes with empty title and url" do
      mock_page = double("page")
      mock_playwright = double("playwright")
      mock_browser = double("browser")
      mock_context = double("context")

      allow(Playwright).to receive(:create).and_yield(mock_playwright)
      allow(mock_playwright).to receive(:chromium).and_return(mock_browser)
      allow(mock_browser).to receive(:launch).and_yield(mock_browser)
      allow(mock_browser).to receive(:new_context).with(anything).and_yield(mock_context)
      allow(mock_context).to receive(:new_page).and_return(mock_page)
      allow(mock_page).to receive(:goto)
      allow(mock_page).to receive(:evaluate).and_return([
        { "title" => "", "url" => "", "date" => "2026-01-25" },
        { "title" => "第1話", "url" => "/ep/1", "date" => "2026-01-25" }
      ])
      allow_any_instance_of(Scraper).to receive(:sleep)

      scraper = Scraper.new(script_config)
      result = scraper.fetch_episodes

      expect(result.length).to eq(1)
      expect(result.first[:title]).to eq("第1話")
    end
  end
end
