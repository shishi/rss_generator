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

  # 解釈できた日付だけを RFC2822 文字列で返す。
  # 日付が無い / 解釈できないときは nil を返し、pubDate を省略させる。
  #
  # 以前は Time.now にフォールバックしていたが、それは日付の取得失敗を
  # 「今日公開された」という嘘に変換してしまい、毎回の実行で値が変わる。
  # 日付が取れないなら、偽の値を出すより省略する（RSS 2.0 で pubDate は optional）。
  #
  # サイトが未来日を出すことはある（2026-08-21 の実測では corocoro 3 作品の最新話と
  # mangaone の先読み話 1 件）。その日付が何を指すのかは未確認。
  # 判断材料が無いのでこちらで加工せず、サイトの表記をそのまま流す。
  #
  # 掲載日は JST 固定で解釈する。対象が日本のサイトの暦日表記であり、環境ローカル
  # 解釈にすると生成場所（手元は JST / CI の ubuntu-latest は UTC）で同じ日付が
  # 9 時間ずれるため。
  #
  # オフセットは Time.new に明示して渡す。日付文字列に " +09:00" を連結する形は
  # 使えない。Time.parse はこれをオフセットではなく時刻 09:00 として読み、
  # エラーを出さずに別の時刻になる。ずれ量は実行環境の TZ で変わるので、
  # 数値を手がかりに追わないこと（JST なら 9 時間、UTC なら 18 時間）。
  JST_OFFSET = "+09:00"

  def format_date(date_str)
    return nil if date_str.nil? || date_str.empty?

    date = Date.parse(date_str)
    Time.new(date.year, date.month, date.day, 0, 0, 0, JST_OFFSET).rfc2822
  rescue ArgumentError
    # Date::Error は ArgumentError のサブクラスなので解釈不能な文字列もここに来る
    nil
  end
end
