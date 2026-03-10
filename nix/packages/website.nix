{
  stdenv,
  lib,
  bun,
  bun2nix,
  autoPatchelfHook,
  vips,
  glib,
}:
stdenv.mkDerivation {
  pname = "tbone-dev";
  version = "0.0.1";

  src = lib.cleanSourceWith {
    src = ../../web;
    filter = path: type:
      let
        baseName = builtins.baseNameOf path;
      in
        !(builtins.elem baseName [
          "node_modules"
          "dist"
          ".direnv"
          ".git"
          ".astro"
          ".claude"
        ]);
  };

  nativeBuildInputs = [bun bun2nix.hook autoPatchelfHook];
  buildInputs = [vips glib stdenv.cc.cc.lib];

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ../../web/bun.nix;
  };

  # Astro uses its own build command, not `bun build`
  dontUseBunBuild = true;
  dontUseBunCheck = true;
  # We copy dist/ ourselves, not a standalone binary
  dontUseBunInstall = true;

  # Musl variants of sharp are unused on glibc — skip their missing deps
  autoPatchelfIgnoreMissingDeps = ["libc.musl-*"];

  # Patch sharp native binaries before build (autoPatchelfHook only runs in fixupPhase)
  preBuild = ''
    autoPatchelf node_modules/@img
  '';

  buildPhase = ''
    runHook preBuild
    bun run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r dist $out
    runHook postInstall
  '';
}
