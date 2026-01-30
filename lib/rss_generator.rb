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
    if File.directory?(@config_path)
      load_config_from_directory
    else
      load_config_from_file(@config_path)
    end
  end

  def load_config_from_directory
    Dir.glob(File.join(@config_path, "*.yml")).sort.flat_map do |file|
      load_config_from_file(file)
    end
  end

  def load_config_from_file(path)
    config = YAML.load_file(path, aliases: true)
    config["sites"] || []
  end
end
