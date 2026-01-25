# frozen_string_literal: true

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
          .feed { padding: 1rem; border-bottom: 1px solid #eee; }
          .feed a { font-size: 1.2rem; color: #0066cc; text-decoration: none; }
          .feed a:hover { text-decoration: underline; }
        </style>
      </head>
      <body>
        <h1>📚 漫画更新フィード</h1>
        #{build_feed_list}
      </body>
      </html>
    HTML
  end

  private

  def build_feed_list
    @sites.map do |site|
      <<~FEED
        <div class="feed">
          <a href="#{site["id"]}.xml">#{site["name"]}</a>
        </div>
      FEED
    end.join
  end
end
