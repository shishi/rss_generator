# frozen_string_literal: true

require "fileutils"
require_relative "../lib/index_builder"

RSpec.describe IndexBuilder do
  let(:sites) do
    [
      { "name" => "漫画A", "id" => "manga-a" },
      { "name" => "漫画B", "id" => "manga-b" }
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
