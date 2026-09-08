package ci.agnebytiassa.tourisme;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
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

    @SuppressLint("SetJavaScriptEnabled")
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

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int newProgress) {
                progressBar.setProgress(newProgress);
                progressBar.setVisibility(newProgress < 100 ? View.VISIBLE : View.GONE);
            }
        });

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                super.onPageStarted(view, url, favicon);
                progressBar.setVisibility(View.VISIBLE);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                progressBar.setVisibility(View.GONE);
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
        findViewById(R.id.navContact).setOnClickListener(v -> webView.loadUrl(CONTACT_URL));

        findViewById(R.id.btnReload).setOnClickListener(v -> webView.reload());
        findViewById(R.id.btnShare).setOnClickListener(v -> shareWebsite());
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
            webView.destroy();
        }
        super.onDestroy();
    }
}
