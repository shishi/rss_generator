# frozen_string_literal: true

require_relative "../lib/rss_generator"

RSpec.describe RssGenerator do
  describe "#run" do
    it "loads config and generates feeds" do
      # 空の設定でエラーなく実行できることを確認
      generator = RssGenerator.new("spec/fixtures/empty_sites.yml", "tmp/docs")

      expect { generator.run }.not_to raise_error
    ensure
      FileUtils.rm_rf("tmp")
    end
  end

  describe "#load_config" do
    it "loads from a single YAML file" do
      generator = RssGenerator.new("spec/fixtures/empty_sites.yml", "tmp/docs")
      sites = generator.send(:load_config)

      expect(sites).to eq([])
    end

    it "loads from a directory of YAML files" do
      generator = RssGenerator.new("spec/fixtures/sites", "tmp/docs")
      sites = generator.send(:load_config)

      expect(sites.size).to eq(2)
      expect(sites.map { |s| s["name"] }).to contain_exactly("Test Site A", "Test Site B")
    end

    it "sorts sites by filename when loading from directory" do
      generator = RssGenerator.new("spec/fixtures/sites", "tmp/docs")
      sites = generator.send(:load_config)

      # site_a.yml comes before site_b.yml alphabetically
      expect(sites.first["name"]).to eq("Test Site A")
    end
  end
end
