/*
 * DOMPETKU - SCRIPT.JS
 * Panduan edit cepat:
 * - Ubah ikon/warna kategori pada APP_CONFIG di bagian paling atas.
 * - Logika tampilan dashboard ada di render().
 * - Logika ringkasan kategori ada di renderCategories().
 * - Grafik histori ada di renderChart(), tabel histori di renderHistory().
 * - Event tombol dan formulir ada di bagian bawah file.
 * - Alamat API diproses FinanceEngine.java melalui native-bridge.js di dalam APK.
 */

/*
 * PENGATURAN APLIKASI
 * Ingin mengubah ikon atau warna kategori? Edit bagian categories di bawah.
 * Nilai warna menggunakan format HEX, misalnya "#6658e8".
 */
const APP_CONFIG = {
  currency: "IDR",
  locale: "id-ID",
  categories: {
    "Makanan":      { icon: "🍜", color: "#ff9b67" },
    "Transportasi": { icon: "🛵", color: "#5f9df7" },
    "Pendidikan":   { icon: "📚", color: "#8c7cf6" },
    "Hiburan":      { icon: "🎧", color: "#e77bb5" },
    "Kebutuhan":    { icon: "🛍️", color: "#31b99a" },
    "Lainnya":      { icon: "✦",  color: "#b1b5c6" },
    "Gaji":         { icon: "💼", color: "#1caa7b" },
    "Freelance":    { icon: "🖥️", color: "#038df7" },
    "Bonus":        { icon: "🎁", color: "#f5b745" },
    "Investasi":    { icon: "📈", color: "#8c7cf6" },
    "Pemasukan":    { icon: "💰", color: "#1caa7b" }
  },
  bulan: ["Jan","Feb","Mar","Apr","Mei","Jun","Jul","Agu","Sep","Okt","Nov","Des"]
};

// Nilai awal data diambil dari penyimpanan internal Android.

const rupiah = value => new Intl.NumberFormat("id-ID", {
  style: "currency", currency: APP_CONFIG.currency, maximumFractionDigits: 0
}).format(Number(value) || 0);


let appData = { anggaran: 0, pengeluaran: [], pemasukan: [], nama_pengguna: "Pengguna" };
let hideBudget = localStorage.getItem("dompet_hide_budget") === "1";

const $ = id => document.getElementById(id);
const expenseModal = $("expenseModal");
const profileModal = $("profileModal");


