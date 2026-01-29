require "builder"
require "fileutils"
require "time"
require "uri"

class FeedBuilder
  def initialize(site_config, episodes)
    @config = site_config
    @episodes = episodes
    @base_url = site_config["base_url"] || extract_base_url(site_config["url"])
  end

  def build
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
    xml.rss(version: "2.0") do
      xml.channel do
        xml.title @config["name"]
        xml.link @config["url"]
        xml.description "#{@config["name"]} の更新情報"

        @episodes.each do |episode|
          full_url = absolute_url(episode[:url])
          xml.item do
            xml.title episode[:title]
            xml.link full_url
            xml.guid full_url
            xml.pubDate format_date(episode[:date])
          end
        end
      end
    end
  end

  def save(path)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    File.write(path, build)
  end

  private

  # URLからベースURL（スキーム + ホスト）を抽出
  def extract_base_url(url)
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}"
  rescue URI::InvalidURIError
    url
  end

  # 相対URLを絶対URLに変換
  def absolute_url(url)
    return url if url.nil? || url.empty?
    return url if url.start_with?("http://", "https://")

    "#{@base_url}#{url}"
  end

  def format_date(date_str)
    return Time.now.rfc2822 if date_str.nil? || date_str.empty?
    Time.parse(date_str).rfc2822
  rescue ArgumentError
    Time.now.rfc2822
  end
end
