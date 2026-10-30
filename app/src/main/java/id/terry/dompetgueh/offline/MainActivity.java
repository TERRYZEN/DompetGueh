package id.terry.dompetgueh.offline;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import org.json.JSONObject;
import java.io.ByteArrayInputStream;
import java.util.Collections;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public final class MainActivity extends Activity {
    private WebView web;
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private static final String HOST = "appassets.androidplatform.net";

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setStatusBarColor(Color.rgb(247, 248, 252));
        getWindow().setNavigationBarColor(Color.rgb(247, 248, 252));
        getWindow().getDecorView().setSystemUiVisibility(android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR |
            android.view.View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR);
        final SharedPreferences prefs = getSharedPreferences("dompetgueh_data", MODE_PRIVATE);
        final FinanceEngine engine = new FinanceEngine(new FinanceEngine.Store() {
            @Override public String read() { return prefs.getString("database", ""); }
            @Override public boolean write(String json) { return prefs.edit().putString("database", json).commit(); }
        });
        web = new WebView(this);
        web.setBackgroundColor(Color.rgb(247, 248, 252));
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(false);
        s.setAllowContentAccess(false);
        s.setAllowFileAccessFromFileURLs(false);
        s.setAllowUniversalAccessFromFileURLs(false);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        s.setBlockNetworkLoads(true);
        s.setSupportMultipleWindows(false);
        s.setTextZoom(100);
        if (Build.VERSION.SDK_INT >= 29) s.setForceDark(WebSettings.FORCE_DARK_OFF);
        web.setWebChromeClient(new WebChromeClient());
        web.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest req) {
                return !local(req.getUrl());
            }
            @Override public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest req) {
                Uri uri = req.getUrl();
                if (local(uri)) {
                    String path = uri.getPath().substring("/assets/".length());
                    if (!path.contains("..") && !path.contains("\\")) {
                        try {
                            String mime = path.endsWith(".css") ? "text/css" : path.endsWith(".js") ?
                                "application/javascript" : path.endsWith(".woff2") ? "font/woff2" :
                                path.endsWith(".ttf") ? "font/ttf" : "text/html";
                            return new WebResourceResponse(mime, "UTF-8", 200, "OK",
                                Collections.singletonMap("Cache-Control", "no-cache"), getAssets().open(path));
                        } catch (Exception ignored) { }
                    }
                }
                return new WebResourceResponse("text/plain", "UTF-8", 404, "Not Found",
                    Collections.<String, String>emptyMap(), new ByteArrayInputStream(new byte[0]));
            }
        });
        web.addJavascriptInterface(new Object() {
            @JavascriptInterface public void request(final String id, final String path, final String method, final String body) {
                if (!id.matches("[0-9]+")) return;
                worker.execute(new Runnable() { @Override public void run() {
                    final String response = engine.request(path, method, body);
                    runOnUiThread(new Runnable() { @Override public void run() {
                        if (!isDestroyed()) web.evaluateJavascript("window.__nativeResolve(" + JSONObject.quote(id) + "," + response + ")", null);
                    }});
                }});
            }
            @JavascriptInterface public void copy(final String text) {
                runOnUiThread(new Runnable() { @Override public void run() {
                    ClipboardManager clipboard = (ClipboardManager)getSystemService(CLIPBOARD_SERVICE);
                    clipboard.setPrimaryClip(ClipData.newPlainText("Kode pemulihan DompetGueh", text));
                }});
            }
        }, "DompetNative");
        setContentView(web);
        web.loadUrl("https://" + HOST + "/assets/index.html");
    }

    private boolean local(Uri uri) {
        return "https".equals(uri.getScheme()) && HOST.equals(uri.getHost()) && uri.getPath() != null && uri.getPath().startsWith("/assets/");
    }

    @Override public void onBackPressed() {
        web.evaluateJavascript("(function(){var modal=document.querySelector('.modal-backdrop.show');" +
            "if(modal){modal.classList.remove('show');modal.setAttribute('aria-hidden','true');document.body.classList.remove('modal-open');return 'handled';}" +
            "if(!document.getElementById('pinScreen').classList.contains('pin-hidden'))return 'exit';" +
            "if(document.getElementById('historiView').classList.contains('active-view')){tampilkanHalaman('dashboard');return 'handled';}return 'exit';})()",
            new android.webkit.ValueCallback<String>() { @Override public void onReceiveValue(String value) {
                if ("\"exit\"".equals(value)) finish();
            }});
    }

    @Override protected void onDestroy() {
        worker.shutdown();
        if (web != null) { web.removeJavascriptInterface("DompetNative"); web.destroy(); }
        super.onDestroy();
    }
}
