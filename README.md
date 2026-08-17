# Railway Ubuntu Docker

Ubuntu 24.04 SSH di [Railway](https://railway.com) + dashboard [9router](https://github.com/decolua/9router).  
Klik tombol → isi 1–2 variabel (boleh dikosongkan) → SSH & UI langsung jadi.

**Dev:** KurrXd

> Format tombol lama (`/new/template?template=https://github.com/...&envs=`) **sudah mati**. Railway mengabaikannya dan buka pencarian template (PostgreSQL, Redis, …).

Satu-klik yang masih jalan butuh **template Railway resmi** (`/new/template/KODE`). Itu baru bisa dibuat setelah akun Railway **connect GitHub**.

Sementara ini: deploy langsung dari repo ini + isi env di layar **Add variables**.

---

## Yang kamu dapat

| | |
|--|--|
| OS | Ubuntu 24.04, login **root** |
| SSH | TCP proxy port **22** |
| 9router | UI web port **20128** (setup AI dari browser) |
| Node | LTS + `python` / `pip` |
| Backup | Opsional, ke repo GitHub privat |

Password default: **`Kurr123@`** (root + login 9router). Ganti lewat `ROOT_PASSWORD`.

Ini **container Railway**, bukan VPS dedicated. Redeploy = disk kosong, kecuali kamu pasang Volume atau isi backup GitHub.

---

## 1. Deploy dari GitHub (isi env di situ)

Repo: **[asepbalon121221/RailwayUBUNTUDOCKER](https://github.com/asepbalon121221/RailwayUBUNTUDOCKER)**

1. Railway → [Account](https://railway.com/account) → **connect GitHub** (akun yang punya repo ini).
2. [New Project](https://railway.com/new) → **Deploy from GitHub repo** (jangan pilih PostgreSQL / Redis).
3. Pilih **`RailwayUBUNTUDOCKER`**.
4. Klik **Add variables** (bukan Deploy Now), isi:

   | Variabel | Wajib? | Isi |
   |----------|--------|-----|
   | `ROOT_PASSWORD` | tidak | Password SSH + 9router. Kosong = `Kurr123@` |
   | `GITHUB_TOKEN` | tidak | PAT GitHub scope `repo`. Kosong = backup mati |
   | `GITHUB_REPO` | tidak | `owner/name` atau URL. Kosong = auto-buat `xd-vps-src-<id>` |

5. **Deploy**. Tunggu build hijau.

Setelah GitHub sudah nyambung di Railway, template one-click + form env bisa di-generate (tombol `railway.com/new/template/KODE`).

### Jaringan (kalau belum otomatis)

Service → **Settings** → **Networking**:

1. **TCP Proxy** → port aplikasi **22** → salin host + port publik.
2. **Generate Domain** → target port **20128** (9router).

---

## 2. Masuk SSH

```bash
ssh root@<TCP_HOST> -p <TCP_PORT>
```

Contoh:

```bash
ssh root@mainline.proxy.rlwy.net -p 39381
```

Password: `Kurr123@` (atau `ROOT_PASSWORD` yang kamu set).

Host TCP Railway biasanya resolve ke IP publik. Cek:

```bash
nslookup <TCP_HOST>
```

Lalu:

```
ip    66.x.x.x
port  39381
pass  Kurr123@
```

---

## 3. 9router (dashboard AI)

Buka domain HTTP Railway (port **20128**).

Login password = password root.

Dari UI: Providers, model, API key. Tidak perlu CLI.

---

## 4. Backup GitHub (opsional)

Supaya 9router + file `/root` selamat saat redeploy.

1. Buat PAT: [github.com/settings/tokens](https://github.com/settings/tokens/new?description=XD%20VPS%20src-sync&scopes=repo) → centang **`repo`**.
2. Railway → Variables:

```
GITHUB_TOKEN=ghp_...
GITHUB_REPO=
```

| `GITHUB_REPO` | Efek |
|---------------|------|
| **kosong** | Auto-buat repo privat `xd-vps-src-<project-id>` |
| paste `owner/name` atau URL | Pakai repo itu |

**Launch:** restore dari GitHub **sekali**, setelah itu cuma **auto-backup** (default 3 menit).

Detail: [TOKENS.md](TOKENS.md)

Cek di SSH:

```bash
src-sync --status
```

---

## Variabel lengkap

| Variabel | Default | Fungsi |
|----------|---------|--------|
| `ROOT_PASSWORD` | `Kurr123@` | Password root + 9router |
| `GITHUB_TOKEN` | kosong | Backup on/off |
| `GITHUB_REPO` | kosong | Nama/URL repo backup; kosong = auto-buat |
| `SYNC_INTERVAL` | `180` | Jeda backup (detik) |
| `AUTHORIZED_KEYS` | kosong | SSH public key (password tetap hidup) |
| `SSH_USERNAME` + `SSH_PASSWORD` | kosong | User sudo tambahan (isi berdua) |
| `APP_LANG` | `id` | Bahasa log: `id` atau `en` |

---

## Perintah di SSH

```bash
usage              # sisa kredit trial Railway
src-sync --status  # status backup
src-sync backup    # push backup sekarang
```

---

## Volume (opsional)

Data hilang saat redeploy. Kalau mau disk tetap:

Railway → service → **Volume** → mount **`/root`**.

Itu ikut nyimpan `~/.9router`. Backup GitHub tetap disarankan.

---

## Deploy manual (tanpa tombol)

```bash
git clone https://github.com/asepbalon121221/RailwayUBUNTUDOCKER
cd RailwayUBUNTUDOCKER
# Railway CLI
railway login
railway init
railway up
```

Lalu pasang TCP **22** + domain **20128** seperti di atas.

---

## Troubleshooting

| Gejala | Cek |
|--------|-----|
| SSH timeout | TCP Proxy port **22** sudah dibuat? Host/port dari Networking, bukan domain HTTP |
| 9router tidak buka | Domain mengarah ke port **20128**? |
| Backup mati | `GITHUB_TOKEN` terisi? `src-sync --status` |
| Restore tidak jalan | Token harus bisa akses `GITHUB_REPO` (akun yang sama / collaborator) |
| Password ditolak | Pakai `ROOT_PASSWORD` di Variables, bukan password Railway |

© XD VPS · KurrXd · MIT
