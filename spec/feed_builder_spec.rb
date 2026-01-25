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

  describe "#build with episodes" do
    it "includes episodes as RSS items" do
      episodes = [
        { title: "第3話", url: "https://example.com/ep/3", date: "2026-01-25" },
        { title: "第2話", url: "https://example.com/ep/2", date: "2026-01-20" }
      ]
      builder = FeedBuilder.new(site_config, episodes)
      xml = builder.build

      expect(xml).to include("<item>")
      expect(xml).to include("<title>第3話</title>")
      expect(xml).to include("<link>https://example.com/ep/3</link>")
      expect(xml).to include("<pubDate>")
    end
  end
end
