{
  description = "A flake to build McDowell_CV_Template.tex";

  inputs = {
    nixpkgs.url = "http:/rime.cx/v1/github/NixOS/nixpkgs/b/nixpkgs-unstable.tar.gz";
    systems.url = "github:nix-systems/default";
  };
  outputs = { self, nixpkgs, systems }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = eachSystem (system: {
        default =
	      let
		      pkgs = nixpkgs.legacyPackages.${system};
		      # thanks https://github.com/NixOS/nixpkgs/issues/215857 and https://gist.github.com/lunik1/7a771166e4e22d0de114bf485a3532db (forked at 573)
		      systemFonts = with pkgs; [ caladea carlito ];
		      OSFONTDIR = builtins.concatStringsSep "//:"
			  (map (font: "${font}/share/fonts") systemFonts);
	      in pkgs.stdenvNoCC.mkDerivation rec {
			name = "McDowell_CV_Template";
			src = self;
			buildInputs = [
			  pkgs.coreutils
			  (pkgs.texlive.combine {
			    inherit (pkgs.texlive)
			      scheme-small latexmk tabu changepage enumitem catchfile latex-bin fontspec;
			    "amsmath" = pkgs.texlive."amsmath";
			  })
			] ++ systemFonts;
			inherit OSFONTDIR;
			buildPhase = ''
			  export PATH="${pkgs.lib.makeBinPath buildInputs}";
			  mkdir -p .cache/texmf-var
			  env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var \
			  latexmk -pdflua -verbose -f -rules -lualatex ./McDowell_CV_Template.tex
			'';

			installPhase = ''
			  mkdir -p $out
			  cp McDowell_CV_Template.pdf $out/
			'';

			phases = [ "unpackPhase" "buildPhase" "installPhase" ];
		};
	});
    };
}
