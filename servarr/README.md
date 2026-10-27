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

## Bootstrap

The optional `bootstrap` hook Job uses the servarr-bootstrap image to configure
qBittorrent, Prowlarr, Sonarr, Radarr, Jellyfin and Seerr. It is safe to rerun;
it reconciles the existing state rather than creating duplicate accounts.
