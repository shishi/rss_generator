require "builder"

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
      end
    end
  end
end
