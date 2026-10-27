# mealie

Mealie recipe manager with PostgreSQL and Authelia OIDC.

## What it runs

- the pinned `mealie-recipes/mealie` image;
- a PostgreSQL database;
- a local breakglass admin, created once by the bootstrap Job;
- OIDC login for directory users through Authelia.

The local admin password is generated into the release Secret and the bootstrap
Job changes Mealie's initial `MyPassword` before the install is reported
complete.

## Values

| Value | Default | Purpose |
|---|---|---|
| `image` | `ghcr.io/mealie-recipes/mealie:v3.22.0` | Application image |
| `externalUrl` | empty | Public URL, normally supplied by the catalog |
| `persistence.data.storageClass` | cluster default | Mealie data |
| `postgres.persistence.storageClass` | cluster default | PostgreSQL data |
| `bootstrap.adminEmail` | `mealie-admin@mealie.local` | Breakglass admin email |
| `bootstrap.adminPassword` | generated | Breakglass admin password |
| `oidc.enabled` | false | Enable Authelia OIDC |
| `oidc.issuerUrl` | empty | Authelia issuer |
| `oidc.clientId` / `oidc.clientSecret` | empty | OIDC client |
| `oidc.requireEmailVerification` | false | Accept Authelia's directory claims |

## Notes

- The route is behind Authelia; Mealie also has its own OIDC login.
- The local admin remains available for setup and breakglass access.
- Mealie's UI language is browser/user-driven; there is no server-side default.
- Mealie is AGPL-3.0; see the platform license matrix.

## License

The chart source is Apache-2.0. The Mealie application keeps its AGPL-3.0
license; see `LICENSES.md` in the chart repository and
`docs/licenses.md` in the platform repository.
