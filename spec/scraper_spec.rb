# spec/scraper_spec.rb
require_relative "../lib/scraper"

RSpec.describe Scraper do
  let(:site_config) do
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

  describe "#fetch_episodes" do
    it "returns an array of episode hashes" do
      # Playwrightをモック
      mock_page = double("page")
      mock_playwright = double("playwright")
      mock_browser = double("browser")
      mock_context = double("context")

      allow(Playwright).to receive(:create).and_yield(mock_playwright)
      allow(mock_playwright).to receive(:chromium).and_return(mock_browser)
      allow(mock_browser).to receive(:launch).and_yield(mock_browser)
      allow(mock_browser).to receive(:new_context).and_yield(mock_context)
      allow(mock_context).to receive(:new_page).and_return(mock_page)
      allow(mock_page).to receive(:goto)
      allow(mock_page).to receive(:wait_for_selector)
      allow(mock_page).to receive(:query_selector_all).and_return([])

      scraper = Scraper.new(site_config)
      result = scraper.fetch_episodes

      expect(result).to be_an(Array)
    end
  end
end
