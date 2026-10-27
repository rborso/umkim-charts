# SparkyFitness

A UMKIM-tailored chart for [SparkyFitness](https://github.com/CodeWithCJ/SparkyFitness):
the frontend, the API server and PostgreSQL, with Authelia OIDC and the
Mealie recipe provider reachable inside the cluster.

The catalog entry installs the public `ghcr.io/codewithcj/sparkyfitness-*`
images pinned to `v1.9.0`. The chart itself is Apache-2.0, but **SparkyFitness
is not OSI open source**: its `LICENSE` is a source-available, non-commercial
license. Commercial use needs written permission from the upstream author. See
`docs/licenses.md` in umkim-thin.

## Install

The catalog supplies the public URL, the OIDC client and storage classes. A
standalone render needs at least the URL and, for OIDC, the client:

```bash
helm install sparkyfitness . \
  --namespace sparkyfitness --create-namespace \
  --set externalUrl=https://sparkyfitness.example.com \
  --set oidc.enabled=true \
  --set oidc.issuerUrl=https://auth.example.com \
  --set oidc.clientId=sparkyfitness \
  --set oidc.clientSecret='...' \
  --set server.adminEmail=admin@example.com
```

Register this exact redirect URI in the identity provider:

```
https://sparkyfitness.example.com/api/auth/sso/callback/authelia
```

The slug comes from `oidc.providerSlug` (`authelia` by default). SparkyFitness
stores the provider in its database on startup and the bootstrap Job checks
that it appears in `/api/auth/settings`.

`server.adminEmail` receives the admin panel. The catalog sets it to the
directory admin's address, so the first OIDC login with that account is an
administrator. OIDC auto-registration requires `server.disableSignup: false`;
if signups are disabled, new OIDC accounts cannot be created.

The chart creates a combined CA bundle for the server, so Authelia's certificate
is trusted both with public ACME certificates and with the lab CA. UMKIM also
adds `hostAliases` pointing the public host and the portal at Traefik.

## Mealie recipes

SparkyFitness has a built-in **Mealie** external food provider. When both apps
are installed, recipes are imported into SparkyFitness; they are not copied back
to Mealie. The catalog sets
`server.allowPrivateNetworkFoodProviders: true` because Mealie is reached at its
cluster Service address. That is an intentional SSRF trade-off for this
single-tenant platform; use a global provider if you do not want to allow
non-admin users to add arbitrary private URLs.

1. Install Mealie first (catalog namespace and release both `mealie`).
2. In Mealie, open the user menu -> **API Tokens** and create a token for the
   SparkyFitness provider. Keep it out of ConfigMaps and chat.
3. In SparkyFitness open **Settings -> Food & Exercise Data Providers** and add
   a **Mealie** provider:
   - Base URL: `http://mealie.mealie.svc.cluster.local:9000`
   - API token: the token from step 2
4. Alternatively, an administrator can add the same provider once in
   **Admin -> Global Data Providers** so every user can search it without
   creating a personal token.
5. Search for a recipe in SparkyFitness's food search, choose it, and log it or
   save it as a food. SparkyFitness maps Mealie's per-serving nutrition and
   image.

To have the bootstrap Job verify Mealie as well, set:

```yaml
integrations:
  mealie:
    enabled: true
    baseUrl: http://mealie.mealie.svc.cluster.local:9000
```

The Job only performs a readiness check. It never stores the Mealie token.

## Storage

`persistence.uploads` (avatars and food images) and `persistence.backup`
(database exports) are separate ReadWriteOnce claims; PostgreSQL has its own
claim. The catalog wires all three to the site's config storage class.

## Health and startup

The server runs migrations before it listens. Its startup probe allows five
minutes; the liveness probe only begins after the startup probe succeeds. The
post-install Job waits for `/api/health` and the OIDC provider registration.
