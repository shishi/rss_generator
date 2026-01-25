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
end
