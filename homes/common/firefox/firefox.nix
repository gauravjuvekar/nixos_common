{ firefox-addons, lib, ... }:
{
  programs.firefox =
    {
      enable = true;
      profiles."Personal" =
        {
          name = "Personal";
          isDefault= (lib.mkDefault false);
          id = 0;
          settings =
            {
              "app.shield.optoutstudies.enabled" = false;
              "browser.bookmarks.restore_default_bookmarks" = false;
              "browser.bookmarks.showMobileBookmarks" = false;
              "browser.compactmode.show" = true;
              "browser.contentblocking.category" = "strict";
              "browser.download.alwaysOpenPanel" = false;
              "browser.download.always_ask_before_handling_new_types" = true;
              "browser.download.autohideButton" = false;
              "browser.download.improvements_to_download_panel" = false;
              "browser.download.panel.shown" = true;
              "browser.download.start_downloads_in_tmp_dir" = true;
              "browser.download.useDownloadDir" = false;
              "browser.fullscreen.autohide" = false;
              "browser.link.open_newwindow.restriction" = 0;
              "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
              "browser.newtabpage.activity-stream.feeds.topsites" = false;
              "browser.newtabpage.activity-stream.improvesearch.handoffToAwesomebar" = false;
              "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
              "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
              "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
              "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
              "browser.newtabpage.activity-stream.showSponsored" = false;
              "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
              "browser.proton.enabled" = false;
              "browser.search.separatePrivateDefault.urlbarResult.enabled" = false;
              "browser.search.widget.inNavBar" = true;
              "browser.startup.page" = 3;
              "browser.tabs.inTitlebar" = 0;
              "browser.toolbars.bookmarks.showOtherBookmarks" = false;
              "browser.toolbars.bookmarks.visibility" = "always";
              "browser.uidensity" = 1;
              "browser.uiCustomization.state" =
                {
                  "currentVersion" = 20;
                  "dirtyAreaCache" =
                    [
                      "PersonalToolbar"
                      "TabsToolbar"
                      "nav-bar"
                      "toolbar-menubar"
                      "unified-extensions-area"
                      "widget-overflow-fixed-list"
                    ];
                  "newElementCount" = 10;
                  "placements" =
                    {
                      "nav-bar" =
                        [
                          "back-button"
                          "forward-button"
                          "downloads-button"
                          "stop-reload-button"
                          "urlbar-container"
                          "search-container"
                          "fxa-toolbar-menu-button"
                          "reset-pbm-toolbar-button"
                          "unified-extensions-button"
                        ];
                      "PersonalToolbar" =
                        [
                          "sidebar-button"
                          "_73a6fe31-595d-460b-a920-fcc0f8843232_-browser-action" # noscript
                          "ublock0_raymondhill_net-browser-action"
                          "cookieautodelete_kennydo_com-browser-action"
                          "addon_darkreader_org-browser-action"
                          "personal-bookmarks"
                          "offline-qr-code_rugk_github_io-browser-action"
                          "_a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7_-browser-action" # user agent switcher
                          "printedit-we_dw-dev-browser-action"
                          "developer-button"
                          "zoompage-we_dw-dev-browser-action"
                          "zoom-controls"
                          "managed-bookmarks"
                        ];
                      "toolbar-menubar" =
                        [
                          "menubar-items"
                        ];
                      "TabsToolbar" =
                        [
                          "tabbrowser-tabs"
                          "new-tab-button"
                          "sync-button"
                          "simple-tab-groups_drive4ik-browser-action"
                          "treestyletab_piro_sakura_ne_jp-browser-action"
                          "alltabs-button"
                        ];
                      "unified-extensions-area" =
                        [
                          "sponsorblocker_ajay_app-browser-action"
                          "_ddc62400-f22d-4dd3-8b4a-05837de53c2e_-browser-action" # read aloud
                          "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action" # vimium
                          "_tst-search-browser-action"
                          "redirector_einaregilsson_com-browser-action"
                          "_0d7cafdd-501c-49ca-8ebb-e3341caaa55e_-browser-action" # youtube nonstop
                          "_e855175b-f84a-429d-85d6-a61831c8291c_-browser-action" # tab retitle
                          "firemonkey_eros_man-browser-action"
                          "foxytab_eros_man-browser-action"
                          "jid0-bnmfwww2w2w4e4edvcddbnmhdvg_jetpack-browser-action" # tab reloader
                          "jid1-bofifl9vbdl2zq_jetpack-browser-action" # decentraleyes
                          "jid1-kkzogwgsw3ao4q_jetpack-browser-action" # i don't care about cookies
                          "_506e023c-7f2b-40a3-8066-bc5deb40aebe_-browser-action" # gesturfy
                          "_7a7a4a92-a2a0-41d1-9fd7-1e92480d612d_-browser-action" # stylus
                        ];
                      "widgets-overflow-fixed-list" = [];
                    };
                };
              "browser.urlbar.matchBuckets" = "general:5 =suggestion:Infinity";
              "browser.urlbar.quicksuggest.dataCollection.enabled" = false;
              "browser.urlbar.quicksuggest.nonsponsored" = false;
              "browser.urlbar.quicksuggest.scenario" = "offline";
              "browser.urlbar.quicksuggest.sponsored" = false;
              "browser.urlbar.scotchBonnet.enableOverride" = false;
              "browser.urlbar.showSearchSuggestionsFirst" = false;
              "browser.urlbar.suggest.engines" = false;
              "browser.urlbar.suggest.pocket" = false;
              "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
              "browser.urlbar.suggest.quicksuggest.sponsored" = false;
              "browser.urlbar.suggest.searches" = false;
              "devtools.chrome.enabled" = true;
              "devtools.theme" = "auto";
              "dom.forms.autocomplete.formautofill" = true;
              "extensions.formautofill.CreditCards.enabled" = false;
              "extensions.pocket.enabled" = false;
              "extensions.pocket.showHome" = false;
              "findbar.highlightAll" = true;
              "general.smoothScroll" = true;
              "network.dns.disablePrefetch" = true;
              "network.predictor.enabled" = false;
              "network.prefetch-next" = false;
              "network.trr.uri" = "https://mozilla.cloudflare-dns.com/dns-query";
              "privacy.firstparty.isolate" = true;
              "signon.firefoxRelay.feature" = "disabled";
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "trailhead.firstrun.didSeeAboutWelcome" = true;
              "ui.context_menus.after_mouseup" = true;
            };
          extensions.packages = with firefox-addons;
            [
              # These unfree extensions cannot be installed due to bug
              # https://gitlab.com/rycee/nur-expressions/-/issues/244
              # enhancer-for-youtube
              # flagfox
              # scroll_anywhere
              cookie-autodelete
              darkreader
              decentraleyes
              firemonkey
              foxytab
              gesturefy
              i-dont-care-about-cookies
              noscript
              offline-qr-code-generator
              print-edit-we
              read-aloud
              redirector
              simple-tab-groups
              sponsorblock
              stylus
              tab-reloader
              tab-retitle
              tab-session-manager
              tree-style-tab
              tst-tab-search
              ublock-origin
              user-agent-string-switcher
              vimium
              youtube-nonstop
              zoom-page-we
            ];
          userContent =
            ''
              @-moz-document unobservable-document() {
                @media (prefers-color-scheme: dark) {
                  .pdfViewer {
                    filter: invert(100%);
                  }
                }
              }
            '';
        };
    };
}
