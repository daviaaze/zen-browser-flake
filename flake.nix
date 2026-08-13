{
  description = "Zen Browser";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};

    version = "1.21.12b";
    src = pkgs.fetchurl {
      url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen.linux-x86_64.tar.xz";
      sha256 = "sha256-R+FJK+3KWuQUL1SiIFWeC+96eE+1MJCPYFnadm0WIi8=";
    };

    zen-unwrapped = pkgs.stdenv.mkDerivation {
      pname = "zen-browser-unwrapped";
      inherit version src;

      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
        wrapGAppsHook3
        patchelfUnstable
      ];

      buildInputs = with pkgs; [
        gtk3
        adwaita-icon-theme
        alsa-lib
        dbus-glib
        libxtst
        stdenv.cc.cc
      ];

      # Libraries that are dlopen'd at runtime — added to rpath
      # so the binaries can find them without LD_LIBRARY_PATH pollution
      runtimeDependencies = with pkgs; [libva.out];
      appendRunpaths = with pkgs; ["${pipewire}/lib"];

      # Mozilla uses "relrhack" for manual relocation processing
      patchelfFlags = ["--no-clobber-old-sections"];

      installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/zen-${version} $out/bin
        cp -r * $out/lib/zen-${version}/
        ln -s $out/lib/zen-${version}/zen $out/bin/zen

        runHook postInstall
      '';

      passthru = {
        applicationName = "Zen Browser";
        binaryName = "zen";
        libName = "zen-${version}";
        gtk3 = pkgs.gtk3;
        ffmpegSupport = true;
        gssSupport = true;
        pipewireSupport = true;
      };

      meta = {
        description = "Zen Browser, a privacy-focused web browser built on Firefox";
        homepage = "https://zen-browser.app";
        license = pkgs.lib.licenses.mpl20;
        platforms = ["x86_64-linux"];
        mainProgram = "zen";
      };
    };
  in {
    packages.${system} = {
      inherit zen-unwrapped;
      default = (pkgs.wrapFirefox zen-unwrapped {
        pname = "zen-browser";
        applicationName = "zen";
        libName = "zen-${version}";
        wmClass = "zen-alpha";
        extraPolicies = {
          DisableAppUpdate = true;
        };
      }).overrideAttrs (old: {
        # Remove the three-element group ["--set-default" "MOZ_ENABLE_WAYLAND" "1"]
        # that the firefox wrapper injects. A flat list.filter would also drop the
        # standalone "1" values from --set MOZ_LEGACY_PROFILES/MOZ_ALLOW_DOWNGRADE.
        makeWrapperArgs = let
          args = old.makeWrapperArgs or [];
          go = acc: rest:
            if rest == [] then acc
            else
              let
                flag = builtins.elemAt rest 0;
                key = builtins.elemAt rest 1;
                val = builtins.elemAt rest 2;
              in
                if flag == "--set-default" && key == "MOZ_ENABLE_WAYLAND" && val == "1" then
                  # skip the triplet
                  go acc (builtins.drop 3 rest)
                else
                  go (acc ++ [flag]) (builtins.drop 1 rest);
        in go [] args;
      });
    };
  };
}