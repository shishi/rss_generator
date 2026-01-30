# frozen_string_literal: true

require "fileutils"
require "uri"

class IndexBuilder
  def initialize(sites)
    @sites = sites
  end

  def build
    <<~HTML
      <!DOCTYPE html>
      <html lang="ja">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>RSS Feeds</title>
        <style>
          body { font-family: sans-serif; max-width: 600px; margin: 2rem auto; padding: 0 1rem; }
          h1 { border-bottom: 2px solid #333; padding-bottom: 0.5rem; }
          h2 { margin-top: 2rem; color: #666; font-size: 1rem; }
          .feed { padding: 0.75rem 1rem; border-bottom: 1px solid #eee; }
          .feed a { font-size: 1.1rem; color: #0066cc; text-decoration: none; }
          .feed a:hover { text-decoration: underline; }
        </style>
      </head>
      <body>
        <h1>📚 漫画更新フィード</h1>
        #{build_grouped_feed_list}
      </body>
      </html>
    HTML
  end

  def save(path)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    File.write(path, build)
  end

  private

  def build_grouped_feed_list
    groups = group_by_domain
    groups.map do |domain, sites|
      <<~GROUP
        <h2>#{domain}</h2>
        #{build_feed_items(sites)}
      GROUP
    end.join
  end

  def group_by_domain
    @sites.group_by { |site| extract_domain(site["url"]) }
          .sort_by { |domain, _| domain }
          .to_h
  end

  def extract_domain(url)
    return "unknown" if url.nil? || url.empty?

    URI.parse(url).host || "unknown"
  rescue URI::InvalidURIError
    "unknown"
  end

  def build_feed_items(sites)
    sites.map do |site|
      <<~FEED
        <div class="feed">
          <a href="#{site["id"]}.xml">#{site["name"]}</a>
        </div>
      FEED
    end.join
  end
end
