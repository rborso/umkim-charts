# umkim-charts

The official app charts for [umkim-thin](https://github.com/rborso/umkim-thin).

This repository is the source of the charts the catalog pins. The platform repo
consumes it as a git submodule at `charts/apps/` and packages those charts into
the local mirror. Charts are not published as a required artifact.

The catalog entries keep OCI references as canonical metadata, but an offline
install uses the submodule/local mirror.

## Charts

| Directory | Chart | Upstream application |
|---|---|---|
| `gitea/` | `gitea` | Gitea, PostgreSQL, Valkey |
| `immich/` | `immich` | Immich, vectorchord PostgreSQL, Valkey |
| `nextcloud/` | `nextcloud` | Nextcloud, PostgreSQL, Valkey, Collabora |
| `mealie/` | `mealie` | Mealie, PostgreSQL |
| `sparkyfitness/` | `sparkyfitness` | SparkyFitness (source-available, non-commercial), PostgreSQL |
| `paperless/` | `paperless` | Paperless-ngx, PostgreSQL, Valkey |
| `servarr/` | `servarr` | Seerr, Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent, FlareSolverr |

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

- Each chart has its own version in `Chart.yaml`.
- A chart change is a PR in this repository.
- Before a PR, run the lint, render and package commands below; nothing is
  published.
- The consumer pins the **submodule commit** and the matching catalog chart
  version in the same umkim-thin PR. Run the catalog contract render in that
  companion PR.
- No chart tag or registry publication is required for installation; the
  packaged local mirror is the delivery path.

The platform keeps `charts/apps` as a pinned submodule. To update the platform to
a newer chart release:

```bash
cd charts/apps
git fetch
git switch --detach <chart-repo-commit-or-tag>
cd ../..
git add charts/apps
git commit -m "chart(gitea): update to 0.1.20"
```

Then bump `catalog/<app>.yaml` to the same chart version and run the platform
checks. A chart change and its consumer pin belong in a paired review; neither
side is a release by itself.

## Development

Contributors with an SSH key can clone this repository directly:

```bash
git clone git@github.com:rborso/umkim-charts.git
```

```bash
for chart in gitea immich nextcloud paperless sparkyfitness servarr; do
  helm lint "$chart"
  helm package "$chart" --destination /tmp/charts
done
```

The charts are Apache-2.0. The applications they deploy keep their own
licenses; see [`LICENSES.md`](LICENSES.md).

## License

Apache-2.0. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
