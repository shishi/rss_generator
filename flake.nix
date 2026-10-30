{
  description = "RSS Generator - Scrape manga sites and generate RSS feeds";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    packnix-bundler = {
      url = "github:tomberek/packnix-bundler";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      packnix-bundler,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        gems = packnix-bundler.lib.buildBundlerApp {
          inherit pkgs;
          name = "rss-generator-gems";
          ruby = pkgs.ruby_3_3;
          gemdir = ./.;
        };

        nodejs = pkgs.nodejs_24;

        package = pkgs.lib.importJSON ./package.json;
        packageLock = pkgs.lib.importJSON ./package-lock.json;
        nodeModules =
          assert pkgs.lib.assertMsg (package.dependencies == packageLock.packages."".dependencies)
            "package.json dependencies differ from package-lock.json; regenerate the lockfile.";
          pkgs.importNpmLock.buildNodeModules {
            inherit package packageLock nodejs;
            derivationArgs.env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
          };

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
          libx11
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxrandr
          libxcb
          at-spi2-atk
          at-spi2-core
          gtk3
        ];

        ldLibraryPath = pkgs.lib.makeLibraryPath chromiumLibs;

        # Common environment variables for Playwright
        playwrightEnv = ''
          export PLAYWRIGHT_BROWSERS_PATH="${pkgs.chromium}/bin"
          export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
          export PLAYWRIGHT_CLI_EXECUTABLE_PATH="${nodeModules}/node_modules/.bin/playwright"
          export CHROME_PATH="${pkgs.chromium}/bin/chromium"
          export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
          export FONTCONFIG_PATH="${pkgs.fontconfig.out}/etc/fonts"
          export LD_LIBRARY_PATH="${ldLibraryPath}"
          export PATH="${nodejs}/bin:$PATH"
        '';

        # Helper to create app scripts
        mkApp = name: script: {
          type = "app";
          program = toString (pkgs.writeShellScript name ''
            ${playwrightEnv}
            ${script}
          '');
        };
      in
      {
        apps = {
          test = mkApp "run-tests" ''
            exec ${pkgs.xvfb-run}/bin/xvfb-run ${gems.wrappedRuby}/bin/ruby -rbundler/setup ${gems}/bin/rspec "$@"
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
            nodeModules
            pkgs.chromium
            pkgs.xvfb-run
            pkgs.xorg-server
            pkgs.fontconfig
            pkgs.noto-fonts
            pkgs.noto-fonts-cjk-sans
            pkgs.liberation_ttf
          ] ++ chromiumLibs;

          LD_LIBRARY_PATH = ldLibraryPath;

          shellHook = ''
            ${playwrightEnv}

            echo "RSS Generator development environment"
            echo "Ruby: $(ruby --version)"
            echo "Node: $(node --version)"
            echo "Chromium: $(chromium --version 2>/dev/null || echo 'available')"
            echo ""
            echo "Gems are managed by Nix from Gemfile.lock checksums"
            echo "To update gems: nix shell --inputs-from . nixpkgs#bundler nixpkgs#ruby_3_3 -c bundle lock --update --add-checksums"
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
