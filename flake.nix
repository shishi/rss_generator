{
  description = "RSS Generator - Scrape manga sites and generate RSS feeds";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Ruby
            ruby_3_3
            bundler

            # Node.js (for Playwright)
            nodejs_20

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
          ];

          shellHook = ''
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.chromium}/bin"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
            export CHROME_PATH="${pkgs.chromium}/bin/chromium"

            echo "RSS Generator development environment"
            echo "Ruby: $(ruby --version)"
            echo "Node: $(node --version)"
            echo "Chromium: $(chromium --version 2>/dev/null || echo 'available')"
            echo ""
            echo "Run 'bundle install' to install Ruby dependencies"
          '';

          # Set library path for Playwright
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
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
        };
      }
    );
}
