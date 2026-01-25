require_relative "../lib/feed_builder"

RSpec.describe FeedBuilder do
  let(:site_config) do
    {
      "name" => "テスト漫画",
      "id" => "test-manga",
      "url" => "https://example.com/manga/1"
    }
  end

  describe "#build" do
    it "generates valid RSS 2.0 XML structure" do
      builder = FeedBuilder.new(site_config, [])
      xml = builder.build

      expect(xml).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(xml).to include('<rss version="2.0">')
      expect(xml).to include("<title>テスト漫画</title>")
      expect(xml).to include("<link>https://example.com/manga/1</link>")
      expect(xml).to include("</rss>")
    end
  end
end
