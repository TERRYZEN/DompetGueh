package id.terry.dompetgueh.offline;

import android.content.SharedPreferences;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** Flutter renders every screen; this channel only accesses private local data. */
public final class MainActivity extends FlutterActivity {
    private final ExecutorService worker = Executors.newSingleThreadExecutor();

    @Override public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        // Same storage name and key as the preceding offline APK, to retain data on update.
        final SharedPreferences prefs = getSharedPreferences("dompetgueh_data", MODE_PRIVATE);
        final SharedPreferences ui = getSharedPreferences("dompetgueh_flutter_ui", MODE_PRIVATE);
        final FinanceEngine engine = new FinanceEngine(new FinanceEngine.Store() {
            @Override public String read() { return prefs.getString("database", ""); }
            @Override public boolean write(String json) { return prefs.edit().putString("database", json).commit(); }
        });
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "id.terry.dompetgueh/local")
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("preferences")) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("dark", ui.getBoolean("dark", false));
                    map.put("hideBudget", ui.getBoolean("hideBudget", false));
                    result.success(map);
                } else if (call.method.equals("savePreferences")) {
                    final Boolean dark = call.argument("dark"), hidden = call.argument("hideBudget");
                    worker.execute(() -> {
                        final boolean saved = ui.edit().putBoolean("dark", Boolean.TRUE.equals(dark))
                            .putBoolean("hideBudget", Boolean.TRUE.equals(hidden)).commit();
                        runOnUiThread(() -> result.success(saved));
                    });
                } else if (call.method.equals("request")) {
                    final String path = call.argument("path"), method = call.argument("method"), body = call.argument("body");
                    if (path == null || method == null || body == null) {
                        result.error("INVALID_ARGUMENT", "Permintaan tidak valid.", null);
                        return;
                    }
                    worker.execute(() -> {
                        final String response = engine.request(path, method, body);
                        runOnUiThread(() -> result.success(response));
                    });
                } else result.notImplemented();
            });
    }

    @Override protected void onDestroy() {
        worker.shutdown();
        super.onDestroy();
    }
}
