{
  config,
  pkgs,
  ...
}:
{
  dconf.settings = {
    "org/nemo" = {
      "icon-view/captions" = [
        "mime_type"
        "permissions"
        "date_modified"
      ];
      "list-view/default-column-order" = [
        "name"
        "size"
        "type"
        "date_modified"
        "date_created_with_time"
        "date_accessed"
        "date_created"
        "detailed_type"
        "group"
        "where"
        "mime_type"
        "date_modified_with_time"
        "octal_permissions"
        "owner"
        "permissions"
      ];
      "list-view/default-visible-columns" = [
        "name"
        "size"
        "type"
        "date_modified"
        "mime_type"
        "octal_permissions"
      ];
      "sidebar-panels/tree/show-only-directories" = false;
    };
    "org/nemo/preferences" = {
      "date-format" = "informal";
      "default-folder-viewer" = "list-view";
      "show-advanced-permissions" = true;
      "show-computer-icon-toolbar" = true;
      "show-home-icon-toolbar" = true;
      "show-new-folder-icon-toolbar" = true;
      "show-open-in-terminal-toolbar" = true;
      "show-reload-icon-toolbar" = true;
      "size-prefixes" = "base-2";
      "thumbnail-limit" = 104857600;
    };
  };
}
