{ pkgs ? import <nixpkgs> {}, nixosPath ? toString <nixpkgs/nixos>, lib ? pkgs.lib
, e2e ? true, throwError ? true }:

with lib;

let
  kubenix = import ./. { inherit pkgs; };

  lib = kubenix.lib;

  generateK8S = name: spec: import ./generators/k8s {
    inherit name;
    inherit pkgs;
    inherit (pkgs) lib;
    inherit spec;
  };

  runK8STests = k8sVersion: import ./tests {
    inherit pkgs lib kubenix k8sVersion e2e throwError nixosPath;
  };
in rec {
  generate.k8s = pkgs.linkFarm "k8s-generated.nix" [
    {
      name = "v1.19.nix";
      path = generateK8S "v1.19" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.19.0/api/openapi-spec/swagger.json";
        sha256 = "15vhl0ibd94rqkq678cf5cl46dxmnanjpq0lmsx15i8l82fnhz35";
      });
    }

    {
      name = "v1.20.nix";
      path = generateK8S "v1.20" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.20.0/api/openapi-spec/swagger.json";
        sha256 = "0g4hrdkzrr1vgjvakxg5n9165yiizb0vga996a3qjjh3nim4wdf7";
      });
    }

    {
      name = "v1.21.nix";
      path = generateK8S "v1.21" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.21.0/api/openapi-spec/swagger.json";
        sha256 = "1k1r4lni78h0cdhfslrz6f6nfrsjazds1pprxvn5qkjspd6ri2hj";
      });
    }

    {
      name = "v1.22.nix";
      path = generateK8S "v1.22" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.22.0/api/openapi-spec/swagger.json";
        sha256 = "0ww7blb13001p4lcdjmbzmy1871i5ggxmfg2r56iws32w1q8cwfn";
      });
    }

    {
      name = "v1.23.nix";
      path = generateK8S "v1.23" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.23.0/api/openapi-spec/swagger.json";
        sha256 = "0jivg8nlxka1y7gzqpcxkmbvhcbxynyrxmjn0blky30q5064wx2a";
      });
    }

    {
      name = "v1.24.nix";
      path = generateK8S "v1.24" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.24.14/api/openapi-spec/swagger.json";
        sha256 = "sha256:1mm3ah08jvp8ghzglf1ljw6qf3ilbil3wzxzs8jzfhljpsxpk41q";
      });
    }

    {
      name = "v1.25.nix";
      path = generateK8S "v1.25" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.25.10/api/openapi-spec/swagger.json";
        sha256 = "sha256:0hdv3677yr8a1qs3jb72m7r9ih7xsnd8nhs9fp506lzfl5b7lycc";
      });
    }

    {
      name = "v1.26.nix";
      path = generateK8S "v1.26" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.26.5/api/openapi-spec/swagger.json";
        sha256 = "sha256:1dyqvggyvqw3z9sml2x06v1l9kynqcs8bkfrkx8jy81gkvg7qxdi";
      });
    }

    {
      name = "v1.27.nix";
      path = generateK8S "v1.27" (builtins.fetchurl {
        url = "https://github.com/kubernetes/kubernetes/raw/v1.27.2/api/openapi-spec/swagger.json";
        sha256 = "sha256:1yqcds6lvpnvc5dsv9pnvp5qb3kc5y6cdgx827szljdlwf51wd15";
      });
    }
  ];

  tests = {
    k8s-1_19 = runK8STests "1.19";
    k8s-1_20 = runK8STests "1.20";
    k8s-1_21 = runK8STests "1.21";
    k8s-1_22 = runK8STests "1.22";
    k8s-1_23 = runK8STests "1.23";
    k8s-1_24 = runK8STests "1.24";
    k8s-1_25 = runK8STests "1.25";
    k8s-1_26 = runK8STests "1.26";
    k8s-1_27 = runK8STests "1.27";
  };

  test-results = pkgs.recurseIntoAttrs (mapAttrs (_: t: pkgs.recurseIntoAttrs {
    results = pkgs.recurseIntoAttrs t.results;
    result = t.result;
  }) tests);

  test-check =
    if !(all (test: test.success) (attrValues tests))
    then throw "tests failed"
    else true;

  examples = import ./examples {};
}
