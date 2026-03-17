{
  description = "PUL ChromeDriver 146.0.7680.80";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          
          platformData = {
            "x86_64-linux"   = { plat = "linux64";   hash = "sha256-0000000000000000000000000000000000000000000="; };
            "x86_64-darwin"  = { plat = "mac-x64";   hash = "sha256-0000000000000000000000000000000000000000000="; };
            "aarch64-darwin" = { plat = "mac-arm64"; hash = "sha256-dNEHIKl7X6xJtW7dEpDqn8qTUPxkInxL5d7C/w8jENY="; };
          };

          currentData = platformData.${system};
          version = "146.0.7680.80";
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "chromedriver";
            inherit version;

            src = pkgs.fetchurl {
              url = "https://storage.googleapis.com/chrome-for-testing-public/${version}/${currentData.plat}/chromedriver-${currentData.plat}.zip";
              hash = currentData.hash;
            };

            nativeBuildInputs = [ pkgs.unzip ];

            unpackPhase = ''
              unzip $src
            '';

            installPhase = ''
              mkdir -p $out/bin
              cp chromedriver-${currentData.plat}/chromedriver $out/bin/chromedriver
              chmod +x $out/bin/chromedriver
            '';
          };
        });
    };
}
