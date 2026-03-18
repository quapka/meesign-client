{
  stdenv,

  flutter,
  cargo,
  meesign-crypto
}:
flutter.buildFlutterApplication rec {
  pname = "meesign-client";
  version = "0.5.0";
  name = "meesign-client";
  src = ./.;

  flutterMode = "release";

  targetFlutterPlatform = "web";

  buildInputs = [
    cargo
  ];

  flutterBuildFlags = ["--dart-define=ALLOW_BAD_CERTS=true"];

  # get the lib, proto and bindings?
  patchPhase = ''
    mkdir -p meesign_native/native/meesign-crypto/proto
    mkdir -p meesign_native/native/meesign-crypto/proto
    mkdir -p meesign_native/native/meesign-crypto/target/x86_64-unknown-linux-gnu
    mkdir -p meesign_native/native/meesign-crypto/pkg

    cp ${meesign-crypto.outPath}/proto/meesign.proto meesign_native/native/meesign-crypto/proto
    cp ${meesign-crypto.outPath}/include/bindings.h meesign_native/native/meesign-crypto/include
    cp ${meesign-crypto.outPath}/lib/libmeesign_crypto.so meesign_native/native/meesign-crypto/target/x86_64-unknown-linux-gnu
    cp --recursive ${meesign-crypto.outPath}/pkg meesign_native/native/meesign-crypto/
  '';

  autoPubspecLock = src + "/pubspec.lock";

  fixupPhase = ''
    # ln -s $out/bin/meesign_client $out/bin/${pname}
  '';
}
