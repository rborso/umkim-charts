# HomeBox

A UMKIM-tailored chart for [HomeBox](https://homebox.software): the home
inventory app with SQLite and Authelia OIDC.

HomeBox is AGPL-3.0. See `docs/licenses.md` in umkim-thin.

## Install

The catalog supplies the public URL and OIDC client. A standalone render needs
at least:

```bash
helm install homebox . \
  --namespace homebox --create-namespace \
  --set externalUrl=https://homebox.example.com \
  --set hostname=homebox.example.com \
  --set oidc.enabled=true \
  --set oidc.issuerUrl=https://auth.example.com \
  --set oidc.clientId=homebox \
  --set oidc.clientSecret='...' \
  --set persistence.data.storageClass=longhorn-rwo
```

Register this exact redirect URI in the identity provider:

```
https://homebox.example.com/api/v1/users/login/oidc/callback
```

`hostname` must be the hostname only, without `https://`; it is used for
absolute OIDC callback URLs. The chart derives it from `externalUrl` when it is
empty.

The image is the upstream **rootless** variant (UID 65532). Only `/data` and
`/tmp` are writable. `/data` contains `homebox.db`, uploads and thumbnails.
OIDC users are created on first login; local registration is disabled by
default. Local login stays enabled as a breakglass path, but no local account
is created automatically.

## OIDC

The chart sets `HBOX_OIDC_SCOPE=openid profile email`, does not require an
`email_verified` claim (Authelia's directory users do not need it), and uses the
display text `Authelia` for the login button. Group restriction is available
through `oidc.allowedGroups`; it needs the `groups` scope when enabled.

The init container builds a CA bundle from the image's public roots plus the
optional `umkim-thin-ca` ConfigMap. HomeBox (Go) reads it through
`SSL_CERT_FILE`, so discovery, token and userinfo requests trust both public
ACME certificates and the lab CA.
