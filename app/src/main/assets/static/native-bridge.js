/* Only transport changes: the original UI calls the private Android backend. */
(function () {
  let serial = 0;
  const pending = new Map();
  window.__nativeResolve = function (id, response) {
    const operation = pending.get(id);
    if (!operation) return;
    pending.delete(id);
    if (response.ok) operation.resolve(response.result);
    else operation.reject(new Error(response.pesan || "Terjadi kesalahan."));
  };
  window.dompetApi = function (path, options = {}) {
    return new Promise((resolve, reject) => {
      if (!window.DompetNative) return reject(new Error("Buka aplikasi dari APK DompetGueh."));
      const id = String(++serial);
      pending.set(id, { resolve, reject });
      try { window.DompetNative.request(id, path, options.method || "GET", options.body || "{}"); }
      catch (error) { pending.delete(id); reject(error); }
    });
  };
})();
