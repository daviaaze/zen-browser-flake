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
      default = pkgs.wrapFirefox zen-unwrapped {
        pname = "zen-browser";
        applicationName = "zen";
        libName = "zen-${version}";
        wmClass = "zen-alpha";
        extraPolicies = {
          DisableAppUpdate = true;
        };
      };
    };
  };
}
