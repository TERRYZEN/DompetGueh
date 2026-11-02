package id.terry.dompetgueh.offline;

import org.json.JSONArray;
import org.json.JSONObject;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Locale;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/** Local equivalent of the original Flask API. No network or Python runtime. */
public final class FinanceEngine {
    public interface Store {
        String read();
        boolean write(String json);
    }
    private final Store store;
    private final SecureRandom random = new SecureRandom();
    private boolean unlocked;
    private long lastId;
    private static final long MAX = 9007199254740991L;
    private static final String[] EXPENSE = {"Makanan", "Transportasi", "Pendidikan", "Hiburan", "Kebutuhan", "Lainnya"};
    private static final String[] INCOME = {"Gaji", "Freelance", "Bonus", "Investasi", "Lainnya"};

    public FinanceEngine(Store store) { this.store = store; }

    public synchronized String request(String path, String method, String body) {
        try {
            return new JSONObject().put("ok", true).put("result", route(path, method, new JSONObject(body))).toString();
        } catch (ApiError e) {
            return error(e.getMessage());
        } catch (Exception e) {
            return error("Data tidak dapat diproses atau disimpan. Silakan coba lagi.");
        }
    }

    private String error(String message) {
        try { return new JSONObject().put("ok", false).put("pesan", message).toString(); }
        catch (Exception e) { return "{\"ok\":false,\"pesan\":\"Terjadi kesalahan.\"}"; }
    }

    private JSONObject load() throws Exception {
        String saved = store.read();
        if (saved != null && !saved.isEmpty()) return new JSONObject(saved);
        return new JSONObject().put("anggaran", 0).put("pengeluaran", new JSONArray())
            .put("pemasukan", new JSONArray()).put("pin_hash", "").put("recovery_hash", "")
            .put("nama_pengguna", "Pengguna");
    }

    private void save(JSONObject d) throws Exception {
        if (!store.write(d.toString())) throw new ApiError("Penyimpanan gagal. Periksa ruang penyimpanan HP.");
    }

    private JSONObject publicData(JSONObject d) throws Exception {
        return new JSONObject().put("anggaran", d.getLong("anggaran"))
            .put("pengeluaran", d.getJSONArray("pengeluaran"))
            .put("pemasukan", d.getJSONArray("pemasukan"))
            .put("nama_pengguna", d.getString("nama_pengguna"));
    }

    private JSONObject message(String text) throws Exception { return new JSONObject().put("pesan", text); }

    private JSONObject result(String text, JSONObject d) throws Exception {
        save(d);
        return message(text).put("data", publicData(d));
    }

    private void validPin(String pin) throws ApiError {
        if (!pin.matches("[0-9]{4,8}")) throw new ApiError("PIN harus terdiri dari 4 sampai 8 angka.");
    }

    private String hex(byte[] b) {
        StringBuilder s = new StringBuilder();
        for (byte value : b) s.append(String.format(Locale.ROOT, "%02x", value & 255));
        return s.toString();
    }

    private byte[] unhex(String s) {
        byte[] b = new byte[s.length() / 2];
        for (int i = 0; i < b.length; i++) b[i] = (byte)Integer.parseInt(s.substring(i * 2, i * 2 + 2), 16);
        return b;
    }

