# gitea-helm

UMKIM-tailored Gitea stack. Self-contained Helm chart:

- Gitea 28 (web UI, Git HTTP/SSH, background workers in one binary)
- PostgreSQL 18
- valkey (cache, sessions, queue)

A post-install bootstrap creates the local admin and registers **LLDAP** as an
LDAP authentication source, so directory users sign in to Gitea with their
existing credentials — no second account. In `umkim-thin` the catalog also
supplies the LDAP bind Secret, OIDC client values and storage classes.

## Install

```sh
helm upgrade --install gitea . -n gitea --create-namespace \
  --set gitea.externalUrl=https://gitea.example.com \
  --set ingress.enabled=true --set ingress.host=gitea.example.com
```

Generated admin password (and DB password):

```sh
kubectl -n gitea get secret gitea-secrets -o jsonpath='{.data.admin-password}' | base64 -d
```

## Directory authentication (LLDAP)

Gitea speaks LDAP natively, so directory users are authenticated straight against
LLDAP. Create a bind secret from the directory service account, then point the
chart at it:

```sh
# <identity-namespace> is `identity` in umkim-thin.
IDENTITY_NS=${IDENTITY_NS:-identity}
BIND=$(kubectl -n "$IDENTITY_NS" get secret lldap-service-accounts \
  -o jsonpath='{.data.password}' | base64 -d)
kubectl -n gitea create secret generic gitea-lldap-bind \
  --from-literal=LLDAP_LDAP_USER_PASS="$BIND" \
  --dry-run=client -o yaml | kubectl apply -f -
```

```sh
helm upgrade --install gitea . -n gitea \
  --set auth.ldap.enabled=true \
  --set auth.ldap.host=lldap.identity.svc.cluster.local \
  --set auth.ldap.port=3890 \
  --set auth.ldap.bindDn='uid=svc-bind,ou=people,dc=example,dc=com' \
  --set auth.ldap.userSearchBase='ou=people,dc=example,dc=com' \
  --set auth.ldap.existingSecret=gitea-lldap-bind
```

The catalog path does this automatically; the manual snippet is for a
standalone chart install.

The bootstrap runs `gitea admin auth add-ldap` with those values. Existing
sources are left alone (the bootstrap is idempotent), so re-running it after an
upgrade is safe.

### Attribute mapping

| Gitea | LLDAP attribute |
| --- | --- |
| username | `uid` |
| email | `mail` |
| first name | `cn` (LLDAP's display name) |
| surname | `sn` (often absent; Gitea then shows just the display name) |

`userFilter` defaults to `(&(objectClass=person)(uid=%s))`, which matches LLDAP's
`person` objects. Directories that expose `givenName`/`sn` can override
`auth.ldap.firstnameAttribute` / `surnameAttribute`.

### SSH keys from the directory

Set `auth.ldap.publicSshKeyAttribute` (default `sshPublicKey`) and Gitea treats
that attribute as the user's SSH public key(s):

- On every login Gitea reads the attribute and **synchronises** it into the
  user's keys: new keys are added, and keys that came from this source and were
  removed from the directory are deleted.
- Keys added in Gitea itself (Settings → SSH keys, or the API) are **not**
  touched — they have no login source, so the sync ignores them.
- Directory-sourced keys are marked *externally managed*: visible in Gitea but
  not deletable there (remove them in the directory instead).
- The attribute may hold several keys (LLDAP: `isList: true`).
- `auth.ldap.sshKeysAreVerified` (default true) marks them verified.

The umkim fleet's `fleet-console` chart ships the attribute; umkim-thin's
identity chart uses the same `lldap.bootstrap.userSchemas` contract. LLDAP is
case-insensitive on the wire, so the standard `sshPublicKey` spelling works even
though LLDAP stores it lowercase.

## Git over SSH

Gitea's built-in SSH server listens on `gitea.ssh.listenPort` (2222). It is not
HTTP, so it needs a TCP path.

**umkim-thin.** The catalog configures Traefik's `gitssh` entrypoint (public
2222, NodePort 30222) and Gitea advertises `ssh://git@gitea.<zone>:2222/...`;
the chart does not need `ingress.enabled` for this.

**With UMKIM (fleet).** Publish the SSH Service as a NodePort and let UMKIM
forward it to the hub, so clients never touch a node address:

```sh
helm upgrade --install gitea . -n gitea \
  --set gitea.ssh.service.type=NodePort \
  --set gitea.ssh.service.nodePort=32222 \
  --set gitea.ssh.advertisedPort=2222 \
  --set gitea.ssh.domain=<app-host>
```

then give the app a `tcp` route (`protocol: tcp`, `forwardPort: 2222`,
`servicePort: 32222`). UMKIM runs a port-forwarder on the hub that dials the
NodePort over the WireGuard overlay. Set `advertisedPort` to the route's
`forwardPort` so the clone URL Gitea shows is the one clients actually use —
`ssh://git@<app-host>:2222/<owner>/<repo>.git`. See
[fleet-apps.md](https://github.com/rborso/umkim/blob/main/docs/components/fleet-apps.md).

**Standalone.** Without UMKIM, expose the NodePort and set `gitea.ssh.domain` to
the address clients reach:

- `gitea.ssh.listenPort` — container port (and Service port).
- `gitea.ssh.service.type` / `nodePort` — `NodePort` makes the port reachable on
  the node address.
- `gitea.ssh.advertisedPort` — port in the clone URL; defaults to the NodePort,
  else `listenPort`.
- `gitea.ssh.domain` — host in the clone URL; defaults to the route host.

Register an SSH key on the user (Settings → SSH / GPG keys, or
`POST /api/v1/user/keys`), then:

```sh
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519 -p 2222 -o StrictHostKeyChecking=accept-new" \
  git clone ssh://git@<hub-host>:2222/<owner>/<repo>.git
```

## Optional Authelia first-line defense

`ingress.forwardAuth=true` chains the Authelia forward-auth middleware so the
whole host is gated before Gitea is reached. In the umkim fleet, set
`ingress.forwardAuth: ${FORWARD_AUTH}`; in umkim-thin the console creates the
route and its middleware, so the chart ingress is optional. Gitea's own LDAP
login still applies afterwards.

## Values

See `values.yaml`. Notable: `auth.ldap.*`, `gitea.ssh.*`,
`gitea.persistence.data`, `postgres.persistence`, `redis.enabled`,
`bootstrap.*`, `ingress.*`.

## Verification

- `GET /api/healthz` returns `{"status":"pass"}`.
- The bootstrap Job log ends with `bootstrap complete`.
- A directory user can sign in on the login page (the LDAP source appears there).

## Language

The chart sets Gitea's `[i18n] LANGS`/`NAMES` list with `en-US` first by
default. Gitea uses a matching browser locale when available; the first entry
is the fallback. The console install form can reorder the fallback. A selected
locale does not force every browser to that language.

## License

The chart source is Apache-2.0, part of umkim-thin. The deployed images keep
their upstream licenses:

| Component | License | Source |
|---|---|---|
| Gitea | MIT | https://github.com/go-gitea/gitea |
| PostgreSQL | PostgreSQL License | https://www.postgresql.org/about/licence/ |
| Valkey | BSD-3-Clause | https://github.com/valkey-io/valkey |

See [`../LICENSES.md`](../LICENSES.md).
