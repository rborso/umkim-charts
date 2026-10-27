# immich-helm

UMKIM-tailored Immich stack. Self-contained Helm chart:

- `immich-server` (upstream image)
- vectorchord Postgres (Immich's `ghcr.io/immich-app/postgres`)
- valkey (Redis)
- optional machine learning component (disabled by default — no AI features)

A post-install bootstrap creates the local admin, optionally wires SSO (OIDC via
Authelia backed by LLDAP), and can disable local password login once SSO works.
In `umkim-thin` the catalog supplies the OIDC client, issuer and storage class;
the chart's `ingress` is optional because the console creates the route.

## Install

```sh
helm upgrade --install immich . \
  --namespace immich --create-namespace \
  --set bootstrap.admin.email=admin@example.com
```

The generated admin password (and DB password) live in the `<release>-secrets`
Secret:

```sh
kubectl -n immich get secret immich-secrets -o jsonpath='{.data.admin-password}' | base64 -d
```

## SSO (LLDAP via Authelia OIDC)

Immich has **no native LDAP**; it authenticates via OpenID Connect. To use the
platform directory, Authelia acts as the OIDC provider with LLDAP as its
backend.

1. Configure an Authelia OIDC client for Immich (`authelia.oidc.clients` in the
   identity chart, namespace `identity` in umkim-thin) with redirect URIs:

   - `https://<immich-host>/auth/login`
   - `https://<immich-host>/user-settings`
   - `app.immich:///oauth-callback`

2. Install with the OAuth values:

   ```sh
   helm upgrade --install immich . -n immich \
     --set bootstrap.oauth.enabled=true \
     --set bootstrap.oauth.issuerUrl=https://auth.example.com \
     --set bootstrap.oauth.clientId=immich \
     --set bootstrap.oauth.clientSecret=<secret>
   ```

The bootstrap sets the OAuth config through `/api/system-config` after creating
the admin, so users can sign in with their directory account.

## Forward-auth (Authelia) in front of Immich

The Authelia forward-auth gate is an **optional** "first line defense". Turn it
on per install with `ingress.forwardAuth`:

```sh
# gate the app behind Authelia (login page included)
helm upgrade --install immich . -n immich \
  --set ingress.enabled=true --set ingress.host=immich.example.com \
  --set ingress.forwardAuth=true

# or rely on Immich's own login/OIDC only
helm upgrade --install immich . -n immich \
  --set ingress.enabled=true --set ingress.host=immich.example.com \
  --set ingress.forwardAuth=false
```

`ingress.forwardAuthMiddleware` (default `fleet-ingress-authelia@file`) names
the middleware from the umkim fleet chart. In `umkim-thin` the console creates
the route and uses `identity-authelia@file`; the chart ingress is not used.
`ingress.middlewares` chains extra middlewares after it.

When on, everything on the host (including the Immich API and mobile app) is
behind Authelia, so clients that cannot do the browser redirect are blocked
unless their paths are excluded. Immich's own login/OIDC still applies after
the Authelia session.

## Values

See `values.yaml`. Notable: `immich.machineLearning.enabled` (AI off by
default), `immich.persistence.data`, `postgres.persistence`, `bootstrap.*`,
`ingress.middlewares`.

## Verification

The bootstrap creates the admin and (when enabled) configures SSO. Verify:

- `GET /api/server/ping` returns `{"res":"pong"}`.
- Admin login (`POST /api/auth/login`) succeeds.
- A directory user completes the OIDC login.

## License

The chart source is Apache-2.0, part of umkim-thin. The deployed images keep
their upstream licenses:

| Component | License | Source |
|---|---|---|
| Immich | AGPL-3.0 | https://github.com/immich-app/immich |
| VectorChord | AGPL-3.0 or Elastic-2.0 | https://github.com/tensorchord/VectorChord |
| PostgreSQL | PostgreSQL License | https://www.postgresql.org/about/licence/ |
| Valkey | BSD-3-Clause | https://github.com/valkey-io/valkey |

See [`../LICENSES.md`](../LICENSES.md).
