# servarr

One chart for the media stack: Seerr, Jellyfin, Sonarr, Radarr, Prowlarr,
qBittorrent and FlareSolverr, wired together on a shared media volume. Config
volumes use a RWO class; media uses the platform's RWX/shareable class
(`ReadWriteMany` on HA, `ReadWriteOnce` on a single node). The umkim-thin
catalog fills both from the install form.

The chart deploys upstream images; the bootstrap Job configures the apps through
their APIs. It does not vendor upstream application source. See the
`bootstrap` values for the optional image/Job; the platform console normally
builds/imports it for the pinned node.

## Language

The media stack's default language is English. The console install form and the
chart's `bootstrap.mediaLanguage` accept English, Hungarian, and the other
supported Radarr languages. It controls the Seerr original language, the
Radarr/Sonarr language profile, and Jellyfin's first-run language.

## License

The **chart source** is Apache-2.0, part of umkim-thin.

| Component | License |
|---|---|
| Seerr | MIT |
| Jellyfin | GPL-2.0 |
| Sonarr | GPL-3.0 |
| Radarr | GPL-3.0 |
| Prowlarr | GPL-3.0 |
| qBittorrent | GPL-2.0-or-later source; GPL-3.0-or-later binary with OpenSSL exception |
| FlareSolverr | MIT |
| Jellyfin LDAP plugin | MIT |
| LinuxServer.io image packaging | GPL-3.0 |

See [`../LICENSES.md`](../LICENSES.md) for sources and notices.

## Persistence

Each app keeps its configuration on its `<app>-config` PVC, mounted at
`/config`. Seerr's image defaults to `/app/config`, so the chart sets
`CONFIG_DIRECTORY=/config` and gives its pod `fsGroup: 1000` (the image runs as
UID 1000). When upgrading from a chart before 0.3.3, copy the old container's
`/app/config` onto the PVC **before** the upgrade; otherwise Seerr starts at
first-run setup and only the copy can restore it.

## Bootstrap

The optional `bootstrap` hook Job uses the servarr-bootstrap image to configure
qBittorrent, Prowlarr, Sonarr, Radarr, Jellyfin and Seerr. It is safe to rerun;
it reconciles the existing state rather than creating duplicate accounts.
