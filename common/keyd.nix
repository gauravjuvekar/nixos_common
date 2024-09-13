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
                      esc = "overload(numpad, capslock)";
                      # leftalt = "oneshot(alt)";
                      # leftcontrol = "oneshot(control)";
                      # leftshift = "oneshot(shift)";
                      # meta = "oneshot(meta)";
                      tab = "overload(nav, tab)";
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
                      space = "0";
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
                      p = "*";
                      y = "*";
                      "/" = "/";
                      n = "/";
                    };
                };
            };
        };
    };
}
