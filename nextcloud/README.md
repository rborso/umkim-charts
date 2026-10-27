# nextcloud-helm

UMKIM-tailored Nextcloud stack with Collabora Online. Self-contained Helm chart:

- Nextcloud 35 (Apache image)
- PostgreSQL 18
- valkey (cache + file locking)
- Collabora Online (CODE) — optional

A post-install bootstrap sets the trusted domains and overwrite URL, registers
the directory (**LLDAP**) as the LDAP backend (`user_ldap`) when enabled, and
wires the `richdocuments` app to Collabora. In `umkim-thin` the catalog supplies
the LDAP bind Secret and storage classes; the chart's optional `oidc` mode is
disabled there (see the platform auth docs).

## Install

```sh
helm upgrade --install nextcloud . -n nextcloud --create-namespace \
  --set nextcloud.externalUrl=https://nextcloud.example.com \
  --set ingress.enabled=true --set ingress.host=nextcloud.example.com
```

Generated admin password (and DB password):

```sh
kubectl -n nextcloud get secret nextcloud-secrets -o jsonpath='{.data.admin-password}' | base64 -d
```

The admin user is `bootstrap.admin.username` (default `nc-admin`); the upstream
image creates it on first boot.

## Directory authentication (LLDAP)

Nextcloud has no native LDAP bundled — the `user_ldap` app is enabled and
configured by the bootstrap. Create a bind secret from the directory service
account, then point the chart at it:

```sh
IDENTITY_NS=${IDENTITY_NS:-identity}
BIND=$(kubectl -n "$IDENTITY_NS" get secret lldap-service-accounts \
  -o jsonpath='{.data.password}' | base64 -d)
kubectl -n nextcloud create secret generic nextcloud-lldap-bind \
  --from-literal=LLDAP_LDAP_USER_PASS="$BIND" \
  --dry-run=client -o yaml | kubectl apply -f -
```

```sh
helm upgrade --install nextcloud . -n nextcloud \
  --set auth.ldap.enabled=true \
  --set auth.ldap.host=lldap.identity.svc.cluster.local \
  --set auth.ldap.port=3890 \
  --set auth.ldap.bindDn='uid=svc-bind,ou=people,dc=example,dc=com' \
  --set auth.ldap.baseDn='ou=people,dc=example,dc=com' \
  --set auth.ldap.existingSecret=nextcloud-lldap-bind
```

The bootstrap creates the LDAP configuration (`s01`), fills the LLDAP-specific
options, activates it, and runs `occ ldap:test-config`. Directory users then log
in with their existing credentials.

### Attribute mapping

| Nextcloud | LLDAP attribute |
| --- | --- |
| login / username | `uid` |
| display name | `cn` |
| email | `mail` |

`userFilter` defaults to `(&(objectClass=person))` (Nextcloud's static "all users"
filter) and `loginFilter` to `(&(objectClass=person)(uid=%uid))` — the login one
carries the `%uid` placeholder. Both match LLDAP's `person` objects.

## Collabora Online

Give Collabora its own route and set the public URL so the browser can load the
editor:

```yaml
collabora:
  enabled: true
  publicUrl: https://collabora.example.com
  aliasGroup: https://nextcloud.example.com
```

The bootstrap enables `richdocuments` and points `wopi_url` /
`public_wopi_url` at `collabora.publicUrl`. `aliasGroup` (`aliasgroup1`) is the
Nextcloud URL allowed to use this Collabora. Collabora runs with
`--o:ssl.enable=false --o:ssl.termination=true` because the platform ingress
(Traefik) terminates TLS in front of it.

Without a route, `publicUrl` falls back to the in-cluster Service URL — document
preview works, browser editing does not.

## Values

See `values.yaml`. Notable: `auth.ldap.*`, `collabora.*`,
`nextcloud.persistence.data`, `nextcloud.trustedDomains`,
`nextcloud.trustedProxies`, `postgres.persistence`, `redis.enabled`,
`bootstrap.*`, `ingress.*`, and `hostAliases`. The platform sets
`hostAliases` so the server **and Collabora** resolve the public Nextcloud
hostname to Traefik inside the cluster; without it, Collabora's WOPI request can
loop through NAT and return the router's RFC1918 rejection page.

## Verification

- `GET /status.php` returns `{"installed":true,...}`.
- The bootstrap Job log ends with `bootstrap complete`.
- A directory user signs in on the login page.
- Opening a document offers **Open with Collabora**.

## Language

`bootstrap.language` (default `en`) sets Nextcloud's default language for new
users and the local admin during bootstrap. Existing users keep their own
language. The console install form exposes the same setting.

## License

The chart source is Apache-2.0, part of umkim-thin. The deployed images keep
their upstream licenses:

| Component | License | Source |
|---|---|---|
| Nextcloud | AGPL-3.0 | https://github.com/nextcloud/server |
| Collabora Online | MPL-2.0 | https://github.com/CollaboraOnline/online |
| PostgreSQL | PostgreSQL License | https://www.postgresql.org/about/licence/ |
| Valkey | BSD-3-Clause | https://github.com/valkey-io/valkey |

See [`../LICENSES.md`](../LICENSES.md).
