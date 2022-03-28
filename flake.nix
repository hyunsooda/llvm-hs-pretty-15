{
  inputs = {
    nixpkgs.url = "nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
    llvm-hs = {
      url = "github:MuKnIO/llvm-hs/bytestring-0.11-pure";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, llvm-hs }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (system:
      let
        overlay = self: super: {
          haskell = super.haskell // {
            packageOverrides = hsSelf: hsSuper: {
              # Tests require llvm-hs which is broken atm
              llvm-hs-pretty = self.haskell.lib.dontCheck (hsSelf.callCabal2nix "llvm-hs-pretty" ./. { });
              llvm-hs-pure = hsSelf.callCabal2nix "llvm-hs-pure" "${llvm-hs}/llvm-hs-pure" { };
            };
          };
        };
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
        hs = pkgs.haskell.packages.ghc921;
      in rec {
        inherit overlay;

        packages = rec {
          llvm-hs-pretty = hs.llvm-hs-pretty;
          default = llvm-hs-pretty;
        };

        # Compatibility for older Nix versions
        defaultPackage = packages.default;

        devShell = hs.shellFor {
          packages = hsPkgs: with hsPkgs; [ llvm-hs-pretty ];
          nativeBuildInputs = with hs; [
            cabal-install
            fourmolu
            haskell-language-server
            hlint
          ];
        };
      });
}
