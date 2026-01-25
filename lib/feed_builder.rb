require "builder"
require "time"

class FeedBuilder
  def initialize(site_config, episodes)
    @config = site_config
    @episodes = episodes
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
          xml.item do
            xml.title episode[:title]
            xml.link episode[:url]
            xml.guid episode[:url]
            xml.pubDate format_date(episode[:date])
          end
        end
      end
    end
  end

  private

  def format_date(date_str)
    return Time.now.rfc2822 if date_str.nil? || date_str.empty?
    Time.parse(date_str).rfc2822
  rescue ArgumentError
    Time.now.rfc2822
  end
end
