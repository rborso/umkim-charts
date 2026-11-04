# umkim-charts

The official app charts for [umkim-thin](https://github.com/rborso/umkim-thin).

This repository is the source of the charts the catalog pins. Each chart is
released independently as an immutable OCI tag
(`helm push ... oci://ghcr.io/rborso/charts`), so a chart update does not require
a platform/console release. The platform repo consumes it as a git submodule at
`charts/apps/` and packages those charts into the local mirror. The submodule
and mirror are the development/offline fallback; the OCI tag is the production
delivery path.

The catalog entries keep OCI references as canonical metadata. The console uses
a locally cached chart for the exact version first, then pulls the OCI ref with
that exact `--version`.

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
| `servarr/` | `servarr` | `0.3.2` | `1.0.0` | Seerr, Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent, FlareSolverr |
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
- Publish each version as an immutable OCI tag:

  ```bash
  helm package <chart> --destination dist
  helm push dist/<chart>-<version>.tgz oci://ghcr.io/rborso/charts
  ```

  Never reuse a chart version, and never move an existing tag.
- Publish a catalog release in umkim-thin that lists the new version (and
  `minimumUmkimThinVersion` if the chart needs a newer console). This is a
  catalog upload, not a platform image rebuild.
- The `charts/apps` submodule can be refreshed independently as the offline
  fallback. A platform release only needs the submodule bump when the bundled
  fallback should include the new chart.

To refresh the platform fallback:

```bash
cd charts/apps
git fetch
git switch --detach <chart-repo-commit-or-tag>
cd ../..
git add charts/apps
git commit -m "chart(gitea): update the offline fallback"
```

Then update `catalog/<app>.yaml` if the fallback catalog should point at it.
The production path is the OCI tag plus an uploaded catalog; neither requires
the other train to release.

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
