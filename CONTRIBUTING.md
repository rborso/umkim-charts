# Contributing

This repository contains the official UMKIM app charts. The platform, catalog,
console and acceptance tests live in
[umkim-thin](https://github.com/rborso/umkim-thin).

By participating you agree to [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md). There
is no CLA: contributions are under Apache-2.0.

## Changing a chart

1. Edit the chart under `<app>/` and bump its `Chart.yaml` version.
2. Keep the chart's route/auth/bootstrap assumptions compatible with the
   umkim-thin catalog contract. The catalog entry is the platform-side pin; it
   is not stored here yet.
3. Record the upstream project/license if you add a component.
4. Run:

```bash
helm lint <app>
helm template ci <app> >/dev/null
helm package <app> --destination /tmp/charts
```

5. Open a PR. Nothing is published; run the lint, render and package commands
   locally first.

## Updating the platform

Pair the chart PR with an `umkim-thin` PR that updates the `charts/apps`
submodule pointer and the matching `catalog/<app>.yaml` version. The platform PR
runs the catalog contract render and the acceptance checks. Never change the
catalog pin without the submodule pointer, or the reverse.

## Security

Do not open a public issue for a vulnerability in the platform or the app.
Report it privately through the umkim-thin repository:

<https://github.com/rborso/umkim-thin/security/policy>
