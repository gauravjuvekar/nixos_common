{ ... }: {
  hostinfo = {
    isRemotelyAccessible = false;
    isLaptop = false;
    isLocalGraphical = true;
    hostname = "gjuvekar-dt";
    domainname = "client.nvidia.com";
    primaryUsername = "gjuvekar";
  };

  usageinfo = {
    devLangs = [
      "cxx"
      "python"
      "rust"
    ];
    devTools = [
      "binary"
      "containers"
      "db"
      "memory"
      "network"
      "perf"
    ];
    cadTools = [
      "2d"
    ];
  };
}
