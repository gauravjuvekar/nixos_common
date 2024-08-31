{ ... }:
{
  services.keyd =
    {
      enable = true;
      keyboards =
        {
          default =
            {
              ids = [ "*" ];
              settings =
                {
                  main =
                    {
                      capslock = "overload(control, esc)";
                      esc = "overload(nav, capslock)";
                      leftalt = "oneshot(alt)";
                      leftcontrol = "oneshot(control)";
                      leftshift = "oneshot(shift)";
                      meta = "oneshot(meta)";
                      tab = "overload(numpad, tab)";
                    };
                  "nav" =
                    {
                      h = "left";
                      j = "down";
                      k = "up";
                      l = "right";
                    };
                  "numpad" =
                    {
                      m = "1";
                      "," = "2";
                      "." = "3";
                      j = "4";
                      k = "5";
                      l = "6";
                      u = "7";
                      i = "8";
                      o = "9";
                      "'" = ".";
                      h = "-";
                      ";" = "+";
                      "p" = "*";
                      "/" = "/";
                      space = "0";
                    };
                };
            };
        };
    };
}
