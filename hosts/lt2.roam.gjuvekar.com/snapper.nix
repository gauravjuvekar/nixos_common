{ pkgs, ... }:
{
  services.snapper.configs =
    {
      home =
        {
          SUBVOLUME = "/home";
          SPACE_LIMIT = "0.7";
          NUMBER_CLEANUP = "yes";
          NUMBER_MIN_AGE = "1800";
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_MIN_AGE = "1800";
          TIMELINE_LIMIT_HOURLY = 24;
          TIMELINE_LIMIT_DAILY = 7;
          TIMELINE_LIMIT_WEEKLY = 5;
          TIMELINE_LIMIT_MONTHLY = 2;
          TIMELINE_LIMIT_YEARLY = 0;
        };
    };

  environment.systemPackages = with pkgs;
    [
      snapper
      snapper-gui
    ];
}
