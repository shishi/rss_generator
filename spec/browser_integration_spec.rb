# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tmpdir"
require "yaml"

RSpec.describe "RSS generation with the installed browser runtime" do
  it "scrapes an episode and writes the feed and index through the CLI" do
    cli_path = File.realpath(ENV.fetch("PLAYWRIGHT_CLI_EXECUTABLE_PATH"))
    expect(cli_path).to start_with("/nix/store/")

    Dir.mktmpdir("rss-browser") do |directory|
      html_path = File.join(directory, "episodes.html")
      File.write(html_path, <<~HTML)
        <!doctype html>
        <ul><li class="episode">
          <a href="https://example.test/episodes/1"><span class="title">Episode 1</span></a>
          <time class="date">2026-01-01</time>
        </li></ul>
      HTML
      config_path = File.join(directory, "sites.yml")
      File.write(config_path, YAML.dump("sites" => [{
        "name" => "Browser fixture",
        "id" => "browser-fixture",
        "url" => "file://#{html_path}",
        "base_url" => "https://example.test",
        "wait_for" => ".episode",
        "selectors" => {
          "episode_list" => ".episode",
          "episode_title" => ".title",
          "episode_url" => "a",
          "episode_date" => ".date"
        }
      }]))
      output_path = File.join(directory, "output")

      stdout, stderr, status = Open3.capture3(
        { "npm_config_offline" => "true", "npm_config_cache" => File.join(directory, "npm-cache") },
        "timeout", "--kill-after=5s", "15s", RbConfig.ruby,
        File.expand_path("../bin/generate", __dir__), config_path, output_path,
        chdir: directory
      )

      expect(status.success?).to be(true), "#{stdout}\n#{stderr}"
      feed = File.read(File.join(output_path, "browser-fixture.xml"))
      expect(feed).to include("<item>", "<title>Episode 1</title>", "<link>https://example.test/episodes/1</link>")
      expect(File.read(File.join(output_path, "index.html"))).to include("browser-fixture.xml")
    end
  end
end
