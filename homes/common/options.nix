{ lib, ... }:
{
  options.fqdn = lib.mkOption
    {
      type = lib.types.str;
      default = null;
    };

  options.fullname = lib.mkOption
    {
      type = lib.types.str;
      default = null;
    };
}
