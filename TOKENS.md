# XD VPS · Token

Tidak wajib untuk SSH atau 9router. Login dashboard 9router = password root.

## GitHub — backup (opsional)

[Buat token](https://github.com/settings/tokens/new?description=XD%20VPS%20src-sync&scopes=repo) → centang **`repo`** → Generate → copy `ghp_...`

Isi di **[`config.json`](config.json)** (bukan Railway Variables):

```json
"github_token": "ghp_...",
"github_repo": ""
```

| `github_repo` | Efek |
|---------------|------|
| **kosong** | Auto-buat repo privat `xd-vps-src-<project-id>` di akun token |
| `owner/name` atau URL | Pakai repo itu. Launch: **restore sekali**, lalu cuma **auto-backup** |

Commit + push. Railway rebuild dari repo.

Token harus bisa akses repo itu (akun yang sama, atau collaborator).

Provider AI, model, dan API key: isi di **UI 9router**, bukan di sini.

© XD VPS · KurrXd
