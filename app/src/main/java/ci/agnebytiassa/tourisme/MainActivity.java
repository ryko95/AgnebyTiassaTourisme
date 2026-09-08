package ci.agnebytiassa.tourisme;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ProgressBar;
import android.widget.Toast;

public class MainActivity extends Activity {

    private static final String HOME_URL = "https://agnebytiassatourisme.com/";
    private static final String SITES_URL = "https://agnebytiassatourisme.com/sites";
    private static final String MAP_URL = "https://agnebytiassatourisme.com/carte";
    private static final String EXPERIENCES_URL = "https://agnebytiassatourisme.com/experiences";
    private static final String CONTACT_URL = "https://agnebytiassatourisme.com/contact";
    private static final String WHATSAPP_URL = "https://wa.me/2250546093940";

    private WebView webView;
    private ProgressBar progressBar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        webView = findViewById(R.id.webView);
        progressBar = findViewById(R.id.pageProgress);

        configureWebView();
        configureNavigation();

        if (savedInstanceState == null) {
            webView.loadUrl(HOME_URL);
        } else {
            webView.restoreState(savedInstanceState);
        }
    }

    @SuppressLint({"SetJavaScriptEnabled", "AddJavascriptInterface"})
    private void configureWebView() {
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setLoadWithOverviewMode(true);
        settings.setUseWideViewPort(true);
        settings.setBuiltInZoomControls(false);
        settings.setDisplayZoomControls(false);
        settings.setSupportZoom(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE);

        webView.addJavascriptInterface(new MobileBridge(), "AgnebyApp");

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int newProgress) {
                progressBar.setProgress(newProgress);
                progressBar.setVisibility(newProgress < 100 ? View.VISIBLE : View.GONE);
            }
        });

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageStarted(WebView view, String url, android.graphics.Bitmap favicon) {
                super.onPageStarted(view, url, favicon);
                progressBar.setVisibility(View.VISIBLE);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                progressBar.setVisibility(View.GONE);
                injectMobileEnhancements(view, url);
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return handleUrl(request.getUrl());
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return handleUrl(Uri.parse(url));
            }

            @Override
            public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
                super.onReceivedError(view, request, error);
                if (request.isForMainFrame()) {
                    showOfflinePage();
                }
            }
        });

        webView.setDownloadListener((url, userAgent, contentDisposition, mimetype, contentLength) -> openExternal(Uri.parse(url)));
    }

    private void injectMobileEnhancements(WebView view, String url) {
        if (url == null || !(url.startsWith("http://") || url.startsWith("https://"))) {
            return;
        }

        if (url.contains("/carte")) {
            view.postDelayed(() -> focusInteractiveMap(view), 450L);
        }

        view.postDelayed(() -> wireTouristSitesToGoogleMaps(view), 500L);
    }

    private void focusInteractiveMap(WebView view) {
        String script = "(function(){"
                + "var selectors=['.leaflet-container','#map','[id*=map i]','[class*=map i]','iframe'];"
                + "var found=null;"
                + "for(var s=0;s<selectors.length&&!found;s++){"
                + "var nodes=document.querySelectorAll(selectors[s]);"
                + "for(var i=0;i<nodes.length;i++){var r=nodes[i].getBoundingClientRect();if(r.height>220&&r.width>220){found=nodes[i];break;}}}"
                + "if(found){found.scrollIntoView({behavior:'auto',block:'start'});setTimeout(function(){window.scrollBy(0,-68);},80);}"
                + "})();";
        view.evaluateJavascript(script, null);
    }

    private void wireTouristSitesToGoogleMaps(WebView view) {
        String script = "(function(){"
                + "function txt(n){return ((n&&n.innerText)||'').replace(/\\s+/g,' ').trim();}"
                + "function titleOf(card){var t=card.querySelector('h1,h2,h3,h4,h5,strong,[class*=title i]');return txt(t)||txt(card).split('  ')[0];}"
                + "var sections=Array.prototype.slice.call(document.querySelectorAll('section,main,div')).filter(function(s){"
                + "var h=s.querySelector('h1,h2,h3');var v=txt(h);return /sites? (à ne pas manquer|incontournables)|découvrir.{0,20}sites?|nos sites/i.test(v);});"
                + "sections.forEach(function(sec){if(sec.dataset.mapsBridge==='1')return;sec.dataset.mapsBridge='1';"
                + "sec.addEventListener('click',function(e){"
                + "var card=e.target.closest('a,article,li,[class*=card i],[class*=site i]');if(!card||!sec.contains(card))return;"
                + "var t=titleOf(card);if(!t||/tous les sites|ouvrir la page|en détail|découvrir/i.test(t))return;"
                + "e.preventDefault();e.stopPropagation();if(window.AgnebyApp){window.AgnebyApp.openMapForSite(t);}},true);});"
                + "})();";
        view.evaluateJavascript(script, null);
    }

    private boolean handleUrl(Uri uri) {
        String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase();
        String host = uri.getHost() == null ? "" : uri.getHost().toLowerCase();

        if ("app".equals(scheme) && "retry".equals(host)) {
            webView.loadUrl(HOME_URL);
            return true;
        }

        if ("http".equals(scheme) || "https".equals(scheme)) {
            if (host.equals("agnebytiassatourisme.com") || host.endsWith(".agnebytiassatourisme.com")) {
                return false;
            }
            openExternal(uri);
            return true;
        }

        if ("tel".equals(scheme) || "mailto".equals(scheme) || "sms".equals(scheme)
                || "geo".equals(scheme) || "whatsapp".equals(scheme) || "intent".equals(scheme)) {
            openExternal(uri);
            return true;
        }
        return false;
    }

    private void openGoogleMaps(String siteName) {
        String cleanName = siteName == null ? "Site touristique" : siteName.replace("Voir sur la carte", "").trim();
        String query = cleanName + ", Agnéby-Tiassa, Côte d'Ivoire";
        Uri geoUri = Uri.parse("geo:0,0?q=" + Uri.encode(query));
        Intent mapsIntent = new Intent(Intent.ACTION_VIEW, geoUri);
        mapsIntent.setPackage("com.google.android.apps.maps");

        try {
            startActivity(mapsIntent);
        } catch (ActivityNotFoundException ignored) {
            Uri webMaps = Uri.parse("https://www.google.com/maps/search/?api=1&query=" + Uri.encode(query));
            openExternal(webMaps);
        }
    }

    private class MobileBridge {
        @JavascriptInterface
        public void openMapForSite(String siteName) {
            runOnUiThread(() -> openGoogleMaps(siteName));
        }
    }

    private void openExternal(Uri uri) {
        try {
            startActivity(new Intent(Intent.ACTION_VIEW, uri));
        } catch (ActivityNotFoundException ignored) {
            Toast.makeText(this, "Aucune application compatible n’est installée.", Toast.LENGTH_SHORT).show();
        }
    }

    private void configureNavigation() {
        findViewById(R.id.navHome).setOnClickListener(v -> webView.loadUrl(HOME_URL));
        findViewById(R.id.navSites).setOnClickListener(v -> webView.loadUrl(SITES_URL));
        findViewById(R.id.navMap).setOnClickListener(v -> webView.loadUrl(MAP_URL));
        findViewById(R.id.navExperiences).setOnClickListener(v -> webView.loadUrl(EXPERIENCES_URL));
        findViewById(R.id.navFeatured).setOnClickListener(v -> showFeaturedPage());
        findViewById(R.id.navMarketplace).setOnClickListener(v -> showMarketplacePage());
        findViewById(R.id.navContact).setOnClickListener(v -> webView.loadUrl(CONTACT_URL));

        findViewById(R.id.btnReload).setOnClickListener(v -> webView.reload());
        findViewById(R.id.btnShare).setOnClickListener(v -> shareWebsite());
    }

    private String baseLocalCss() {
        return "body{margin:0;font-family:Arial,sans-serif;background:#F4FBF1;color:#17351F;}"
                + ".hero{padding:28px 20px;background:linear-gradient(135deg,#BEE8B5,#FFF1DF);border-bottom:4px solid #F28C28;}"
                + ".hero h1{margin:0 0 8px;color:#256B35;font-size:28px}.hero p{margin:0;line-height:1.55}"
                + ".wrap{padding:18px}.card{background:#fff;border:1px solid #D9EDD7;border-radius:20px;padding:18px;margin-bottom:14px;box-shadow:0 6px 18px #00000012;}"
                + ".card h3{margin:0 0 8px;color:#256B35}.tag{display:inline-block;background:#FFF1DF;color:#B45B08;border-radius:999px;padding:6px 10px;font-size:12px;font-weight:bold;margin-bottom:10px;}"
                + ".btn{display:inline-block;margin-top:10px;background:#F28C28;color:#fff;text-decoration:none;padding:12px 16px;border-radius:999px;font-weight:bold;}"
                + ".btn.green{background:#256B35}.muted{color:#647067;font-size:13px;line-height:1.45}.grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;}"
                + "@media(max-width:520px){.grid{grid-template-columns:1fr}.hero h1{font-size:25px}}";
    }

    private void showFeaturedPage() {
        String html = "<!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1'>"
                + "<style>" + baseLocalCss() + "</style></head><body>"
                + "<div class='hero'><div class='tag'>À LA UNE</div><h1>Activités & temps forts</h1>"
                + "<p>Une rubrique pensée pour mettre en avant les sorties, visites, événements culturels et expériences du moment dans l’Agnéby-Tiassa.</p></div>"
                + "<div class='wrap'><div class='grid'>"
                + "<div class='card'><h3>🌿 Nature & découverte</h3><p>Excursions, sites naturels, fleuve Bandama, barrage et découvertes de terrain.</p><a class='btn' href='" + EXPERIENCES_URL + "'>Voir les expériences</a></div>"
                + "<div class='card'><h3>🎭 Culture & patrimoine</h3><p>Patrimoine local, mémoire, traditions, villages et rendez-vous culturels à valoriser.</p><a class='btn green' href='" + SITES_URL + "'>Découvrir les sites</a></div>"
                + "</div><div class='card'><h3>Recevoir les prochaines annonces</h3><p class='muted'>Les activités datées pourront être ajoutées ici au fur et à mesure. Le bouton ci-dessous permet déjà de contacter l’équipe tourisme pour connaître les prochains rendez-vous.</p>"
                + "<a class='btn' href='" + WHATSAPP_URL + "?text=Bonjour%2C%20je%20souhaite%20conna%C3%AEtre%20les%20activit%C3%A9s%20%C3%A0%20la%20une%20dans%20l%27Agn%C3%A9by-Tiassa.'>Demander le programme</a></div></div></body></html>";
        webView.loadDataWithBaseURL("https://agnebytiassatourisme.com/app/featured", html, "text/html", "UTF-8", null);
    }

    private void showMarketplacePage() {
        String html = "<!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1'>"
                + "<style>" + baseLocalCss() + "</style></head><body>"
                + "<div class='hero'><div class='tag'>MARKETPLACE</div><h1>Le marché touristique local</h1>"
                + "<p>Un espace pour connecter visiteurs, guides, artisans, producteurs, hébergeurs et restaurateurs de l’Agnéby-Tiassa.</p></div>"
                + "<div class='wrap'><div class='grid'>"
                + "<div class='card'><h3>🧭 Guides & circuits</h3><p>Organiser une visite, trouver un guide local ou préparer un circuit sur mesure.</p></div>"
                + "<div class='card'><h3>🧺 Produits du terroir</h3><p>Mettre en avant les productions locales, saveurs et spécialités de la région.</p></div>"
                + "<div class='card'><h3>🎨 Artisanat local</h3><p>Valoriser les créateurs, objets artisanaux et savoir-faire des communautés.</p></div>"
                + "<div class='card'><h3>🏡 Hébergement & restauration</h3><p>Faciliter la mise en relation avec les offres d’accueil et de restauration.</p></div>"
                + "</div><div class='card'><h3>Vous souhaitez proposer une offre ?</h3><p class='muted'>Cette première version sert de vitrine. Les vendeurs et prestataires pourront ensuite disposer de fiches dédiées, photos, contacts et localisation.</p>"
                + "<a class='btn' href='" + WHATSAPP_URL + "?text=Bonjour%2C%20je%20souhaite%20%C3%AAtre%20r%C3%A9f%C3%A9renc%C3%A9%20sur%20la%20Marketplace%20Agn%C3%A9by-Tiassa%20Tourisme.'>Être référencé</a></div></div></body></html>";
        webView.loadDataWithBaseURL("https://agnebytiassatourisme.com/app/marketplace", html, "text/html", "UTF-8", null);
    }

    private void shareWebsite() {
        Intent share = new Intent(Intent.ACTION_SEND);
        share.setType("text/plain");
        share.putExtra(Intent.EXTRA_SUBJECT, getString(R.string.share_title));
        share.putExtra(Intent.EXTRA_TEXT, getString(R.string.share_text));
        startActivity(Intent.createChooser(share, "Partager l’Agnéby-Tiassa"));
    }

    private void showOfflinePage() {
        String html = "<!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1'>"
                + "<style>body{font-family:sans-serif;background:#F4FBF1;color:#17351F;text-align:center;padding:55px 22px}"
                + ".card{background:white;border-radius:22px;padding:30px 20px;box-shadow:0 6px 24px #00000018}"
                + "h2{color:#256B35}a{display:inline-block;margin-top:18px;background:#F28C28;color:white;text-decoration:none;"
                + "padding:13px 24px;border-radius:28px;font-weight:bold}</style></head><body><div class='card'>"
                + "<div style='font-size:48px'>🌿</div><h2>Connexion indisponible</h2>"
                + "<p>Vérifiez votre connexion Internet pour continuer la découverte de l’Agnéby-Tiassa.</p>"
                + "<a href='app://retry'>Réessayer</a></div></body></html>";
        webView.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null);
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        webView.saveState(outState);
        super.onSaveInstanceState(outState);
    }

    @Override
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) {
            webView.goBack();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    protected void onDestroy() {
        if (webView != null) {
            webView.stopLoading();
            webView.removeJavascriptInterface("AgnebyApp");
            webView.destroy();
        }
        super.onDestroy();
    }
}
