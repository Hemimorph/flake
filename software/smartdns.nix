{
  inputs,
  pkgs,
  lib,
  ...
}:
let

  dnsmasq-china-list-pkgs = pkgs.stdenvNoCC.mkDerivation {
    pname = "dnsmasq-china-list";
    version = "0-unstable";
    src = inputs.dnsmasq-china-list;

    buildPhase = ''
      runHook preBuild

      sed -i '/^server=/!d' accelerated-domains.china.conf
      sed -i 's/^server=\/\([^/]*\)\/.*$/\1/g' accelerated-domains.china.conf

      sed -i '/^server=/!d' apple.china.conf
      sed -i 's/^server=\/\([^/]*\)\/.*$/\1/g' apple.china.conf

      sed -i '/^server=/!d' google.china.conf
      sed -i 's/^server=\/\([^/]*\)\/.*$/\1/g' google.china.conf

      sed -i '/^bogus-nxdomain=/!d' bogus-nxdomain.china.conf
      sed -i 's/^bogus-nxdomain=//g' bogus-nxdomain.china.conf

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/dnsmasq-china-list
      install -Dm644 -v *.conf -t $out/share/dnsmasq-china-list/

      runHook postInstall
    '';
    meta = with lib; {
      description = "Chinese-specific configuration to improve your favorite DNS server. Best partner for chnroutes";
      homepage = "https://github.com/felixonmars/dnsmasq-china-list";
      lincense = lincense.wtfpl;
      maintainers = with maintainers; [ Cryolitia ];
    };
  };

  confFile = pkgs.writeText "smartdns.conf" ''
    bind [::]:53
    speed-check-mode ping,tcp:80,tcp:443
    prefetch-domain yes
    dualstack-ip-selection yes
    log-level info
    log-console yes
    audit-enable yes
    audit-console yes

    server-https https://dns.google/dns-query -host-ip 8.8.8.8 -host-name dns.google -tls-host-verify dns.google
    server-https https://cloudflare-dns.com/dns-query -host-ip 1.1.1.1 -host-name cloudflare-dns.com -tls-host-verify cloudflare-dns.com

    server 192.168.88.1 -g cn -e
    server 192.168.88.1 -g internal -e
    server 127.0.0.1:1053 -g DN42local -e
    server [fd42:d42:d42:53::1] -g DN42 -e
    server [fd42:d42:d42:54::1] -g DN42 -e
    server [fd10:127:53:53::] -g NEO -e

    domain-set -name cn -file ${dnsmasq-china-list-pkgs}/share/dnsmasq-china-list/accelerated-domains.china.conf
    domain-set -name apple -file ${dnsmasq-china-list-pkgs}/share/dnsmasq-china-list/apple.china.conf
    domain-set -name google -file ${dnsmasq-china-list-pkgs}/share/dnsmasq-china-list/google.china.conf

    force-AAAA-SOA yes

    domain-rules /internal/ -nameserver internal -address -4
    domain-rules /hemimorph.dn42/ -nameserver DN42local -address -6
    domain-rules /d.6.9.6.d.6.5.6.8.6.d.f.ip6.arpa/ -nameserver DN42local
    domain-rules /dn42/ -nameserver DN42 -address -6
    domain-rules /neo/ -nameserver NEO -address -6
    domain-rules /d.f.ip6.arpa/ -nameserver DN42
    domain-rules /domain-set:cn/ -nameserver cn -address -6
    domain-rules /domain-set:apple/ -nameserver cn -address -6
    domain-rules /domain-set:google/ -nameserver cn -address -6

    ip-set -name nxdomain -file ${dnsmasq-china-list-pkgs}/share/dnsmasq-china-list/bogus-nxdomain.china.conf
    ip-rules ip-set:nxdomain -bogus-nxdomain

    address /onion/#4
    address /onion/fdd0:5ad7:5f56:1:be24:11ff:fe6a:4be1

    address /steamcontent.com/#6
    nameserver /steamcontent.com/cn
  '';
in
{
  services.smartdns = {
    enable = true;
  };

  systemd.services.smartdns.restartTriggers = lib.mkForce [ confFile ];
  systemd.services.smartdns.path = [ pkgs.gzip ];
  environment.etc."smartdns/smartdns.conf".source = lib.mkForce confFile;

  networking.firewall.allowedUDPPorts = [ 53 ];
}
