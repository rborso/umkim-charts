# Vaultwarden

A UMKIM-tailored chart for [Vaultwarden](https://github.com/dani-garcia/vaultwarden),
the Bitwarden-compatible password manager. SQLite lives on one
ReadWriteOnce volume.

Vaultwarden is AGPL-3.0. See `docs/licenses.md` in umkim-thin.

## Install

The catalog supplies the public URL and storage class. A standalone render
needs at least:

```bash
helm install vaultwarden . \
  --namespace vaultwarden --create-namespace \
  --set externalUrl=https://vaultwarden.example.com \
  --set persistence.data.storageClass=longhorn-rwo
```

The container runs as UID 1000 and listens on port 8080; the Service exposes
8080. The image is pinned to `vaultwarden/server:1.37.5`.

## First account and signups

The first account has to be created in the web vault. `signupsAllowed` is
therefore `true` by default. After creating the household accounts, set it to
`false` and use Vaultwarden invitations (or the admin page) for new users:

```bash
helm upgrade vaultwarden . --namespace vaultwarden \
  --reuse-values --set signupsAllowed=false
```

The admin page is `/admin`. The chart generates a 48-character `ADMIN_TOKEN`
and preserves it across upgrades; read it with:

```bash
kubectl -n vaultwarden get secret vaultwarden-secrets \
  -o jsonpath='{.data.admin-token}' | base64 -d
```

## Authentication

Vaultwarden can use Authelia as an OpenID Connect identity provider. The
catalog registers the client and fills `sso.*`; the chart enables `SSO_ONLY`
for the platform install:

```text
SSO_ENABLED=true
SSO_ONLY=true
SSO_AUTHORITY=https://auth.example.com
SSO_CLIENT_ID=vaultwarden
SSO_CLIENT_SECRET=...
SSO_SCOPES=openid profile email offline_access
SSO_SIGNUPS_ALLOWED=true
SSO_SIGNUPS_MATCH_EMAIL=false
```

The redirect URI is `https://vaultwarden.example.com/identity/connect/oidc-signin`.
Only an Authelia identity can sign in to a vault; local signup and local login
are disabled. The first SSO login creates the Vaultwarden account, then the
user sets the **master password in the client**. SSO authenticates the user; it
never supplies the vault encryption key, and the admin cannot reset it.

The chart builds a CA bundle from the image roots plus the platform
`umkim-thin-ca` ConfigMap and points `SSL_CERT_FILE`/`SSL_CERT_DIR` at it. This
is required for the SSO discovery and token exchange against a lab-CA
certificate. `hostAliases` points the portal at Traefik inside the cluster; the
catalog sets both.

The public route is additionally behind Authelia forward-auth. The trusted
VPN/management paths skip that portal gate, but `SSO_ONLY` still requires an
Authelia login at Vaultwarden itself. `/admin` remains a separate server
management surface protected by `ADMIN_TOKEN` and cannot decrypt vaults.

Keep `SSO_ONLY=false` during a migration if native clients have not been
verified against the Vaultwarden OIDC flow. The web vault is covered by the
platform journey; extension/mobile support must be checked before enforcing
SSO-only access.

The app is a single Deployment with `Recreate`, because SQLite and the `/data`
volume are ReadWriteOnce. Back up `/data` (database, attachments, RSA keys)
before upgrades; the platform's application backup covers the PVC.

## Values

| Value | Default | Purpose |
|---|---|---|
| `image` | `docker.io/vaultwarden/server:1.37.5` | Pinned application image |
| `port` | `8080` | Container Service port |
| `externalUrl` | empty | Public URL, normally supplied by the catalog |
| `persistence.data.size` | `5Gi` | SQLite, attachments and keys |
| `persistence.data.storageClass` | cluster default | Data volume class |
| `signupsAllowed` | `true` | First-account bootstrap; turn off after setup |
| `signupsVerify` | `false` | No SMTP in the default install |
| `invitationsAllowed` | `true` | Invite additional household users |
| `adminToken` | generated | `/admin` token; preserved in the release Secret |

## License

The chart source is Apache-2.0. Vaultwarden is AGPL-3.0; see `LICENSES.md` in
the chart repository and `docs/licenses.md` in the platform repository.
