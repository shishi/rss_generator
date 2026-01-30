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
        # Common library path for Chromium
        ldLibraryPath = pkgs.lib.makeLibraryPath [
          pkgs.glib
          pkgs.nss
          pkgs.nspr
          pkgs.atk
          pkgs.cups
          pkgs.dbus
          pkgs.expat
          pkgs.libdrm
          pkgs.libxkbcommon
          pkgs.pango
          pkgs.cairo
          pkgs.alsa-lib
          pkgs.mesa
          pkgs.xorg.libX11
          pkgs.xorg.libXcomposite
          pkgs.xorg.libXdamage
          pkgs.xorg.libXext
          pkgs.xorg.libXfixes
          pkgs.xorg.libXrandr
          pkgs.xorg.libxcb
          pkgs.at-spi2-atk
          pkgs.at-spi2-core
          pkgs.gtk3
        ];
      in
      {
        apps = {
          # Test runner script - run with: nix run .#test
          test = {
            type = "app";
            program = toString (pkgs.writeShellScript "run-tests" ''
              export PLAYWRIGHT_BROWSERS_PATH="${pkgs.chromium}/bin"
              export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
              export CHROME_PATH="${pkgs.chromium}/bin/chromium"
              export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
              export FONTCONFIG_PATH="${pkgs.fontconfig.out}/etc/fonts"
              export LD_LIBRARY_PATH="${ldLibraryPath}"
              exec ${pkgs.xvfb-run}/bin/xvfb-run ${gems}/bin/rspec "$@"
            '');
          };

          # Generate RSS feeds - run with: nix run .#generate
          generate = {
            type = "app";
            program = toString (pkgs.writeShellScript "generate-feeds" ''
              export PLAYWRIGHT_BROWSERS_PATH="${pkgs.chromium}/bin"
              export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
              export CHROME_PATH="${pkgs.chromium}/bin/chromium"
              export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
              export FONTCONFIG_PATH="${pkgs.fontconfig.out}/etc/fonts"
              export LD_LIBRARY_PATH="${ldLibraryPath}"
              exec ${pkgs.xvfb-run}/bin/xvfb-run ${gems}/bin/ruby bin/generate "$@"
            '');
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Ruby with gems managed by Nix
            gems
            gems.wrappedRuby

            # Also keep bundler for development (updating Gemfile)
            pkgs.bundler

          ] ++ (with pkgs; [
            # Node.js (for Playwright)
            nodejs_22

            # Playwright dependencies for Chromium
            # These are required for headless Chrome to run
            chromium

            # System libraries needed by Playwright/Chromium
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

            # X11 libraries
            xorg.libX11
            xorg.libXcomposite
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXrandr
            xorg.libxcb

            # Additional dependencies
            at-spi2-atk
            at-spi2-core
            gtk3

            # Virtual framebuffer for headless GUI testing (WSL2/CI)
            xvfb-run
            xorg.xorgserver

            # Fonts for proper text rendering
            fontconfig
            noto-fonts
            noto-fonts-cjk-sans
            liberation_ttf
          ]);

          shellHook = ''
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.chromium}/bin"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
            export CHROME_PATH="${pkgs.chromium}/bin/chromium"

            # Font configuration for CJK support
            export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
            export FONTCONFIG_PATH="${pkgs.fontconfig.out}/etc/fonts"

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

          # Set library path for Playwright
          LD_LIBRARY_PATH = ldLibraryPath;
        };
      }
    );
}
