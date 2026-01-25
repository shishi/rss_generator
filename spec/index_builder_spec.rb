# frozen_string_literal: true

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
end
