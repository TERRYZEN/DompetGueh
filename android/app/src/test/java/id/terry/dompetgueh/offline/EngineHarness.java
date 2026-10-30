package id.terry.dompetgueh.offline;
import id.terry.dompetgueh.offline.FinanceEngine;
import org.json.*;
import java.io.*;
public final class EngineHarness {
    static final class MemoryStore implements FinanceEngine.Store {
        String value=""; boolean fail;
        public String read(){return value;}
        public boolean write(String v){if(fail)return false;value=v;return true;}
    }
    static MemoryStore store=new MemoryStore();
    static FinanceEngine engine=new FinanceEngine(store);
    static int checks=0;
    static JSONObject raw(String path,String method,String body)throws Exception{return new JSONObject(engine.request(path,method,body));}
    static JSONObject call(String path,String method,String body)throws Exception{
        JSONObject r=raw(path,method,body);if(!r.getBoolean("ok"))throw new AssertionError(r.toString());return r.getJSONObject("result");
    }
    static void check(boolean b)throws Exception{checks++;if(!b)throw new AssertionError("check "+checks);}
    static void fail(String p,String m,String b)throws Exception{check(!raw(p,m,b).getBoolean("ok"));}
    public static void main(String[]args)throws Exception{
        if(args.length>0&&args[0].equals("--server")){
            BufferedReader reader=new BufferedReader(new InputStreamReader(System.in,"UTF-8"));String line;
            while((line=reader.readLine())!=null){
                JSONObject q=new JSONObject(line);
                if(q.optString("path").equals("__restart")){engine=new FinanceEngine(store);System.out.println("{\"ok\":true}");continue;}
                System.out.println(engine.request(q.getString("path"),q.optString("method","GET"),q.optString("body","{}")));
            }return;
        }
        check(call("/api/pin/status","GET","{}").getBoolean("perlu_setup"));
        fail("/api/data","GET","{}");
        fail("/api/pin/setup","POST","{\"pin\":\"12ab\"}");
        String code=call("/api/pin/setup","POST","{\"pin\":\"1234\"}").getString("kode_pemulihan");
        check(code.matches("[A-F0-9]{4}(-[A-F0-9]{4}){5}"));
        check(!store.value.contains("1234")&&!store.value.contains(code.replace("-","")));
        check(call("/api/data","GET","{}").getLong("anggaran")==0);
        fail("/api/pin/setup","POST","{\"pin\":\"2222\"}");
        check(call("/api/anggaran","PUT","{\"anggaran\":100000,\"mode\":\"tambah\"}").getJSONObject("data").getLong("anggaran")==100000);
        JSONObject d=call("/api/pemasukan","POST","{\"nama\":\"Gaji\",\"tanggal\":\"2026-10-27\",\"kategori\":\"Gaji\",\"jumlah\":5000000}").getJSONObject("data");
        check(d.getLong("anggaran")==5100000);long income=d.getJSONArray("pemasukan").getJSONObject(0).getLong("id");
        d=call("/api/pengeluaran","POST","{\"nama\":\"Makan\",\"tanggal\":\"2026-10-27\",\"kategori\":\"Makanan\",\"jumlah\":25000}").getJSONObject("data");
        check(d.getJSONArray("pengeluaran").length()==1&&d.getLong("anggaran")==5100000);
        long expense=d.getJSONArray("pengeluaran").getJSONObject(0).getLong("id");
        fail("/api/pengeluaran","POST","{\"nama\":\"Invalid\",\"tanggal\":\"2026-02-31\",\"kategori\":\"Makanan\",\"jumlah\":100}");
        fail("/api/pengeluaran","POST","{\"nama\":\"Invalid\",\"tanggal\":\"2026-10-27\",\"kategori\":\"Makanan\",\"jumlah\":-1}");
        fail("/api/pengeluaran","POST","{\"nama\":\"Invalid\",\"tanggal\":\"2026-10-27\",\"kategori\":\"bad\",\"jumlah\":100}");
        fail("/api/anggaran","PUT","{\"anggaran\":-1}");
        fail("/api/profil","PUT","{\"nama\":\"\"}");
        check(call("/api/profil","PUT","{\"nama\":\"Terry\"}").getJSONObject("data").getString("nama_pengguna").equals("Terry"));
        d=call("/api/pengeluaran/"+expense,"DELETE","{}").getJSONObject("data");check(d.getJSONArray("pengeluaran").length()==0);
        fail("/api/pengeluaran/"+expense,"DELETE","{}");
        d=call("/api/pemasukan/"+income,"DELETE","{}").getJSONObject("data");check(d.getLong("anggaran")==100000);
        d=call("/api/pemasukan","POST","{\"nama\":\"Bonus\",\"tanggal\":\"2026-10-27\",\"kategori\":\"Bonus\",\"jumlah\":20000}").getJSONObject("data");income=d.getJSONArray("pemasukan").getJSONObject(0).getLong("id");
        call("/api/anggaran","PUT","{\"anggaran\":50000,\"mode\":\"ganti\"}");
        d=call("/api/pemasukan/"+income,"DELETE","{}").getJSONObject("data");check(d.getLong("anggaran")==50000);
        engine=new FinanceEngine(store);check(!call("/api/pin/status","GET","{}").getBoolean("terbuka"));
        fail("/api/data","GET","{}");fail("/api/pin/unlock","POST","{\"pin\":\"9999\"}");
        call("/api/pin/unlock","POST","{\"pin\":\"1234\"}");
        check(call("/api/data","GET","{}").getString("nama_pengguna").equals("Terry"));
        call("/api/pin/lock","POST","{}");fail("/api/data","GET","{}");
        fail("/api/pin/reset","POST","{\"pin_baru\":\"5678\",\"kode_pemulihan\":\"wrong\"}");
        String next=call("/api/pin/reset","POST",new JSONObject().put("pin_baru","5678").put("kode_pemulihan",code.toLowerCase()).toString()).getString("kode_pemulihan");
        check(!next.equals(code));
        fail("/api/pin/reset","POST",new JSONObject().put("pin_baru","9999").put("kode_pemulihan",code).toString());
        call("/api/pin/lock","POST","{}");fail("/api/pin/unlock","POST","{\"pin\":\"1234\"}");call("/api/pin/unlock","POST","{\"pin\":\"5678\"}");
        store.fail=true;fail("/api/anggaran","PUT","{\"anggaran\":80000,\"mode\":\"ganti\"}");store.fail=false;
        check(call("/api/data","GET","{}").getLong("anggaran")==50000);
        System.out.println("PASS: "+checks+" backend checks (PIN, recovery, persistence, money, deletion, profile, failed saves).");
    }
}
