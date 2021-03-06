{stdenv, lib, fetchFromGitHub, crystal, zlib, openssl, duktape}:
let
  crystalPackages = lib.mapAttrs (name: src:
    stdenv.mkDerivation {
      name = lib.replaceStrings ["/"] ["-"] name;
      src = fetchFromGitHub src;
      phases = "installPhase";
      installPhase = ''cp -r $src $out'';
      passthru = { libName = name; };
    }
  ) (import ./shards.nix);

  crystalLib = stdenv.mkDerivation {
    name = "crystal-lib";
    src = lib.attrValues crystalPackages;
    libNames = lib.mapAttrsToList (k: v: [k v]) crystalPackages;
    phases = "buildPhase";
    buildPhase = ''
      mkdir -p $out
      linkup () {
        while [ "$#" -gt 0 ]; do
          ln -s $2 $out/$1
          shift; shift
        done
      }
      linkup $libNames
    '';
  };
in
stdenv.mkDerivation rec {
  version = "2018-05-27";
  name = "mint-${version}";
  src = fetchFromGitHub {
    owner = "mint-lang";
    repo = "mint";
    rev = "a3f0c86f54b8b3a18dda5c39c2089bdb1d774b4f";
    sha256 = "1bgs6jkwfc2ksq4gj55cl3h2l5g25f5bwlsjryiw9cbx5k4bp1kz";
  };

  buildInputs = [ crystal zlib openssl duktape ];

  buildPhase = ''
    mkdir -p $out/bin

    mkdir tmp
    cd tmp
    ln -s ${crystalLib} lib
    cp -r $src/* .
    crystal build src/mint.cr -o $out/bin/mint --verbose --progress --release --no-debug
  '';

  installPhase = ''true'';

  meta = {
    description = "A refreshing language for the front-end web";
    homepage = https://mint-lang.com/;
    license = stdenv.lib.licenses.bsd3;
    maintainers = with stdenv.lib.maintainers; [ manveru ];
    platforms = [ "x86_64-linux" "i686-linux" "x86_64-darwin" ];
  };
}
