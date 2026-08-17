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

Password default: **`Kurr123@`** — ganti di [`config.json`](config.json) (`root_password`). Tidak perlu isi Railway Variables.

Ini **container Railway**, bukan VPS dedicated. Redeploy = disk kosong, kecuali kamu pasang Volume atau isi `github_token` di config.json.

---

## 1. Deploy dari GitHub

Repo: **[asepbalon121221/RailwayUBUNTUDOCKER](https://github.com/asepbalon121221/RailwayUBUNTUDOCKER)**

Semua setting ada di **[`config.json`](config.json)** di repo. Edit file itu, commit, push — Railway rebuild. **Tidak perlu isi Variables.**

1. Isi `config.json` (password, `github_token`, `github_repo`, dll).
2. Railway → [Account](https://railway.com/account) → **connect GitHub**.
3. [New Project](https://railway.com/new) → **Deploy from GitHub repo** → **`RailwayUBUNTUDOCKER`** → Deploy Now.
4. Tunggu build hijau.

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

Isi di [`config.json`](config.json):

```json
"github_token": "ghp_...",
"github_repo": ""
```

| `github_repo` | Efek |
|---------------|------|
| **kosong** | Auto-buat repo privat `xd-vps-src-<project-id>` |
| `owner/name` atau URL | Pakai repo itu |

Push → Railway rebuild. Launch: restore sekali, lalu auto-backup.

Detail: [TOKENS.md](TOKENS.md)

```bash
src-sync --status
```

---

## config.json

| Key | Default | Fungsi |
|-----|---------|--------|
| `root_password` | `Kurr123@` | Password root + 9router |
| `github_token` | `""` | Backup on/off |
| `github_repo` | `""` | Nama/URL repo backup; kosong = auto-buat |
| `sync_interval` | `180` | Jeda backup (detik) |
| `authorized_keys` | `""` | SSH public key |
| `ssh_username` / `ssh_password` | `""` | User sudo tambahan |
| `app_lang` | `id` | `id` atau `en` |
| `ninerouter.port` | `20128` | Port UI |

Railway Variables opsional — kalau diisi, menimpa config.json.

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
