# frozen_string_literal: true

require "fileutils"
require_relative "../lib/index_builder"

RSpec.describe IndexBuilder do
  let(:sites) do
    [
      { "name" => "漫画A", "id" => "manga-a", "url" => "https://example.com/a" },
      { "name" => "漫画B", "id" => "manga-b", "url" => "https://example.com/b" }
    ]
  end

  describe "#build" do
    it "generates HTML with links to all feeds" do
      builder = IndexBuilder.new(sites)
      html = builder.build

      expect(html).to include("<!DOCTYPE html>")
      expect(html).to include("<title>RSS Feeds</title>")
      expect(html).to include('href="manga-a.xml"')
      expect(html).to include("漫画A")
      expect(html).to include('href="manga-b.xml"')
      expect(html).to include("漫画B")
    end

    it "groups sites by domain" do
      sites_multi_domain = [
        { "name" => "Site A1", "id" => "a1", "url" => "https://example.com/a1" },
        { "name" => "Site A2", "id" => "a2", "url" => "https://example.com/a2" },
        { "name" => "Site B1", "id" => "b1", "url" => "https://other.org/b1" }
      ]
      builder = IndexBuilder.new(sites_multi_domain)
      html = builder.build

      # Domain headers should be present
      expect(html).to include("example.com")
      expect(html).to include("other.org")

      # Should have h2 or similar for domain grouping
      expect(html).to include("<h2")
    end
  end

  describe "#save" do
    it "writes HTML to specified file path" do
      builder = IndexBuilder.new(sites)
      tmp_path = "tmp/index.html"
      FileUtils.mkdir_p("tmp")

      builder.save(tmp_path)

      expect(File.exist?(tmp_path)).to be true
      content = File.read(tmp_path)
      expect(content).to include("漫画A")
    ensure
      FileUtils.rm_rf("tmp")
    end
  end
end
