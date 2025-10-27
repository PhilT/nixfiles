final: prev: {
  overskride = prev.overskride.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
      (prev.fetchpatch {
        name = "fix-device-list-sorting.patch";
        url = "https://patch-diff.githubusercontent.com/raw/kaii-lb/overskride/pull/47.patch";
        hash = "sha256-B5Ot5B+ToGURnbwKjP+n8J6MI0eR1ppesCw5ijkEVSU=";
      })
    ];
  });
}
