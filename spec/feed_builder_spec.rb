require_relative "../lib/feed_builder"

RSpec.describe FeedBuilder do
  let(:site_config) do
    {
      "name" => "テスト漫画",
      "id" => "test-manga",
      "url" => "https://example.com/manga/1"
    }
  end

  # base_url指定ありの設定（SPAサイト向け）
  let(:site_config_with_base_url) do
    {
      "name" => "SPA漫画",
      "id" => "spa-manga",
      "url" => "https://spa-example.com/manga/1/chapter/123",
      "base_url" => "https://spa-example.com"
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

  describe "#build with relative URLs" do
    it "converts relative URLs to absolute URLs using base_url" do
      episodes = [
        { title: "第1話", url: "/manga/1/chapter/100", date: "2026-01-25" }
      ]
      builder = FeedBuilder.new(site_config_with_base_url, episodes)
      xml = builder.build

      expect(xml).to include("<link>https://spa-example.com/manga/1/chapter/100</link>")
      expect(xml).to include("<guid>https://spa-example.com/manga/1/chapter/100</guid>")
    end

    it "extracts base_url from url when base_url is not specified" do
      episodes = [
        { title: "第1話", url: "/ep/1", date: "2026-01-25" }
      ]
      builder = FeedBuilder.new(site_config, episodes)
      xml = builder.build

      expect(xml).to include("<link>https://example.com/ep/1</link>")
    end

    it "keeps absolute URLs unchanged" do
      episodes = [
        { title: "第1話", url: "https://other-site.com/ep/1", date: "2026-01-25" }
      ]
      builder = FeedBuilder.new(site_config, episodes)
      xml = builder.build

      expect(xml).to include("<link>https://other-site.com/ep/1</link>")
    end

    it "handles empty URLs gracefully" do
      episodes = [
        { title: "第1話", url: "", date: "2026-01-25" }
      ]
      builder = FeedBuilder.new(site_config, episodes)
      xml = builder.build

      expect(xml).to include("<link></link>")
    end
  end

  describe "#build pubDate の信頼性" do
    # ENV["TZ"] を差し替えるのは、CI runner(ubuntu-latest)が UTC で、
    # 開発機(WSH/WSL)が JST という環境差そのものを検証したいため。
    def with_tz(tz)
      original = ENV["TZ"]
      ENV["TZ"] = tz
      yield
    ensure
      ENV["TZ"] = original
    end

    # item に pubDate が出ていないことを「XML 全体に <pubDate> が無い」で
    # 表すと、channel 側に pubDate を足した瞬間に検証が無効化される。
    # 件数で数えることで、その変更が test の失敗として見える。
    def pubdate_count(xml)
      xml.scan("<pubDate>").size
    end

    it "日付が空のときは pubDate を出さない" do
      episodes = [{ title: "第1話", url: "https://example.com/ep/1", date: "" }]
      xml = FeedBuilder.new(site_config, episodes).build

      expect(xml).to include("<title>第1話</title>")
      expect(pubdate_count(xml)).to eq(0)
    end

    it "日付が解釈できないときは pubDate を出さない" do
      episodes = [{ title: "第1話", url: "https://example.com/ep/1", date: "近日公開" }]
      xml = FeedBuilder.new(site_config, episodes).build

      expect(xml).to include("<title>第1話</title>")
      expect(pubdate_count(xml)).to eq(0)
    end

    it "日付が未来のときは pubDate を出さない" do
      future = (Time.now + (30 * 24 * 60 * 60)).strftime("%Y-%m-%d")
      episodes = [{ title: "第52話", url: "https://example.com/ep/52", date: future }]
      xml = FeedBuilder.new(site_config, episodes).build

      expect(xml).to include("<title>第52話</title>")
      expect(pubdate_count(xml)).to eq(0)
    end

    it "TZ が UTC の環境でも掲載日を JST として解釈する" do
      with_tz("UTC") do
        episodes = [{ title: "第1話", url: "https://example.com/ep/1", date: "2026-01-25" }]
        xml = FeedBuilder.new(site_config, episodes).build

        expect(xml).to include("<pubDate>Sun, 25 Jan 2026 00:00:00 +0900</pubDate>")
      end
    end

    it "過去の日付はそのまま pubDate に出す" do
      episodes = [{ title: "第1話", url: "https://example.com/ep/1", date: "2026-01-25" }]
      xml = FeedBuilder.new(site_config, episodes).build

      expect(xml).to include("<pubDate>Sun, 25 Jan 2026 00:00:00 +0900</pubDate>")
    end
  end

  describe "#save" do
    it "writes XML to specified file path" do
      builder = FeedBuilder.new(site_config, [])
      tmp_path = "tmp/test-feed.xml"
      FileUtils.mkdir_p("tmp")

      builder.save(tmp_path)

      expect(File.exist?(tmp_path)).to be true
      content = File.read(tmp_path)
      expect(content).to include("<title>テスト漫画</title>")
    ensure
      FileUtils.rm_rf("tmp")
    end
  end
end
