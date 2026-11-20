# umkim-charts

The official app charts for [umkim-thin](https://github.com/rborso/umkim-thin).

This repository is the source of the charts the catalog pins. Charts are
distributed as source: each installation packages the version it needs into its
local chart mirror. There is no chart registry. The platform repo vendors this
repository as the `charts/apps` submodule; the installer packages those charts
into the mirror, so a chart update is a version bump and a commit here, followed
by a submodule bump in `umkim-thin`.

The catalog entries point at the chart's directory in this repository. The
console uses the locally packaged chart for the exact version; the ref records
provenance, it is not a fetch URL.

## Charts

| Directory | Chart | Chart version | App version | Upstream application |
|---|---|---|---|---|
| `actualbudget/` | `actualbudget` | `0.1.2` | `26.11.0` | Actual Budget, SQLite |
| `gitea/` | `gitea` | `0.1.21` | `28.3.0` | Gitea, PostgreSQL, Valkey |
| `immich/` | `immich` | `0.1.11` | `3.3.5` | Immich, vectorchord PostgreSQL, Valkey |
| `homebox/` | `homebox` | `0.1.1` | `0.27.1` | HomeBox, SQLite |
| `nextcloud/` | `nextcloud` | `0.1.20` | `35.0.2` | Nextcloud, PostgreSQL, Valkey, Collabora |
| `mealie/` | `mealie` | `0.1.4` | `3.30.0` | Mealie, PostgreSQL |
| `sparkyfitness/` | `sparkyfitness` | `0.1.1` | `1.11.0` | SparkyFitness (source-available, non-commercial), PostgreSQL |
| `paperless/` | `paperless` | `0.1.13` | `3.4.1` | Paperless-ngx, PostgreSQL, Valkey |
| `servarr/` | `servarr` | `0.3.3` | `1.0.0` | Seerr, Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent, FlareSolverr |
| `vaultwarden/` | `vaultwarden` | `0.1.2` | `1.37.5` | Vaultwarden (Bitwarden-compatible password manager), SQLite |

Each chart is UMKIM-tailored: it carries the route/auth/bootstrap assumptions
the platform expects, not only the upstream application.

## Use from umkim-thin

The `umkim-thin` catalog installs these charts through the console. It supplies
the site-specific values that the standalone examples leave empty:

- `auth.ldap.*` and the bind Secret for Gitea/Nextcloud/Jellyfin;
- Authelia OIDC client id/secret/issuer for Immich/Paperless/Gitea;
- `persistence.*.storageClass` from the selected config/media classes;
- `hostAliases` so the pod can reach its own public host and the portal.

The chart `ingress` is optional and used by standalone installs; the platform
creates the Traefik route itself. Storage-class defaults in these charts are
standalone examples; the catalog always overrides them with the site's config
and media classes.

## Release model

- Each chart has its own version in `Chart.yaml`; bump it for any template,
  image, sidecar or default change.
- A chart change is a PR in this repository. Before merging, run the lint,
  render and package commands below.
- A chart release is a version bump and a commit in this repository. The
  platform's `charts/apps` submodule pin and the catalog entry's `version` are
  the release; the installer packages the chart into the local mirror. Never
  reuse a chart version.
- Publish a catalog release in umkim-thin that lists the new version (and
  `minimumUmkimThinVersion` if the chart needs a newer console). This is a
  catalog upload, not a platform image rebuild.
- The `charts/apps` submodule can be refreshed independently. A platform
  release only needs the submodule bump when the bundled mirror should include
  the new chart.

To refresh the platform fallback:

```bash
cd charts/apps
git fetch
git switch --detach <chart-repo-commit-or-tag>
cd ../..
git add charts/apps
git commit -m "chart(gitea): update the offline fallback"
```

Then update `catalog/<app>.yaml` if the bundled catalog should point at it.
The chart source/version and an uploaded catalog are independent trains; the
mirror package is what installs.

## Development

Contributors with an SSH key can clone this repository directly:

```bash
git clone git@github.com:rborso/umkim-charts.git
```

```bash
for chart in actualbudget gitea homebox immich mealie nextcloud paperless sparkyfitness servarr vaultwarden; do
  helm lint "$chart"
  helm package "$chart" --destination /tmp/charts
done
```

The charts are Apache-2.0. The applications they deploy keep their own
licenses; see [`LICENSES.md`](LICENSES.md).

## License

Apache-2.0. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
