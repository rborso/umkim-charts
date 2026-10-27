{{- define "immich.namespace" -}}
{{- .Values.namespaceOverride | default .Release.Namespace -}}
{{- end -}}

{{- define "immich.labels" -}}
app.kubernetes.io/name: immich
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/* Secret that holds generated credentials. */}}
{{- define "immich.secretName" -}}
{{- printf "%s-secrets" .Release.Name -}}
{{- end -}}

{{/* Preserve generated values across upgrades via lookup. */}}
{{- define "immich.postgresPassword" -}}
{{- $s := lookup "v1" "Secret" (include "immich.namespace" .) (include "immich.secretName" .) -}}
{{- if and $s (index ($s.data | default dict) "postgres-password") -}}
{{- index $s.data "postgres-password" | b64dec -}}
{{- else if .Values.postgres.password -}}
{{- .Values.postgres.password -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}

{{- define "immich.adminPassword" -}}
{{- $s := lookup "v1" "Secret" (include "immich.namespace" .) (include "immich.secretName" .) -}}
{{- if and $s (index ($s.data | default dict) "admin-password") -}}
{{- index $s.data "admin-password" | b64dec -}}
{{- else if .Values.bootstrap.admin.password -}}
{{- .Values.bootstrap.admin.password -}}
{{- else -}}
{{- randAlphaNum 24 -}}
{{- end -}}
{{- end -}}

{{- define "immich.serverHost" -}}
{{- printf "%s-server" .Release.Name -}}
{{- end -}}

{{/* Extra /etc/hosts entries for the server pod. Explicit .Values.hostAliases
     wins. Otherwise, when SSO is on, point the issuer host at the in-cluster
     ingress (fleet-ingress/traefik) so OIDC discovery, token, and JWKS calls
     stay inside the cluster instead of hairpinning to the public WAN address. */}}
{{- define "immich.hostAliases" -}}
{{- if .Values.hostAliases -}}
{{ toYaml .Values.hostAliases }}
{{- else if and .Values.bootstrap.oauth.enabled .Values.bootstrap.oauth.issuerUrl -}}
{{- $host := (urlParse .Values.bootstrap.oauth.issuerUrl).host -}}
{{- $svc := lookup "v1" "Service" "kube-system" "traefik" -}}
{{- if not $svc -}}
{{- $svc = lookup "v1" "Service" "fleet-ingress" "traefik" -}}
{{- end -}}
{{- if and $host $svc $svc.spec.clusterIP -}}
- ip: {{ $svc.spec.clusterIP }}
  hostnames:
    - {{ $host }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "immich.adminEmail" -}}
{{- .Values.bootstrap.admin.email | default (printf "admin@%s.local" .Release.Name) -}}
{{- end -}}

{{/* Roll the server pod when the published in-cluster CA changes; otherwise
     its init container keeps the old combined bundle and OIDC discovery fails
     with "self-signed certificate in certificate chain". */}}
{{- define "immich.caChecksum" -}}
{{- $cm := lookup "v1" "ConfigMap" (include "immich.namespace" .) "umkim-thin-ca" -}}
{{- if and $cm $cm.data (index $cm.data "ca.crt") -}}
{{- index $cm.data "ca.crt" | sha256sum -}}
{{- end -}}
{{- end -}}