// ==================== FORMAT TANGGAL DAN NOTIFIKASI ====================
function tanggalHariIni() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,"0")}-${String(now.getDate()).padStart(2,"0")}`;
}
function formatTanggal(value) {
  if (!value) return "-";
  const [y,m,d] = value.split("-");
  return `${d}/${m}/${y}`;
}
function toast(message, error = false) {
  const el = $("toast");
  el.textContent = message;
  el.className = `toast show${error ? " error" : ""}`;
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => el.className = "toast", 2800);
}
// ==================== KOMUNIKASI DENGAN PENYIMPANAN ANDROID ====================
async function api(url, options = {}) {
  return window.dompetApi(url, options);
}
async function loadData() {
  try {
    appData = await api("/api/data");
    render();
  } catch (error) {
    toast("Gagal memuat data dari penyimpanan HP.", true);
  }
}
// ==================== DATA Gabungan UNTUK HISTORI ====================
function totalPemasukan() {
  return (appData.pemasukan || []).reduce((sum, item) => sum + Number(item.jumlah || 0), 0);
}
function totalPengeluaran() {
  return (appData.pengeluaran || []).reduce((sum, item) => sum + Number(item.jumlah || 0), 0);
}
// Gabungkan pemasukan + pengeluaran lalu urutkan dari yang terbaru.
function daftarHistori() {
  const list = [
    ...(appData.pengeluaran || []).map(item => ({...item, jenis: "pengeluaran"})),
    ...(appData.pemasukan || []).map(item => ({...item, jenis: "pemasukan"}))
  ];
  list.sort((a, b) => String(b.tanggal || "").localeCompare(String(a.tanggal || ""))
    || Number(b.id || 0) - Number(a.id || 0));
  return list;
}
// ==================== MENAMPILKAN DATA KE HALAMAN ====================
function render() {
  const items = appData.pengeluaran || [];
  const incomes = appData.pemasukan || [];
  const total = totalPengeluaran();
  const income = totalPemasukan();
  const remaining = Number(appData.anggaran || 0) - total;
  const percent = appData.anggaran > 0 ? Math.min(100, total / appData.anggaran * 100) : 0;
  const sembunyi = hideBudget ? "Rp••••••" : "";

  $("budgetValue").textContent = hideBudget ? sembunyi : rupiah(appData.anggaran);
  $("incomeValue").textContent = rupiah(income);
  $("totalValue").textContent = rupiah(total);
  $("remainingValue").textContent = hideBudget ? sembunyi : rupiah(remaining);
  $("balanceValue").textContent = rupiah(total);
  $("remainingValue").style.color = (!hideBudget && remaining < 0) ? "#df5967" : "";
  $("transactionCount").textContent = `${items.length} transaksi tercatat`;
  $("incomeCount").textContent = `${incomes.length} pemasukan tercatat`;
  $("progressLabel").textContent = hideBudget ? "•••% anggaran terpakai" : `${Math.round(percent)}% anggaran terpakai`;
  $("budgetProgress").style.width = `${percent}%`;
  $("budgetProgress").style.background = remaining < 0 ? "#df5967" : "";
  $("categoryTotal").textContent = rupiah(total);

  renderProfil();
  renderKickerHalaman();
  renderCategories(items, total);
  renderHistory();
}
// Teks sapaan pada header halaman.
function teksSubtitle(dashboardAktif) {
  const nama = (appData.nama_pengguna || "Pengguna").trim() || "Pengguna";
  return dashboardAktif
    ? `Halo ${nama}, pantau pemasukan, pengeluaran, dan jaga anggaranmu tetap terarah.`
    : "Lihat grafik dan semua transaksi pemasukan serta pengeluaranmu.";
}
function renderKickerHalaman() {
  const dashboardAktif = $("dashboardView").classList.contains("active-view");
  const judul = document.querySelector(".topbar h1");
  const sub = document.querySelector(".topbar .subtitle");
  judul.textContent = dashboardAktif ? "Dashboard" : "Histori Keuangan";
  sub.textContent = teksSubtitle(dashboardAktif);
}
// Nama dan huruf awal pada kartu profil.
function renderProfil() {
  const nama = (appData.nama_pengguna || "Pengguna").trim() || "Pengguna";
  $("profileName").textContent = nama;
  $("avatarLetter").textContent = nama.charAt(0).toUpperCase() || "U";
}
// Ringkasan total pengeluaran per kategori.
function renderCategories(items, total) {
  const summary = {};
  items.forEach(item => {
    summary[item.kategori] = (summary[item.kategori] || 0) + Number(item.jumlah || 0);
  });
  const container = $("categorySummary");
  container.innerHTML = "";
  const categories = Object.entries(summary).sort((a,b) => b[1] - a[1]);
  if (!categories.length) {
    const p = document.createElement("p");
    p.className = "muted";
    p.style.fontSize = "12px";
    p.textContent = "Ringkasan akan muncul setelah kamu menambahkan transaksi.";
    container.appendChild(p);
    return;
  }
  categories.forEach(([name, amount]) => {
    const row = document.createElement("div");
    row.className = "category-row";
    const label = document.createElement("div");
    label.className = "category-label";
    const icon = document.createElement("span");
    icon.textContent = (APP_CONFIG.categories[name]?.icon || "✦");
    const text = document.createElement("span");
    text.textContent = name;
    label.append(icon, text);
    const value = document.createElement("div");
    value.className = "category-amount";
    value.textContent = rupiah(amount);
    const track = document.createElement("div");
    track.className = "category-track";
    const bar = document.createElement("div");
    bar.className = "category-bar";
    bar.style.width = `${total ? amount / total * 100 : 0}%`;
    bar.style.background = (APP_CONFIG.categories[name]?.color || "#6658e8");
    track.appendChild(bar);
    row.append(label, value, track);
    container.appendChild(row);
  });
}
// ==================== HISTORI (TAHUN + FILTER) ====================
function pilihTahun() {
  const select = $("historyYear");
  const tahunSekarang = new Date().getFullYear();
  const tahun = new Set([String(tahunSekarang)]);
  daftarHistori().forEach(item => {
    if (item.tanggal) tahun.add(String(item.tanggal).slice(0, 4));
  });
  const daftar = [...tahun].sort((a, b) => b - a);
  const terpilih = select.value;
  select.innerHTML = "";
  daftar.forEach(t => {
    const opt = document.createElement("option");
    opt.value = t;
    opt.textContent = t;
    select.appendChild(opt);
  });
  select.value = daftar.includes(terpilih) ? terpilih : daftar[0];
}
function renderHistory() {
  pilihTahun();
  const tahun = $("historyYear").value;
  const jenis = $("historyType").value;
  const items = daftarHistori().filter(item => {
    const cocokTahun = !tahun || String(item.tanggal || "").startsWith(tahun);
    const cocokJenis = jenis === "semua" || item.jenis === jenis;
    return cocokTahun && cocokJenis;
  });

  $("listCount").textContent = `${items.length} data`;
  const rows = $("transactionRows");
  rows.innerHTML = "";
  $("emptyState").style.display = items.length ? "none" : "block";

  items.forEach(item => {
    const masuk = item.jenis === "pemasukan";
    const tr = document.createElement("tr");

    const nameCell = document.createElement("td");
    const nameWrap = document.createElement("div");
    nameWrap.className = "transaction-name";
    const symbol = document.createElement("span");
    symbol.className = "transaction-symbol";
    symbol.style.background = `${(APP_CONFIG.categories[item.kategori]?.color || "#b1b5c6")}20`;
    symbol.textContent = (APP_CONFIG.categories[item.kategori]?.icon || "✦");
    const nameText = document.createElement("span");
    nameText.textContent = item.nama;
    const small = document.createElement("small");
    small.textContent = masuk ? "Pemasukan" : "Pengeluaran";
    nameText.appendChild(small);
    nameWrap.append(symbol, nameText);
    nameCell.appendChild(nameWrap);

    const typeCell = document.createElement("td");
    const badge = document.createElement("span");
    badge.className = `type-badge ${masuk ? "badge-income" : "badge-expense"}`;
    badge.textContent = masuk ? "Pemasukan" : "Pengeluaran";
    typeCell.appendChild(badge);

    const categoryCell = document.createElement("td");
    const tag = document.createElement("span");
    tag.className = `category-tag${masuk ? " tag-income" : ""}`;
    tag.textContent = item.kategori || "Lainnya";
    categoryCell.appendChild(tag);

    const dateCell = document.createElement("td");
    dateCell.textContent = formatTanggal(item.tanggal);
    dateCell.style.color = "#8a90a5";

    const amountCell = document.createElement("td");
    amountCell.className = `amount-cell${masuk ? " amount-income" : ""}`;
    amountCell.textContent = `${masuk ? "+" : "-"}${rupiah(item.jumlah)}`;

    const actionCell = document.createElement("td");
    const del = document.createElement("button");
    del.className = "delete-btn";
    del.title = "Hapus transaksi";
    del.setAttribute("aria-label", `Hapus ${item.nama}`);
    del.textContent = "×";
    del.addEventListener("click", () => hapusItem(item));
    actionCell.appendChild(del);

    tr.append(nameCell, typeCell, categoryCell, dateCell, amountCell, actionCell);
    rows.appendChild(tr);
  });

  renderChart();
}
// ==================== GRAFIK HISTORI 1 TAHUN ====================
function ringkasUang(value) {
  const v = Number(value) || 0;
  if (v >= 1000000) return `${(v / 1000000).toFixed(v >= 10000000 ? 0 : 1)} jt`;
  if (v >= 1000) return `${Math.round(v / 1000)} rb`;
  return String(v);
}
function renderChart() {
  const canvas = $("historyChart");
  if (!canvas || !canvas.isConnected) return;
  const wrap = canvas.parentElement;
  const width = Math.max(320, wrap.clientWidth || 600);
  const height = window.innerWidth <= 760 ? 210 : 260;
  const dpr = window.devicePixelRatio || 1;
  canvas.width = Math.round(width * dpr);
  canvas.height = Math.round(height * dpr);
  canvas.style.width = `${width}px`;
  canvas.style.height = `${height}px`;

  const ctx = canvas.getContext("2d");
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  ctx.clearRect(0, 0, width, height);

  const tahun = Number($("historyYear").value) || new Date().getFullYear();
  const bulanan = Array.from({ length: 12 }, () => ({ masuk: 0, keluar: 0 }));
  (appData.pemasukan || []).forEach(item => {
    const [y, m] = String(item.tanggal || "").split("-").map(Number);
    if (y === tahun && m >= 1 && m <= 12) bulanan[m - 1].masuk += Number(item.jumlah || 0);
  });
  (appData.pengeluaran || []).forEach(item => {
    const [y, m] = String(item.tanggal || "").split("-").map(Number);
    if (y === tahun && m >= 1 && m <= 12) bulanan[m - 1].keluar += Number(item.jumlah || 0);
  });

  const gaya = getComputedStyle(document.documentElement);
  const warnaGaris = (gaya.getPropertyValue("--line") || "#edf0f6").trim();
  const warnaTeks = (gaya.getPropertyValue("--muted") || "#8a90a5").trim();
  const warnaMasuk = (gaya.getPropertyValue("--green") || "#1caa7b").trim();
  const warnaKeluar = (gaya.getPropertyValue("--orange") || "#f59a45").trim();

  const padding = { top: 14, right: 8, bottom: 26, left: 44 };
  const plotW = width - padding.left - padding.right;
  const plotH = height - padding.top - padding.bottom;
  const maks = Math.max(...bulanan.map(b => Math.max(b.masuk, b.keluar)), 1);

  // Garis bantu + label sumbu Y
  ctx.font = '10px "DM Sans", sans-serif';
  ctx.textBaseline = "middle";
  for (let i = 0; i <= 4; i++) {
    const nilai = maks * i / 4;
    const y = padding.top + plotH - (plotH * i / 4);
    ctx.strokeStyle = warnaGaris;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padding.left, y);
    ctx.lineTo(width - padding.right, y);
    ctx.stroke();
    ctx.fillStyle = warnaTeks;
    ctx.textAlign = "right";
    ctx.fillText(ringkasUang(nilai), padding.left - 8, y);
  }

  const slot = plotW / 12;
  const lebarBar = Math.min(16, slot * 0.3);
  bulanan.forEach((data, index) => {
    const tengah = padding.left + slot * index + slot / 2;
    const tinggiMasuk = data.masuk / maks * plotH;
    const tinggiKeluar = data.keluar / maks * plotH;
    const dasar = padding.top + plotH;

    ctx.fillStyle = warnaMasuk;
    ctx.fillRect(tengah - lebarBar - 2, dasar - tinggiMasuk, lebarBar, tinggiMasuk);
    ctx.fillStyle = warnaKeluar;
    ctx.fillRect(tengah + 2, dasar - tinggiKeluar, lebarBar, tinggiKeluar);

    ctx.fillStyle = warnaTeks;
    ctx.textAlign = "center";
    ctx.textBaseline = "alphabetic";
    ctx.fillText(APP_CONFIG.bulan[index], tengah, height - 8);
    ctx.textBaseline = "middle";
  });
}
// ==================== MODAL / POPUP ====================
function openModal(modal) {
  modal.classList.add("show");
  modal.setAttribute("aria-hidden", "false");
}
function closeModal(modal) {
  modal.classList.remove("show");
  modal.setAttribute("aria-hidden", "true");
}
let itemUntukDihapus = null;
function hapusItem(item) {
  itemUntukDihapus = item;
  const jenis = item.jenis === "pemasukan" ? "pemasukan" : "pengeluaran";
  $("deleteMessage").textContent = `Hapus ${jenis} "${item.nama}"?` +
    (item.ditambahkan_ke_anggaran ? " Anggaran juga akan berkurang." : "");
  openModal($("deleteModal"));
}
$("cancelDeleteBtn").addEventListener("click", () => closeModal($("deleteModal")));
$("deleteModal").addEventListener("click", e => {
  if (e.target === $("deleteModal")) closeModal($("deleteModal"));
});
$("confirmDeleteBtn").addEventListener("click", async () => {
  if (!itemUntukDihapus) return;
  const button = $("confirmDeleteBtn");
  button.disabled = true;
  try {
    const item = itemUntukDihapus;
    const endpoint = item.jenis === "pemasukan" ? `/api/pemasukan/${item.id}` : `/api/pengeluaran/${item.id}`;
    const result = await api(endpoint, { method: "DELETE" });
    appData = result.data;
    itemUntukDihapus = null;
    closeModal($("deleteModal"));
    render();
    toast(result.pesan);
  } catch (error) {
    toast(error.message, true);
  } finally {
    button.disabled = false;
  }
});

// ==================== TEMA TERANG / GELAP ====================
function terapkanTema(tema) {
  document.documentElement.dataset.theme = tema;
  localStorage.setItem("dompet_theme", tema);
  const btn = $("themeToggleBtn");
  btn.textContent = tema === "dark" ? "🌙" : "☀";
  btn.title = tema === "dark" ? "Gunakan tema terang" : "Gunakan tema gelap";
  btn.setAttribute("aria-label", btn.title);
  renderChart();
}
// ==================== SEMBUNYIKAN ANGGARAN ====================
function terapkanSembunyiAnggaran() {
  const btn = $("hideBudgetBtn");
  btn.textContent = hideBudget ? "🙈" : "👁";
  btn.title = hideBudget ? "Tampilkan anggaran" : "Sembunyikan anggaran";
  btn.setAttribute("aria-label", btn.title);
  btn.setAttribute("aria-pressed", String(hideBudget));
}

// ==================== EVENT TOMBOL DAN FORM ====================
$("todayLabel").textContent = new Intl.DateTimeFormat("id-ID", {
  day:"numeric", month:"short", year:"numeric"
}).format(new Date());
$("expenseDate").value = tanggalHariIni();
$("incomeDate").value = tanggalHariIni();

$("openFormBtn").addEventListener("click", () => openEntryModal("pengeluaran"));
$("emptyAddBtn").addEventListener("click", () => openEntryModal("pengeluaran"));
$("editBudgetBtn").addEventListener("click", () => openEntryModal("anggaran"));
$("closeModalBtn").addEventListener("click", () => closeModal(expenseModal));
$("cancelModalBtn").addEventListener("click", () => closeModal(expenseModal));
expenseModal.addEventListener("click", e => {
  if (e.target === expenseModal) closeModal(expenseModal);
});
profileModal.addEventListener("click", e => {
  if (e.target === profileModal) closeModal(profileModal);
});
document.addEventListener("keydown", e => {
  if (e.key === "Escape") {
    closeModal(expenseModal);
    closeModal(profileModal);
    closeModal($("deleteModal"));
  }
});

$("historyYear").addEventListener("change", renderHistory);
$("historyType").addEventListener("change", renderHistory);
window.addEventListener("resize", () => {
  clearTimeout(window.__chartTimer);
  window.__chartTimer = setTimeout(renderChart, 150);
});

$("themeToggleBtn").addEventListener("click", () => {
  const sekarang = document.documentElement.dataset.theme === "dark" ? "dark" : "light";
  terapkanTema(sekarang === "dark" ? "light" : "dark");
});
$("hideBudgetBtn").addEventListener("click", () => {
  hideBudget = !hideBudget;
  localStorage.setItem("dompet_hide_budget", hideBudget ? "1" : "0");
  terapkanSembunyiAnggaran();
  render();
  toast(hideBudget ? "Anggaran disembunyikan." : "Anggaran ditampilkan kembali.");
});

// Nominal diformat saat diketik, lalu diubah kembali menjadi angka untuk API.
function nilaiNominal(input) {
  const angka = input.value.replace(/\D/g, "");
  const nilai = Number(angka);
  if (!angka || !Number.isSafeInteger(nilai)) throw new Error("Masukkan nominal yang valid.");
  return nilai;
}
["expenseAmount", "incomeAmount", "budgetInput"].forEach(id => {
  const input = $(id);
  input.addEventListener("input", () => {
    const posisi = input.selectionStart;
    const sebelum = input.value.slice(0, posisi).replace(/\D/g, "").length;
    const digits = input.value.replace(/\D/g, "").slice(0, 15);
    input.value = digits.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
    let hitung = 0, kursor = 0;
    while (kursor < input.value.length && hitung < sebelum) {
      if (/\d/.test(input.value[kursor])) hitung++;
      kursor++;
    }
    input.setSelectionRange(kursor, kursor);
  });
});
function openEntryModal(type = "pengeluaran") {
  $("entryType").value = type;
  updateEntryType();
  $("expenseDate").value = tanggalHariIni();
  $("incomeDate").value = tanggalHariIni();
  $("budgetInput").value = "";
  updateBudgetHint();
  openModal(expenseModal);
}
function updateBudgetHint() {
  const mode = $("budgetMode").value;
  const saatIni = hideBudget ? "Rp••••••" : rupiah(appData.anggaran || 0);
  $("budgetHint").textContent = mode === "tambah"
    ? `Anggaran saat ini: ${saatIni}. Nilai yang kamu masukkan akan DITAMBAHKAN ke anggaran sebelumnya.`
    : `Anggaran saat ini: ${saatIni}. Nilai yang kamu masukkan akan MENGGANTIKAN anggaran saat ini.`;
}
$("budgetMode").addEventListener("change", updateBudgetHint);

function updateEntryType() {
  const type = $("entryType").value;
  const isExpense = type === "pengeluaran";
  const isIncome = type === "pemasukan";
  const isBudget = type === "anggaran";

  $("expenseFields").hidden = !isExpense;
  $("incomeFields").hidden = !isIncome;
  $("budgetFields").hidden = !isBudget;

  $("expenseName").required = isExpense;
  $("expenseDate").required = isExpense;
  $("expenseCategory").required = isExpense;
  $("expenseAmount").required = isExpense;
  $("incomeName").required = isIncome;
  $("incomeDate").required = isIncome;
  $("incomeAmount").required = isIncome;
  $("budgetInput").required = isBudget;

  const judul = isBudget ? "Tambahkan Anggaran" : (isIncome ? "Tambahkan Pemasukan" : "Tambahkan Pengeluaran");
  const tombol = isBudget ? "Simpan Anggaran" : (isIncome ? "Simpan Pemasukan" : "Simpan Pengeluaran");
  $("entryModalTitle").textContent = judul;
  $("saveEntryBtn").innerHTML = `${tombol} <span>↗</span>`;
  if (isBudget) updateBudgetHint();
}
$("entryType").addEventListener("change", updateEntryType);

$("expenseForm").addEventListener("submit", async e => {
  e.preventDefault();
  const type = $("entryType").value;
  try {
    if (type === "anggaran") {
      const amount = nilaiNominal($("budgetInput"));
      if (!Number.isFinite(amount) || amount < 0) throw new Error("Anggaran harus nol atau lebih.");
      const mode = $("budgetMode").value;
      const result = await api("/api/anggaran", {
        method:"PUT",
        body:JSON.stringify({anggaran:amount, mode})
      });
      appData = result.data;
      render();
      $("budgetInput").value = "";
      closeModal(expenseModal);
      toast(result.pesan);
      return;
    }

    if (type === "pemasukan") {
      const body = {
        nama: $("incomeName").value.trim(),
        tanggal: $("incomeDate").value,
        kategori: $("incomeCategory").value,
        jumlah: nilaiNominal($("incomeAmount"))
      };
      const result = await api("/api/pemasukan", {method:"POST", body:JSON.stringify(body)});
      appData = result.data;
      render();
      e.target.reset();
      $("incomeDate").value = tanggalHariIni();
      $("expenseDate").value = tanggalHariIni();
      updateEntryType();
      closeModal(expenseModal);
      toast(result.pesan);
      return;
    }

    const body = {
      nama: $("expenseName").value.trim(),
      tanggal: $("expenseDate").value,
      kategori: $("expenseCategory").value,
      jumlah: nilaiNominal($("expenseAmount"))
    };
    const result = await api("/api/pengeluaran", {method:"POST", body:JSON.stringify(body)});
    appData = result.data;
    render();
    e.target.reset();
    $("expenseDate").value = tanggalHariIni();
    $("incomeDate").value = tanggalHariIni();
    updateEntryType();
    closeModal(expenseModal);
    toast(result.pesan);
  } catch (error) {
    toast(error.message, true);
  }
});

// ==================== NAMA PENGGUNA ====================
function openProfileModal() {
  $("profileNameInput").value = (appData.nama_pengguna || "Pengguna").trim();
  openModal(profileModal);
  setTimeout(() => $("profileNameInput").focus(), 60);
}
$("editProfileBtn").addEventListener("click", openProfileModal);
$("closeProfileBtn").addEventListener("click", () => closeModal(profileModal));
$("cancelProfileBtn").addEventListener("click", () => closeModal(profileModal));
$("profileForm").addEventListener("submit", async e => {
  e.preventDefault();
  const nama = $("profileNameInput").value.trim();
  if (!nama) return toast("Nama tidak boleh kosong.", true);
  try {
    const result = await api("/api/profil", {method:"PUT", body:JSON.stringify({nama})});
    appData = result.data;
    render();
    closeModal(profileModal);
    toast(result.pesan);
  } catch (error) {
    toast(error.message, true);
  }
});

// ==================== PIN KEAMANAN & PEMULIHAN ====================
// Mode: setup (pertama kali), unlock (masuk), reset (lupa PIN).
let pinMode = "unlock";

function tampilkanModePin(mode) {
  pinMode = mode;
  const setup = mode === "setup";
  const reset = mode === "reset";
  $("pinTitle").textContent = setup ? "Buat PIN Keamanan" : reset ? "Buat PIN Baru" : "Masukkan PIN";
  $("pinDescription").textContent = setup
    ? "Buat PIN 4–8 angka untuk melindungi data keuanganmu."
    : reset
      ? "Masukkan kode pemulihan yang kamu simpan, kemudian buat PIN baru."
      : "Masukkan PIN keamanan untuk membuka DompetGueh.";
  $("pinLabel").textContent = setup || reset ? "PIN baru" : "PIN keamanan";
  $("pinSubmit").textContent = setup ? "Simpan PIN" : reset ? "Buat PIN Baru" : "Buka Aplikasi";
  $("recoveryInputWrap").hidden = !reset;
  $("recoveryInput").required = reset;
  $("confirmPinWrap").hidden = !(setup || reset);
  $("confirmPinInput").required = setup || reset;
  $("forgotPinBtn").hidden = mode !== "unlock";
  $("backToLoginBtn").hidden = mode !== "reset";
  $("pinInput").autocomplete = mode === "unlock" ? "current-password" : "new-password";
  $("pinInput").value = "";
  $("confirmPinInput").value = "";
  $("recoveryInput").value = "";
  $("pinError").textContent = "";
  $("pinForm").hidden = false;
  $("recoveryResult").hidden = true;
  $("pinNote").hidden = false;
  $("pinScreen").classList.remove("pin-hidden");
}

async function setupSecurity() {
  const status = await api("/api/pin/status");
  // Jangan membiarkan sesi lama melewati pengaturan PIN yang belum selesai.
  if (status.perlu_setup) {
    tampilkanModePin("setup");
  } else if (status.terbuka) {
    $("pinScreen").classList.add("pin-hidden");
    await loadData();
  } else {
    tampilkanModePin("unlock");
  }
}

// Setelah setup atau reset, kode pemulihan baru wajib ditunjukkan sekali.
function tampilkanKodePemulihan(kode) {
  $("pinForm").hidden = true;
  $("pinInput").value = "";
  $("confirmPinInput").value = "";
  $("recoveryInput").value = "";
  $("recoveryResult").hidden = false;
  $("recoveryCode").textContent = kode;
  $("pinTitle").textContent = "Simpan Kode Pemulihan";
  $("pinDescription").textContent = "PIN berhasil dibuat. Simpan kode ini sebelum masuk aplikasi.";
  $("forgotPinBtn").hidden = true;
  $("backToLoginBtn").hidden = true;
  $("pinNote").hidden = true;
}

$("forgotPinBtn").addEventListener("click", () => tampilkanModePin("reset"));
$("backToLoginBtn").addEventListener("click", () => tampilkanModePin("unlock"));
$("copyRecoveryBtn").addEventListener("click", async () => {
  const kode = $("recoveryCode").textContent;
  try {
    if (window.DompetNative) window.DompetNative.copy(kode);
    else await navigator.clipboard.writeText(kode);
    toast("Kode pemulihan disalin.");
  } catch (error) {
    // Fallback saat aplikasi dibuka lewat HTTP non-HTTPS.
    const input = document.createElement("textarea");
    input.value = kode;
    document.body.appendChild(input);
    input.select();
    try {
      document.execCommand("copy");
      toast("Kode pemulihan disalin.");
    } catch (copyError) {
      toast("Silakan salin kode secara manual.", true);
    }
    input.remove();
  }
});
$("finishRecoveryBtn").addEventListener("click", async () => {
  $("recoveryCode").textContent = "";
  $("pinScreen").classList.add("pin-hidden");
  await loadData();
});

$("pinForm").addEventListener("submit", async e => {
  e.preventDefault();
  const pin = $("pinInput").value;
  if (!/^\d{4,8}$/.test(pin)) {
    $("pinError").textContent = "PIN harus terdiri dari 4 sampai 8 angka.";
    return;
  }
  if (pinMode !== "unlock" && pin !== $("confirmPinInput").value) {
    $("pinError").textContent = "Konfirmasi PIN tidak sama.";
    return;
  }
  try {
    let endpoint, body;
    if (pinMode === "setup") {
      endpoint = "/api/pin/setup";
      body = { pin };
    } else if (pinMode === "reset") {
      endpoint = "/api/pin/reset";
      body = { pin_baru: pin, kode_pemulihan: $("recoveryInput").value.trim() };
    } else {
      endpoint = "/api/pin/unlock";
      body = { pin };
    }
    const result = await api(endpoint, { method:"POST", body:JSON.stringify(body) });
    if (pinMode === "setup" || pinMode === "reset") {
      tampilkanKodePemulihan(result.kode_pemulihan);
    } else {
      $("pinInput").value = "";
      $("pinScreen").classList.add("pin-hidden");
      await loadData();
      toast(result.pesan);
    }
  } catch (error) {
    $("pinError").textContent = error.message;
  }
});

$("lockAppBtn").addEventListener("click", async () => {
  try {
    await api("/api/pin/lock", {method:"POST"});
    // Buang data yang sempat ditampilkan dari memori halaman.
    appData = { anggaran:0, pengeluaran:[], pemasukan:[], nama_pengguna:"Pengguna" };
    render();
    tampilkanModePin("unlock");
  } catch (error) {
    toast(error.message, true);
  }
});

// ==================== NAVIGASI HALAMAN ====================
// Navigasi menu utama: Dashboard dan Histori Keuangan
function tampilkanHalaman(namaHalaman) {
  const dashboardAktif = namaHalaman === "dashboard";
  $("dashboardView").classList.toggle("active-view", dashboardAktif);
  $("historiView").classList.toggle("active-view", !dashboardAktif);
  document.querySelectorAll(".nav-item[data-page]").forEach(link => {
    const aktif = link.dataset.page === namaHalaman;
    link.classList.toggle("active", aktif);
    if (aktif) link.setAttribute("aria-current", "page");
    else link.removeAttribute("aria-current");
  });
  const title = document.querySelector(".topbar h1");
  const subtitle = document.querySelector(".topbar .subtitle");
  title.textContent = dashboardAktif ? "Dashboard" : "Histori Keuangan";
  subtitle.textContent = teksSubtitle(dashboardAktif);
  if (dashboardAktif) history.replaceState(null, "", "#dashboard");
  else history.replaceState(null, "", "#histori");
  if (!dashboardAktif) requestAnimationFrame(renderChart);
}
document.querySelectorAll(".nav-item[data-page]").forEach(link => {
  link.addEventListener("click", event => {
    event.preventDefault();
    tampilkanHalaman(link.dataset.page);
  });
});

// ==================== INIT ====================
terapkanTema(document.documentElement.dataset.theme || "light");
terapkanSembunyiAnggaran();
pilihTahun();
setupSecurity().catch(error => { $("pinError").textContent = error.message; });
