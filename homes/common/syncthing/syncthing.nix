{ config, ... }:
{
  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        "dt.sc.gjuvekar.com" = {
          id = "OR3NTZC-FJTRWZB-TDW43ZD-QY6O6M2-43ZBP37-653FL6D-JRTDGNU-SJY6HA4";
        };
        "lt2.roam.gjuvekar.com" = {
          id = "YX5VZCP-7N3UV4H-YJDASJ5-WWYZB7E-B4WMZ2G-IPHAPIR-VOAZWSG-YPSDLA5";
        };
        "gaurav-p8" = {
          id = "HXMXRPG-Q5RXPLZ-RJMPWPW-ILCA6JE-5VVUXAA-WL4FNTA-NCYWF2U-F3N7YQ5";
        };
        "gaurav-s5e" = {
          id = "WZCRWVG-GUKHIPR-B5BV5MM-M63TPGT-QKD6IST-NOJYO4S-UQRKUXN-C643EAY";
        };
        "gaurav-tp" = {
          id = "WG3P7FK-ZXS2LU7-BCF65RY-JIHMNFO-VFXRNQO-FTLZFW7-W4SUVKV-3OGFBAA";
        };
      };
      folders = {
        "${config.home.homeDirectory}/Sync" = {
          id = "default";
          devices = [
            "dt.sc.gjuvekar.com"
            "lt2.roam.gjuvekar.com"
          ];
        };
      };
    };
  };
}
