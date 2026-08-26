{ lib, ... }:

{
  services.bind = {
    enable = true;
    listenOn = lib.mkForce [ "127.0.0.1" ];
    listenOnPort = 1053;
    listenOnIpv6 = lib.mkForce [ ];
    extraOptions = ''
      allow-recursion { };
      recursion no;
    '';
    zones."hemimorph.dn42" = {
      master = true;
      file = "${../dn42}/hemimorph.dn42";
    };
    zones."d.6.9.6.d.6.5.6.8.6.d.f.ip6.arpa" = {
      master = true;
      file = "${../dn42}/d.6.9.6.d.6.5.6.8.6.d.f.ip6.arpa";
    };
  };
}
