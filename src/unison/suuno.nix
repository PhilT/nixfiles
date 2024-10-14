{ ... }:
{
  imports = [
    (import ./phone.nix { name = "suuno"; })
  ];
}