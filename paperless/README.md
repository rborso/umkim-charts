# paperless-helm

UMKIM-tailored Paperless-ngx stack. Self-contained Helm chart:

- paperless-ngx (webserver + consumer + scheduler in one container)
- PostgreSQL
- valkey (Redis broker)

A post-install bootstrap seeds tags and verifies the admin login. SSO uses
OIDC (Authelia backed by LLDAP) via django-allauth. The Authelia "first line
defense" (forward-auth) is an optional toggle. In `umkim-thin` the catalog
supplies the Authelia client, OIDC issuer, CA bundle/host aliases and storage
classes; the chart ingress is optional.

## Install

```sh
helm upgrade --install paperless . -n paperless --create-namespace \
  --set admin.mail=admin@example.com \
  --set externalUrl=https://paperless.example.com \
  --set ingress.enabled=true --set ingress.host=paperless.example.com
```

Generated admin password (and DB password, secret key):

```sh
kubectl -n paperless get secret paperless-secrets -o jsonpath='{.data.admin-password}' | base64 -d
```

## Optional Authelia first-line defense

```sh
--set ingress.forwardAuth=true
```

Gates the whole host behind Authelia before Paperless is reached. In the umkim
fleet, set `ingress.forwardAuth: ${FORWARD_AUTH}`. In umkim-thin the console
creates the route and its `identity-authelia@file` middleware, so the chart
ingress can stay disabled.

## SSO (LLDAP via Authelia OIDC)

Paperless-ngx has no native LDAP; it uses django-allauth with OIDC. Authelia is
the OIDC provider with LLDAP as its backend.

1. Register an Authelia OIDC client for `paperless` with the redirect URI
   `https://<paperless-host>/accounts/oidc/<provider_id>/login/callback/`
   (the provider id defaults to `authelia`), `requirePkce: false` (allauth does
   not send a code_challenge).
2. Install with:

```sh
helm upgrade --install paperless . -n paperless \
  --set oidc.enabled=true \
  --set oidc.issuerUrl=https://auth.example.com \
  --set oidc.clientId=paperless \
  --set oidc.clientSecret=<secret> \
  --set 'hostAliases[0].ip=<in-cluster-ingress-ip>' \
  --set 'hostAliases[0].hostnames[0]=auth.example.com'
```

The catalog path generates the client and supplies `oidc.*`, the combined CA
bundle and `hostAliases` automatically; do not hand-write `${OIDC_*}` values in
umkim-thin.

## Values

See `values.yaml`. Notable: `bootstrap.tags`, `ingress.forwardAuth`, `oidc.*`,
`persistence.*`.

## License

The chart source is Apache-2.0, part of umkim-thin. The deployed images keep
their upstream licenses:

| Component | License | Source |
|---|---|---|
| Paperless-ngx | GPL-3.0 | https://github.com/paperless-ngx/paperless-ngx |
| PostgreSQL | PostgreSQL License | https://www.postgresql.org/about/licence/ |
| Valkey | BSD-3-Clause | https://github.com/valkey-io/valkey |

See [`../LICENSES.md`](../LICENSES.md).