    private byte[] derive(String pin, byte[] salt) throws Exception {
        PBEKeySpec spec = new PBEKeySpec(pin.toCharArray(), salt, 260000, 256);
        try { return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).getEncoded(); }
        finally { spec.clearPassword(); }
    }

    private String hashPin(String pin) throws Exception {
        byte[] salt = new byte[16]; random.nextBytes(salt);
        return hex(salt) + "$" + hex(derive(pin, salt));
    }

    private boolean matchesPin(String pin, String saved) throws Exception {
        if (!pin.matches("[0-9]{4,8}")) return false;
        String[] parts = saved.split("\\$");
        return parts.length == 2 && MessageDigest.isEqual(unhex(parts[1]), derive(pin, unhex(parts[0])));
    }

    private String digest(String text) throws Exception {
        return hex(MessageDigest.getInstance("SHA-256").digest(text.getBytes("UTF-8")));
    }

    private String recovery(JSONObject d) throws Exception {
        byte[] bytes = new byte[12]; random.nextBytes(bytes);
        String code = hex(bytes).toUpperCase(Locale.ROOT);
        d.put("recovery_hash", digest(code));
        StringBuilder formatted = new StringBuilder();
        for (int i = 0; i < 24; i += 4) {
            if (i > 0) formatted.append('-');
            formatted.append(code.substring(i, i + 4));
        }
        return formatted.toString();
    }

    private long amount(JSONObject body, String key, boolean zero) throws Exception {
        try {
            java.math.BigDecimal n = new java.math.BigDecimal(body.get(key).toString());
            long value = n.longValueExact();
            if (value < (zero ? 0 : 1) || value > MAX) throw new ArithmeticException();
            return value;
        } catch (Exception e) {
            throw new ApiError(zero ? "Anggaran harus berupa angka nol atau lebih." : "Jumlah harus lebih dari Rp0 dan berupa bilangan bulat.");
        }
    }

    private long plus(long a, long b) throws ApiError {
        if (a > MAX - b) throw new ApiError("Total nominal terlalu besar.");
        return a + b;
    }

    private JSONObject transaction(JSONObject b, boolean expense) throws Exception {
        String date = b.optString("tanggal", "").trim();
        try {
            SimpleDateFormat f = new SimpleDateFormat("yyyy-MM-dd", Locale.ROOT);
            f.setLenient(false);
            if (!date.matches("[0-9]{4}-[0-9]{2}-[0-9]{2}") || !f.format(f.parse(date)).equals(date)) throw new Exception();
        } catch (Exception e) { throw new ApiError("Tanggal atau jumlah tidak valid."); }
        String name = b.optString("nama", "").trim();
        if (name.isEmpty()) throw new ApiError("Nama wajib diisi.");
        String category = b.optString("kategori", "").trim();
        if (!Arrays.asList(expense ? EXPENSE : INCOME).contains(category)) {
            if (expense) throw new ApiError("Kategori tidak valid.");
            category = "Lainnya";
        }
        long id = Math.max(System.currentTimeMillis() * 1000 + random.nextInt(1000), lastId + 1);
        lastId = id;
        return new JSONObject().put("id", id).put("tanggal", date).put("nama", name)
            .put("kategori", category).put("jumlah", amount(b, "jumlah", false));
    }

    private JSONObject route(String path, String method, JSONObject b) throws Exception {
        JSONObject d = load();
        String hash = d.optString("pin_hash", "");
        if (path.equals("/api/pin/status") && method.equals("GET"))
            return new JSONObject().put("perlu_setup", hash.isEmpty()).put("terbuka", !hash.isEmpty() && unlocked);
        if (path.equals("/api/pin/lock") && method.equals("POST")) {
            unlocked = false;
            return message("Aplikasi dikunci.");
        }
        if (path.equals("/api/pin/setup") && method.equals("POST")) {
            if (!hash.isEmpty()) throw new ApiError("PIN sudah dibuat. Masukkan PIN untuk membuka aplikasi.");
            String pin = b.optString("pin", ""); validPin(pin);
            d.put("pin_hash", hashPin(pin));
            String code = recovery(d);
            save(d); unlocked = true;
            return message("PIN berhasil dibuat.").put("kode_pemulihan", code);
        }
        if (path.equals("/api/pin/unlock") && method.equals("POST")) {
            if (hash.isEmpty()) throw new ApiError("Buat PIN terlebih dahulu.");
            if (!matchesPin(b.optString("pin", ""), hash)) throw new ApiError("PIN salah. Silakan coba lagi.");
            unlocked = true;
            return message("Aplikasi berhasil dibuka.");
        }
        if (path.equals("/api/pin/reset") && method.equals("POST")) {
            if (hash.isEmpty()) throw new ApiError("Buat PIN baru terlebih dahulu.");
            String pin = b.optString("pin_baru", ""); validPin(pin);
            String code = b.optString("kode_pemulihan", "").replaceAll("[\\s-]", "").toUpperCase(Locale.ROOT);
            if (d.optString("recovery_hash", "").isEmpty() || !MessageDigest.isEqual(
                digest(code).getBytes("UTF-8"), d.getString("recovery_hash").getBytes("UTF-8")))
                throw new ApiError("Kode pemulihan salah atau tidak tersedia.");
            d.put("pin_hash", hashPin(pin));
            String newCode = recovery(d);
            save(d); unlocked = true;
            return message("PIN baru berhasil dibuat.").put("kode_pemulihan", newCode);
        }
        if (!unlocked || hash.isEmpty()) throw new ApiError("Masukkan PIN terlebih dahulu.");
        if (path.equals("/api/data") && method.equals("GET")) return publicData(d);
        if (path.equals("/api/profil") && method.equals("PUT")) {
            String name = b.optString("nama", "").trim();
            if (name.isEmpty()) throw new ApiError("Nama tidak boleh kosong.");
            if (name.codePointCount(0, name.length()) > 40) throw new ApiError("Nama maksimal 40 karakter.");
            d.put("nama_pengguna", name);
            return result("Nama berhasil diperbarui.", d);
        }
        if (path.equals("/api/anggaran") && method.equals("PUT")) {
            long value = amount(b, "anggaran", true);
            boolean replace = b.optString("mode", "tambah").equals("ganti");
            if (replace) {
                JSONArray incomes = d.getJSONArray("pemasukan");
                for (int i = 0; i < incomes.length(); i++) incomes.getJSONObject(i).put("ditambahkan_ke_anggaran", false);
            } else value = plus(d.getLong("anggaran"), value);
            d.put("anggaran", value);
            return result(replace ? "Anggaran berhasil diganti." : "Anggaran berhasil ditambahkan.", d);
        }
        for (String kind : new String[]{"pengeluaran", "pemasukan"}) {
            boolean expense = kind.equals("pengeluaran");
            String prefix = "/api/" + kind;
            String label = expense ? "Pengeluaran" : "Pemasukan";
            JSONArray items = d.getJSONArray(kind);
            if (path.equals(prefix) && method.equals("POST")) {
                JSONObject item = transaction(b, expense);
                JSONArray next = new JSONArray().put(item);
                for (int i = 0; i < items.length(); i++) next.put(items.get(i));
                d.put(kind, next);
                if (!expense) {
                    item.put("ditambahkan_ke_anggaran", true);
                    d.put("anggaran", plus(d.getLong("anggaran"), item.getLong("jumlah")));
                }
                return result(label + " berhasil ditambahkan.", d);
            }
            if (path.startsWith(prefix + "/") && method.equals("DELETE")) {
                long id = Long.parseLong(path.substring(prefix.length() + 1));
                JSONArray next = new JSONArray(); JSONObject deleted = null;
                for (int i = 0; i < items.length(); i++) {
                    JSONObject item = items.getJSONObject(i);
                    if (item.getLong("id") == id) deleted = item; else next.put(item);
                }
                if (deleted == null) throw new ApiError("Data tidak ditemukan.");
                d.put(kind, next);
                if (!expense && deleted.optBoolean("ditambahkan_ke_anggaran", false))
                    d.put("anggaran", Math.max(0, d.getLong("anggaran") - deleted.getLong("jumlah")));
                return result(label + " berhasil dihapus.", d);
            }
        }
        throw new ApiError("Fitur tidak ditemukan.");
    }

    private static final class ApiError extends Exception {
        ApiError(String message) { super(message); }
    }
}
