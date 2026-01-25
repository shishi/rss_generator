# frozen_string_literal: true

require "yaml"
require "fileutils"
require_relative "scraper"
require_relative "feed_builder"
require_relative "index_builder"

class RssGenerator
  def initialize(config_path, output_dir)
    @config_path = config_path
    @output_dir = output_dir
  end

  def run
    sites = load_config
    errors = []

    sites.each do |site|
      episodes = Scraper.new(site).fetch_episodes

      if episodes.empty?
        errors << site["name"]
        warn "[WARN] #{site["name"]}: エピソードが取得できませんでした"
        next
      end

      output_path = File.join(@output_dir, "#{site["id"]}.xml")
      FeedBuilder.new(site, episodes).save(output_path)
      puts "[OK] #{site["name"]}: #{episodes.size}件のエピソードを取得"
    end

    IndexBuilder.new(sites).save(File.join(@output_dir, "index.html"))

    if errors.any?
      warn "[ERROR] 取得失敗: #{errors.join(", ")}"
      exit 1
    end
  end

  private

  def load_config
    config = YAML.load_file(@config_path)
    config["sites"] || []
  end
end
