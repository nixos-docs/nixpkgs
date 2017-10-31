# TODO(@Ericson2314): Remove `pkgs` param, which is only used for
# `buildStackProject`, `justStaticExecutables` and `checkUnusedPackages`
{ pkgs, lib }:

rec {
  makePackageSet = import ./make-package-set.nix;

  /* The function overrideCabal lets you alter the arguments to the
     mkDerivation function.

     Example:

     First, note how the aeson package is constructed in hackage-packages.nix:

         "aeson" = callPackage ({ mkDerivation, attoparsec, <snip>
                                }:
                                  mkDerivation {
                                    pname = "aeson";
                                    <snip>
                                    homepage = "https://github.com/bos/aeson";
                                  })

     The mkDerivation function of haskellPackages will take care of putting
     the homepage in the right place, in meta.

         > haskellPackages.aeson.meta.homepage
         "https://github.com/bos/aeson"

         > x = haskell.lib.overrideCabal haskellPackages.aeson (old: { homepage = old.homepage + "#readme"; })
         > x.meta.homepage
         "https://github.com/bos/aeson#readme"

   */
  overrideCabal = drv: f: (drv.override (args: args // {
    mkDerivation = drv: (args.mkDerivation drv).override f;
  })) // {
    overrideScope = scope: overrideCabal (drv.overrideScope scope) f;
  };

  /* doCoverage modifies a haskell package to enable the generation
     and installation of a coverage report.

     See https://wiki.haskell.org/Haskell_program_coverage
   */
  doCoverage = drv: overrideCabal drv (drv: { doCoverage = true; });

  /* dontCoverage modifies a haskell package to disable the generation
     and installation of a coverage report.
   */
  dontCoverage = drv: overrideCabal drv (drv: { doCoverage = false; });

  /* doHaddock modifies a haskell package to enable the generation and
     installation of API documentation from code comments using the
     haddock tool.
   */
  doHaddock = drv: overrideCabal drv (drv: { doHaddock = true; });

  /* dontHaddock modifies a haskell package to disable the generation and
     installation of API documentation from code comments using the
     haddock tool.
   */
  dontHaddock = drv: overrideCabal drv (drv: { doHaddock = false; });

  /* doJailbreak enables the removal of version bounds from the cabal
     file. You may want to avoid this function.

     This is useful when a package reports that it can not be built
     due to version mismatches. In some cases, removing the version
     bounds entirely is an easy way to make a package build, but at
     the risk of breaking software in non-obvious ways now or in the
     future.

     Instead of jailbreaking, you can patch the cabal file.
   */
  doJailbreak = drv: overrideCabal drv (drv: { jailbreak = true; });

  /* dontJailbreak restores the use of the version bounds the check
     the use of dependencies in the package description.
   */
  dontJailbreak = drv: overrideCabal drv (drv: { jailbreak = false; });

  /* doCheck enables dependency checking, compilation and execution
     of test suites listed in the package description file.
   */
  doCheck = drv: overrideCabal drv (drv: { doCheck = true; });
  /* dontCheck disables dependency checking, compilation and execution
     of test suites listed in the package description file.
   */
  dontCheck = drv: overrideCabal drv (drv: { doCheck = false; });

  /* doBenchmark enables dependency checking, compilation and execution
     for benchmarks listed in the package description file.
   */
  doBenchmark = drv: overrideCabal drv (drv: { doBenchmark = true; });
  /* dontBenchmark disables dependency checking, compilation and execution
     for benchmarks listed in the package description file.
   */
  dontBenchmark = drv: overrideCabal drv (drv: { doBenchmark = false; });

  /* doDistribute enables the distribution of binaries for the package
     via hydra.
   */
  doDistribute = drv: overrideCabal drv (drv: { hydraPlatforms = drv.platforms or ["i686-linux" "x86_64-linux" "x86_64-darwin"]; });
  /* dontDistribute disables the distribution of binaries for the package
     via hydra.
   */
  dontDistribute = drv: overrideCabal drv (drv: { hydraPlatforms = []; });

  /* appendConfigureFlag adds a single argument that will be passed to the
     cabal configure command, after the arguments that have been defined
     in the initial declaration or previous overrides.

     Example:

         > haskell.lib.appendConfigureFlag haskellPackages.servant "--profiling-detail=all-functions"
   */
  appendConfigureFlag = drv: x: overrideCabal drv (drv: { configureFlags = (drv.configureFlags or []) ++ [x]; });

  /* removeConfigureFlag drv x is a Haskell package like drv, but with
     all cabal configure arguments that are equal to x removed.

         > haskell.lib.removeConfigureFlag haskellPackages.servant "--verbose"
   */
  removeConfigureFlag = drv: x: overrideCabal drv (drv: { configureFlags = lib.remove x (drv.configureFlags or []); });

  addBuildTool = drv: x: addBuildTools drv [x];
  addBuildTools = drv: xs: overrideCabal drv (drv: { buildTools = (drv.buildTools or []) ++ xs; });

  addExtraLibrary = drv: x: addExtraLibraries drv [x];
  addExtraLibraries = drv: xs: overrideCabal drv (drv: { extraLibraries = (drv.extraLibraries or []) ++ xs; });

  addBuildDepend = drv: x: addBuildDepends drv [x];
  addBuildDepends = drv: xs: overrideCabal drv (drv: { buildDepends = (drv.buildDepends or []) ++ xs; });

  addPkgconfigDepend = drv: x: addPkgconfigDepends drv [x];
  addPkgconfigDepends = drv: xs: overrideCabal drv (drv: { pkgconfigDepends = (drv.pkgconfigDepends or []) ++ xs; });

  addSetupDepend = drv: x: addSetupDepends drv [x];
  addSetupDepends = drv: xs: overrideCabal drv (drv: { setupHaskellDepends = (drv.setupHaskellDepends or []) ++ xs; });

  enableCabalFlag = drv: x: appendConfigureFlag (removeConfigureFlag drv "-f-${x}") "-f${x}";
  disableCabalFlag = drv: x: appendConfigureFlag (removeConfigureFlag drv "-f${x}") "-f-${x}";

  markBroken = drv: overrideCabal drv (drv: { broken = true; });
  markBrokenVersion = version: drv: assert drv.version == version; markBroken drv;

  enableLibraryProfiling = drv: overrideCabal drv (drv: { enableLibraryProfiling = true; });
  disableLibraryProfiling = drv: overrideCabal drv (drv: { enableLibraryProfiling = false; });

  enableSharedExecutables = drv: overrideCabal drv (drv: { enableSharedExecutables = true; });
  disableSharedExecutables = drv: overrideCabal drv (drv: { enableSharedExecutables = false; });

  enableSharedLibraries = drv: overrideCabal drv (drv: { enableSharedLibraries = true; });
  disableSharedLibraries = drv: overrideCabal drv (drv: { enableSharedLibraries = false; });

  enableDeadCodeElimination = drv: overrideCabal drv (drv: { enableDeadCodeElimination = true; });
  disableDeadCodeElimination = drv: overrideCabal drv (drv: { enableDeadCodeElimination = false; });

  enableStaticLibraries = drv: overrideCabal drv (drv: { enableStaticLibraries = true; });
  disableStaticLibraries = drv: overrideCabal drv (drv: { enableStaticLibraries = false; });

  appendPatch = drv: x: appendPatches drv [x];
  appendPatches = drv: xs: overrideCabal drv (drv: { patches = (drv.patches or []) ++ xs; });

  doHyperlinkSource = drv: overrideCabal drv (drv: { hyperlinkSource = true; });
  dontHyperlinkSource = drv: overrideCabal drv (drv: { hyperlinkSource = false; });

  disableHardening = drv: flags: overrideCabal drv (drv: { hardeningDisable = flags; });

  # Controls if Nix should strip the binary files (removes debug symbols)
  doStrip = drv: overrideCabal drv (drv: { dontStrip = false; });
  dontStrip = drv: overrideCabal drv (drv: { dontStrip = true; });

  # Useful for debugging segfaults with gdb.
  # -g: enables debugging symbols
  # --disable-*-stripping: tell GHC not to strip resulting binaries
  # dontStrip: see above
  enableDWARFDebugging = drv:
   appendConfigureFlag (dontStrip drv) "--ghc-options=-g --disable-executable-stripping --disable-library-stripping";

  sdistTarball = pkg: lib.overrideDerivation pkg (drv: {
    name = "${drv.pname}-source-${drv.version}";
    # Since we disable the haddock phase, we also need to override the
    # outputs since the separate doc output will not be produced.
    outputs = ["out"];
    buildPhase = "./Setup sdist";
    haddockPhase = ":";
    checkPhase = ":";
    installPhase = "install -D dist/${drv.pname}-*.tar.gz $out/${drv.pname}-${drv.version}.tar.gz";
    fixupPhase = ":";
  });

  linkWithGold = drv : appendConfigureFlag drv
    "--ghc-option=-optl-fuse-ld=gold --ld-option=-fuse-ld=gold --with-ld=ld.gold";

  # link executables statically against haskell libs to reduce closure size
  justStaticExecutables = drv: overrideCabal drv (drv: {
    enableSharedExecutables = false;
    isLibrary = false;
    doHaddock = false;
    postFixup = "rm -rf $out/lib $out/nix-support $out/share/doc";
  } // lib.optionalAttrs (pkgs.hostPlatform.isDarwin) {
    configureFlags = (drv.configureFlags or []) ++ ["--ghc-option=-optl=-dead_strip"];
  });

  buildFromSdist = pkg: lib.overrideDerivation pkg (drv: {
    unpackPhase = let src = sdistTarball pkg; tarname = "${pkg.pname}-${pkg.version}"; in ''
      echo "Source tarball is at ${src}/${tarname}.tar.gz"
      tar xf ${src}/${tarname}.tar.gz
      cd ${pkg.pname}-*
    '';
  });

  buildStrictly = pkg: buildFromSdist (failOnAllWarnings pkg);

  failOnAllWarnings = drv: appendConfigureFlag drv "--ghc-option=-Wall --ghc-option=-Werror";

  checkUnusedPackages =
    { ignoreEmptyImports ? false
    , ignoreMainModule   ? false
    , ignorePackages     ? []
    } : drv :
      overrideCabal (appendConfigureFlag drv "--ghc-option=-ddump-minimal-imports") (_drv: {
        postBuild = with lib;
          let args = concatStringsSep " " (
                       optional ignoreEmptyImports "--ignore-empty-imports" ++
                       optional ignoreMainModule   "--ignore-main-module" ++
                       map (pkg: "--ignore-package ${pkg}") ignorePackages
                     );
          in "${pkgs.haskellPackages.packunused}/bin/packunused" +
             optionalString (args != "") " ${args}";
      });

  buildStackProject = pkgs.callPackage ./generic-stack-builder.nix { };

  triggerRebuild = drv: i: overrideCabal drv (drv: { postUnpack = ": trigger rebuild ${toString i}"; });

  overrideSrc = drv: { src, version ? drv.version }:
    overrideCabal drv (_: { inherit src version; editedCabalFile = null; });

}
