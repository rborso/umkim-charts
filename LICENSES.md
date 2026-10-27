# Licenses and notices

The **chart source** in this repository is Apache-2.0. The applications and
images the charts deploy remain under their own upstream licenses. This
repository does not vendor upstream application source.

## Charts

| Chart | License |
|---|---|
| `gitea` | Apache-2.0 |
| `immich` | Apache-2.0 |
| `nextcloud` | Apache-2.0 |
| `paperless` | Apache-2.0 |
| `servarr` | Apache-2.0 |

Each chart's `Chart.yaml` declares `artifacthub.io/license: Apache-2.0` and lists
its upstream sources. Packaged chart archives include `LICENSE` and `NOTICE`.

## Applications

### Gitea

| Component | License | Source |
|---|---|---|
| Gitea | MIT | https://github.com/go-gitea/gitea |
| PostgreSQL | PostgreSQL License | https://www.postgresql.org/about/licence/ |
| Valkey | BSD-3-Clause | https://github.com/valkey-io/valkey |

### Nextcloud

| Component | License | Source |
|---|---|---|
| Nextcloud | AGPL-3.0 | https://github.com/nextcloud/server |
| Collabora Online | MPL-2.0 | https://github.com/CollaboraOnline/online |
| PostgreSQL | PostgreSQL License | https://www.postgresql.org/about/licence/ |
| Valkey | BSD-3-Clause | https://github.com/valkey-io/valkey |

### Immich

| Component | License | Source |
|---|---|---|
| Immich | AGPL-3.0 | https://github.com/immich-app/immich |
| VectorChord | AGPL-3.0 or Elastic-2.0 (dual) | https://github.com/tensorchord/VectorChord |
| PostgreSQL | PostgreSQL License | https://www.postgresql.org/about/licence/ |
| Valkey | BSD-3-Clause | https://github.com/valkey-io/valkey |

### Paperless-ngx

| Component | License | Source |
|---|---|---|
| Paperless-ngx | GPL-3.0 | https://github.com/paperless-ngx/paperless-ngx |
| PostgreSQL | PostgreSQL License | https://www.postgresql.org/about/licence/ |
| Valkey | BSD-3-Clause | https://github.com/valkey-io/valkey |

### Servarr

| Component | License | Source |
|---|---|---|
| Seerr | MIT | https://github.com/seerr-team/seerr |
| Jellyfin | GPL-2.0 | https://github.com/jellyfin/jellyfin |
| Sonarr | GPL-3.0 | https://github.com/Sonarr/Sonarr |
| Radarr | GPL-3.0 | https://github.com/Radarr/Radarr |
| Prowlarr | GPL-3.0 | https://github.com/Prowlarr/Prowlarr |
| qBittorrent | GPL-2.0-or-later source; GPL-3.0-or-later binary with OpenSSL exception | https://github.com/qbittorrent/qBittorrent |
| FlareSolverr | MIT | https://github.com/FlareSolverr/FlareSolverr |
| Jellyfin LDAP authentication plugin | MIT | https://github.com/jellyfin/jellyfin-plugin-ldapauth |
| LinuxServer.io image packaging | GPL-3.0 | https://github.com/linuxserver/docker-jellyfin |

The full platform and catalog inventory is in the umkim-thin
[`docs/licenses.md`](https://github.com/rborso/umkim-thin/blob/main/docs/licenses.md).
