require "builder"
require "date"
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
          pub_date = format_date(episode[:date])
          xml.item do
            xml.title episode[:title]
            xml.link full_url
            xml.guid full_url
            xml.pubDate pub_date if pub_date
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

  # 確かな過去日のときだけ RFC2822 文字列を返す。
  # 日付が無い / 解釈できない / 未来日のときは nil を返し、pubDate を省略させる。
  #
  # 以前は Time.now にフォールバックしていたが、それは日付の取得失敗を
  # 「今日公開された」という嘘に変換してしまい、毎回の実行で値が変わる。
  # 未来日はサイト側が掲載日とは別の日付（無料化予定日など）を出している場合に現れ、
  # 日付でフィルタするリーダーが最新話を隠す原因になる。
  #
  # 掲載日を JST 固定で解釈するのは、対象が日本のサイトの暦日表記であり、
  # かつ実行環境の TZ が一致しないため。GitHub Actions の ubuntu-latest は UTC で、
  # 環境ローカル解釈だと JST 00:00-09:00 に走った実行で「JST の当日公開分」が
  # 未来日と誤判定され、最新話の pubDate だけが落ちる。push と workflow_dispatch は
  # その時間帯に入りうる（schedule は 09:00 UTC なので該当しない）。
  # Time.new にオフセットを明示するのは、ENV["TZ"] が tzdata 不在の環境で黙って
  # UTC に落ちるのを避けるため。日付文字列に " +09:00" を連結する形は使えない
  # （Time.parse は "+09:00" を時刻 09:00 として読み、静かに 9 時間ずれる）。
  JST_OFFSET = "+09:00"

  def format_date(date_str)
    return nil if date_str.nil? || date_str.empty?

    date = Date.parse(date_str)
    time = Time.new(date.year, date.month, date.day, 0, 0, 0, JST_OFFSET)
    return nil if time > Time.now

    time.rfc2822
  rescue ArgumentError
    # Date::Error は ArgumentError のサブクラスなので解釈不能な文字列もここに来る
    nil
  end
end
