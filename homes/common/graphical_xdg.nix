{ ... }:
{
  xdg.mime.enable = true;
  xdg.mimeApps =
    {
      enable = true;
      defaultApplications =
        {
          "applicaiton/gzip" = "org.gnome.FileRoller.desktop";
          "applicaiton/x-extension-htm" = "firefox.desktop";
          "applicaiton/x-extension-html" = "firefox.desktop";
          "applicaiton/x-extension-shtml" = "firefox.desktop";
          "applicaiton/x-extension-xht" = "firefox.desktop";
          "applicaiton/x-extension-xhtml" = "firefox.desktop";
          "applicaiton/xhtml+xml" = "firefox.desktop";
          "applicaiton/zip" = "org.gnome.FileRoller.desktop";
          "application/pdf" = "atril.desktop";
          "application/yaml" = "neovide.desktop";
          "image/jpeg" = "xviewer.desktop";
          "image/png" = "xviewer.desktop";
          "image/svg+xml" = "xviewer.desktop";
          "image/tiff" = "xviewer.desktop";
          "image/vnd.microsoft.icon" = "xviewer.desktop";
          "inode/directory" = "nemo.desktop";
          "message/rfc822" = "thunderbird.desktop";
          "text/csv" = "calc.desktop";
          "text/html" = "firefox.desktop";
          "text/plain" = "nvim.desktop";
          "text/x-vcalendar" = "thunderbird.desktop";
          "x-scheme-handler/chrome" = "firefox.desktop";
          "x-scheme-handler/ftp" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/mailto" = "thunderbird.desktop";
        };
    };
  xdg.userDirs.createDirectories = false;
}
