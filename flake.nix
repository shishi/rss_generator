{
  description = "RSS Generator - Scrape manga sites and generate RSS feeds";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        gems = pkgs.bundlerEnv {
          name = "rss-generator-gems";
          ruby = pkgs.ruby_3_3;
          gemdir = ./.;
        };

        # Node は 1 箇所で決める。lib/scraper.rb が Playwright の driver を
        # `npx playwright` として PATH から spawn するため、npm install に使う版と
        # driver を動かす版が一致していなければならない。
        nodejs = pkgs.nodejs_24;

        # Shared system libraries for Chromium/Playwright
        chromiumLibs = with pkgs; [
          glib
          nss
          nspr
          atk
          cups
          dbus
          expat
          libdrm
          libxkbcommon
          pango
          cairo
          alsa-lib
          mesa
          xorg.libX11
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXrandr
          xorg.libxcb
          at-spi2-atk
          at-spi2-core
          gtk3
        ];

        ldLibraryPath = pkgs.lib.makeLibraryPath chromiumLibs;

        # Common environment variables for Playwright
        playwrightEnv = ''
          export PLAYWRIGHT_BROWSERS_PATH="${pkgs.chromium}/bin"
          export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
          export CHROME_PATH="${pkgs.chromium}/bin/chromium"
          export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
          export FONTCONFIG_PATH="${pkgs.fontconfig.out}/etc/fonts"
          export LD_LIBRARY_PATH="${ldLibraryPath}"
          # nix run .#generate / .#test は devShell を経由しないため、ここで PATH に
          # 載せないと Ruby が spawn する npx が呼び出し元の ambient PATH 依存になる
          # （npx が無ければ Scraper が例外を拾って空配列を返し、全サイト取得失敗）。
          export PATH="${nodejs}/bin:$PATH"
        '';

        # npm install check for Playwright
        npmInstallCheck = ''
          if [ ! -d "node_modules" ]; then
            ${nodejs}/bin/npm install --silent
          fi
        '';

        # Helper to create app scripts
        mkApp = name: script: {
          type = "app";
          program = toString (pkgs.writeShellScript name ''
            ${playwrightEnv}
            ${npmInstallCheck}
            ${script}
          '');
        };
      in
      {
        apps = {
          test = mkApp "run-tests" ''
            exec ${pkgs.xvfb-run}/bin/xvfb-run ${gems}/bin/rspec "$@"
          '';

          generate = mkApp "generate-feeds" ''
            exec ${pkgs.xvfb-run}/bin/xvfb-run ${gems.wrappedRuby}/bin/ruby bin/generate "$@"
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            gems
            gems.wrappedRuby
            pkgs.bundler
            nodejs
            pkgs.chromium
            pkgs.xvfb-run
            pkgs.xorg.xorgserver
            pkgs.fontconfig
            pkgs.noto-fonts
            pkgs.noto-fonts-cjk-sans
            pkgs.liberation_ttf
          ] ++ chromiumLibs;

          LD_LIBRARY_PATH = ldLibraryPath;

          shellHook = ''
            ${playwrightEnv}

            # Install Playwright npm package if node_modules doesn't exist
            if [ ! -d "node_modules" ]; then
              echo "Installing Playwright npm package..."
              npm install --silent
            fi

            echo "RSS Generator development environment"
            echo "Ruby: $(ruby --version)"
            echo "Node: $(node --version)"
            echo "Chromium: $(chromium --version 2>/dev/null || echo 'available')"
            echo ""
            echo "Gems are managed by Nix (gemset.nix)"
            echo "To update gems: bundle update && nix run nixpkgs#bundix -- -l"
            echo ""
            echo "Commands:"
            echo "  nix run .#generate  - Generate RSS feeds"
            echo "  nix run .#test      - Run tests"
            echo "  xvfb-run ruby bin/generate  - Direct run (devShell)"
          '';
        };
      }
    );
}
