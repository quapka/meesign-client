{
  stdenv,

  flutter,
  cargo,
  meesign-crypto
}:
let
  mc = meesign-crypto.overrideAttrs (final: prev: rec {
    postFixup = ''
      mkdir $out/include
      mkdir $out/proto
      cp include/bindings.h $out/include/
      cp proto/meesign.proto $out/proto/
    '';
  });
in
# stdenv.mkDerivation {
flutter.buildFlutterApplication rec {
  pname = "meesign-client";
  version = "0.5.0";
  name = "meesign-client";
  src = ./.;

  # targetFlutterPlatform = "linux";

  buildInputs = [
    # TODO A likely to be refactored once Flutter does not write to it's 
    #      installation destination, see https://github.com/flutter/flutter/issues/44526
    # flutter
    cargo
    mc
  ];

  # get the lib, proto and bindings?
  patchPhase = ''
    mkdir -p meesign_native/native/meesign-crypto/proto
    mkdir -p meesign_native/native/meesign-crypto/proto
    mkdir -p meesign_native/native/meesign-crypto/target/x86_64-unknown-linux-gnu

    cp ${mc.outPath}/proto/meesign.proto meesign_native/native/meesign-crypto/proto
    cp ${mc.outPath}/include/bindings.h meesign_native/native/meesign-crypto/include
    cp ${mc.outPath}/lib/libmeesign_crypto.so meesign_native/native/meesign-crypto/target/x86_64-unknown-linux-gnu
  '';

  autoPubspecLock = src + "/pubspec.lock";

  fixupPhase = ''
    ln -s $out/bin/meesign_client $out/bin/meesign-client
  '';
}
