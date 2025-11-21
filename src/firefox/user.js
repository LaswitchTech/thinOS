// Force dark mode UI and content
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
user_pref("browser.theme.content-theme", 0);
user_pref("browser.theme.toolbar-theme", 0);

// Startup & home/new tab behavior: keep it as bare as possible
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtabpage.activity-stream.enabled", false);

// Hide bookmarks toolbar
user_pref("browser.toolbars.bookmarks.visibility", "never");

// URL bar / search suggestions: disable everything we reasonably can
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.searches", false);
user_pref("browser.urlbar.suggest.history", false);
user_pref("browser.urlbar.suggest.bookmark", false);
user_pref("browser.urlbar.suggest.openpage", false);
user_pref("browser.urlbar.suggest.topsites", false);
user_pref("browser.urlbar.suggest.engines", false);
user_pref("browser.urlbar.suggest.trending", false);
user_pref("browser.urlbar.quicksuggest.enabled", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);

// Disable top sites and highlights on new tab (if activity stream ever re-enables)
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeBookmarks", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeDownloads", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includePocket", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeVisited", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);

// Clear history / cookies / cache / form data on exit
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.cookies", true);
user_pref("privacy.clearOnShutdown.downloads", true);
user_pref("privacy.clearOnShutdown.formdata", true);
user_pref("privacy.clearOnShutdown.history", true);
user_pref("privacy.clearOnShutdown.offlineApps", true);
user_pref("privacy.clearOnShutdown.sessions", true);
user_pref("privacy.clearOnShutdown.siteSettings", false); // keep site settings off by default

// Also treat cookies as session-only
user_pref("network.cookie.lifetimePolicy", 2);

// Disable Firefox Account / Sync
user_pref("identity.fxaccounts.enabled", false);
user_pref("services.sync.engine.bookmarks", false);
user_pref("services.sync.engine.history", false);
user_pref("services.sync.engine.passwords", false);
user_pref("services.sync.engine.tabs", false);
user_pref("services.sync.engine.prefs", false);
user_pref("services.sync.engine.addons", false);

// Disable installing/running user extensions as much as possible
// 1 = app; 2 = system; 4 = profile; 8 = user
// Keeping only app+system (no profile/user extensions)
user_pref("extensions.enabledScopes", 3);
user_pref("xpinstall.enabled", false);

// Disable recommendations / random stories / Pocket integration
user_pref("browser.newtabpage.activity-stream.feeds.discoverystreamfeed", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includePocket", false);
user_pref("extensions.pocket.enabled", false);

// Misc privacy hardening related to suggestions
user_pref("browser.urlbar.suggest.mdn", false);
user_pref("browser.urlbar.suggest.weather", false);
user_pref("browser.urlbar.suggest.yelp", false);
user_pref("browser.urlbar.suggest.bestmatch", false);

// Optional: disable telemetry / studies for a quieter thin client
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("app.shield.optoutstudies.enabled", false);

// Force direct connection (no proxy of any kind)
user_pref("network.proxy.type", 0); // 0 = no proxy, 5 = use system proxy
user_pref("network.proxy.share_proxy_settings", false);
user_pref("network.proxy.no_proxies_on", "localhost, 127.0.0.1");

// Disable DNS-over-HTTPS / TRR to avoid third-party resolvers
user_pref("network.trr.mode", 5);        // 5 = off
user_pref("network.trr.uri", "");
user_pref("network.trr.custom_uri", "");
user_pref("network.trr.confirmationNS", "");
user_pref("doh-rollout.enabled", false);
user_pref("doh-rollout.mode", 5);

// Reduce speculative/background network traffic where possible
user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("browser.newtab.preload", false);
user_pref("network.captive-portal-service.enabled", false);
user_pref("captivedetect.canonicalURL", "");

// Optional: disable Safe Browsing to avoid external checks (trades security for isolation)
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);
