{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix.url = "github:nix-community/fenix";
    # TODO meesign-crypto-src seems to have 
    meesign-crypto-src.url = "github:crocs-muni/meesign-crypto";
  };

  outputs =
    {
      self,
      flake-utils,
      naersk,
      nixpkgs,
      fenix,
      meesign-crypto-src,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
          overlays = [ fenix.overlays.default ];
        };

        naersk' = pkgs.callPackage naersk { };
        meesign-crypto = pkgs.callPackage meesign-crypto-src { };
        meesign-client = pkgs.callPackage ./. { inherit meesign-crypto; };
      in
      rec {
        packages = {
          inherit meesign-crypto meesign-client;
          default = meesign-client;
          # inherit meesign-crypto;
        };

        devShell = pkgs.mkShell rec {
          nativeBuildInputs = with pkgs; [
            gdk-pixbuf
            glib
            libepoxy
            atk
            harfbuzz
            pango
            cairo
            libselinux
            libsepol
            xorg.xorgproto
            protobuf
            xorg.libXft
            xorg.libXinerama
            pcre2
            xorg.libX11.dev
            xorg.libX11
            flutter
            cmake
            ninja
            clang
            clang-tools
            pkg-config
            gtk3-x11
            gtk3.dev
            util-linux
            sqlite
            poppler-utils
            libllvm
            libclang

            cargo
            zenity
            openssl
            openssl.dev
            alejandra
            rust-analyzer
            (pkgs.fenix.stable.withComponents [
              "cargo"
              "clippy"
              "rust-src"
              "rustc"
              "rustfmt"
            ])
          ];
          PROTOC = with pkgs; "${protobuf}/bin/protoc";
          CPATH = builtins.concatStringsSep ":" (
            with pkgs;
            [
              "${xorg.libX11.dev}/include"
              "${xorg.xorgproto}/include"
              "${libepoxy}/lib"
              # "${libclang.lib.outPath}/lib/${libclang.lib.pname}/${libclang.lib.version}/include"
            ]
          );
          OPENSSL_LIB_DIR = with pkgs; pkgs.lib.makeLibraryPath [ openssl ];
          OPENSSL_INCLUDE_DIR = with pkgs; "${openssl.dev}/include";

          LD_LIBRARY_PATH =
            with pkgs;
            pkgs.lib.makeLibraryPath [
              pango
              libepoxy
              gtk3
              gtk3.dev
              sqlite
              harfbuzz
              # clang-tools
              # libclang
              atk
              cairo
              # clang
              libllvm
              gdk-pixbuf
              glib
              pcre2
            ];
          # + [ "${PROJECT_ROOT}/meesign_native/native/"];

          PROJECT_ROOT = builtins.toString ./.;
          # NOTE: not 
            # flutter pub get upgrade

            # pushd meesign_native
            # dart pub get
            # popd

          shellHook = ''
            LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${PROJECT_ROOT}/meesign_native/native/meesign-crypto/target/x86_64-unknown-linux-gnu/release"
            export PATH="$PATH":"$HOME/.pub-cache/bin"
          '';
        };
      }
    );
}
