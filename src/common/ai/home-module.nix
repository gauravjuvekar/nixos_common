{ codexPackages }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.codex-jail;
in
{
  options.programs.codex-jail = {
    enable = lib.mkEnableOption "Bubblewrap-isolated Codex wrappers: codex-jailed with host networking and codex-restricted with proxy-only networking";

    allowedDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = (codexPackages.makeRestrictedCodex { inherit pkgs; }).allowedDomains;
      description = ''
        Hostnames permitted through codex-restricted's shared proxy on HTTPS
        port 443. Plain names match exactly; *.example.com matches subdomains
        at any depth but not example.com itself, which must be listed separately.
        Other wildcard forms are rejected. Other destinations, ports, and destinations resolving
        to private or local IP addresses are blocked. This list does not
        restrict codex-jailed's host network access.
      '';
    };

    extraPkgs = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        Additional packages and their runtime dependencies exposed inside both
        Bubblewrap jails, alongside the default tools. Host-installed programs
        are not automatically available inside the jails.
      '';
    };

    jailedPackage = lib.mkOption {
      type = lib.types.package;
      default = codexPackages.makeJailedCodex {
        inherit pkgs;
        inherit (cfg) extraPkgs;
      };
      description = ''
        The codex-jailed package to install. By default, Bubblewrap limits host
        filesystem access to the current working directory, writable ~/.codex,
        packaged tools and their dependencies, and explicitly configured mounts.
        It retains host network access. Additional directories, Git worktrees,
        and Nix daemon access can be exposed through the package constructor.
        Codex's own sandbox is disabled; these restrictions are enforced by
        Bubblewrap.
      '';
    };

    restrictedPackage = lib.mkOption {
      type = lib.types.package;
      default = codexPackages.makeRestrictedCodex {
        inherit pkgs;
        inherit (cfg) allowedDomains extraPkgs;
      };
      description = ''
        The codex-restricted package, including its sharedProxy units. It adds
        an isolated network namespace to the filesystem jail used by
        codex-jailed: direct host and Internet connections are blocked, and
        outbound access goes through a Unix socket to the shared HTTPS proxy.
        Only allowed hostnames on port 443 with public destination IPs are
        permitted. Nix daemon access is disabled to prevent network access
        through the host daemon. Hosted web search and apps are also disabled
        because they run outside the jail's network restrictions.
        Overriding this package also overrides its domain policy and jail
        packages.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.jailedPackage
      cfg.restrictedPackage
    ];
    systemd.user = {
      inherit (cfg.restrictedPackage.sharedProxy) sockets services;
    };
  };
}
