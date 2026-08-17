# XD VPS · Token

Tidak wajib untuk SSH atau 9router. Login dashboard 9router = password root.

## GitHub — backup (opsional)

[Buat token](https://github.com/settings/tokens/new?description=XD%20VPS%20src-sync&scopes=repo) → centang **`repo`** → Generate → copy `ghp_...`

Di Railway Variables:

```
GITHUB_TOKEN=ghp_...
GITHUB_REPO=
```

| `GITHUB_REPO` | Efek |
|---------------|------|
| **kosong** | Auto-buat repo privat `xd-vps-src-<project-id>` di akun token |
| `owner/name` atau URL | Pakai repo itu. Launch: **restore sekali**, lalu cuma **auto-backup** |

Contoh paste repo lama:

```
GITHUB_REPO=owner/nama-repo-backup
```

Token harus bisa akses repo itu (akun yang sama, atau collaborator).

Token disimpan di `/var/lib/xd/github-token` (chmod 600).

Provider AI, model, dan API key: isi di **UI 9router**, bukan di sini.

© XD VPS · KurrXd
