# Actual Budget

A UMKIM-tailored chart for [Actual Budget](https://actualbudget.org): the sync
server and its SQLite database, with Authelia OIDC.

Actual Budget is MIT-licensed. See `docs/licenses.md` in umkim-thin.

## Install

The catalog supplies the public URL and OIDC client. A standalone render needs
at least:

```bash
helm install actualbudget . \
  --namespace actualbudget --create-namespace \
  --set externalUrl=https://actual.example.com \
  --set oidc.enabled=true \
  --set oidc.issuerUrl=https://auth.example.com \
  --set oidc.clientId=actualbudget \
  --set oidc.clientSecret='...' \
  --set persistence.data.storageClass=longhorn-rwo
```

Register this exact redirect URI in the identity provider:

```
https://actual.example.com/openid/callback
```

The chart uses Authelia's OAuth2 flow (`oidc.authMethod: oauth2`), which is the
flow documented by the Authelia integration guide. The first OIDC login becomes
the Actual server owner; `oidc.userCreationMode: login` creates later users on
first login.

The container runs as the image's `actual` user (UID 1001) with a read-only
root filesystem. Only `/data` (SQLite database, budget blobs and server files)
and `/tmp` are writable. The chart builds a Node CA bundle from Node's built-in
roots plus the optional `umkim-thin-ca` ConfigMap, so discovery and token
requests trust both public ACME certificates and the lab CA.

## Data and recovery

`/data` is a ReadWriteOnce PVC. Back up the whole directory; it contains
`account.sqlite` and the budget files.

If OIDC is unavailable, an operator can run the image's password reset inside
the pod:

```bash
kubectl -n actualbudget exec deploy/actualbudget -- \
  node app.js --reset-password
```

This is a breakglass operation; it changes the local password storage and
should be followed by inspecting the OIDC configuration.
