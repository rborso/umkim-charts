{{- define "paperless.namespace" -}}
{{- .Values.namespaceOverride | default .Release.Namespace -}}
{{- end -}}

{{- define "paperless.labels" -}}
app.kubernetes.io/name: paperless
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "paperless.secretName" -}}
{{- printf "%s-secrets" .Release.Name -}}
{{- end -}}

{{- define "paperless.secretKey" -}}
{{- $s := lookup "v1" "Secret" (include "paperless.namespace" .) (include "paperless.secretName" .) -}}
{{- if and $s (index ($s.data | default dict) "secret-key") -}}
{{- index $s.data "secret-key" | b64dec -}}
{{- else if .Values.secretKey -}}
{{- .Values.secretKey -}}
{{- else -}}
{{- randAlphaNum 50 -}}
{{- end -}}
{{- end -}}

{{- define "paperless.adminPassword" -}}
{{- $s := lookup "v1" "Secret" (include "paperless.namespace" .) (include "paperless.secretName" .) -}}
{{- if and $s (index ($s.data | default dict) "admin-password") -}}
{{- index $s.data "admin-password" | b64dec -}}
{{- else if .Values.admin.password -}}
{{- .Values.admin.password -}}
{{- else -}}
{{- randAlphaNum 24 -}}
{{- end -}}
{{- end -}}

{{- define "paperless.postgresPassword" -}}
{{- $s := lookup "v1" "Secret" (include "paperless.namespace" .) (include "paperless.secretName" .) -}}
{{- if and $s (index ($s.data | default dict) "postgres-password") -}}
{{- index $s.data "postgres-password" | b64dec -}}
{{- else if .Values.postgres.password -}}
{{- .Values.postgres.password -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}

{{/* Roll the web pod when the published in-cluster CA changes; otherwise its
     init container keeps the old combined bundle and OIDC discovery fails with
     "self-signed certificate in certificate chain". */}}
{{- define "paperless.caChecksum" -}}
{{- $cm := lookup "v1" "ConfigMap" (include "paperless.namespace" .) "umkim-thin-ca" -}}
{{- if and $cm $cm.data (index $cm.data "ca.crt") -}}
{{- index $cm.data "ca.crt" | sha256sum -}}
{{- end -}}
{{- end -}}

{{- define "paperless.host" -}}
{{- printf "%s-web" .Release.Name -}}
{{- end -}}

{{/* Extra /etc/hosts entries for the server pod. Explicit .Values.hostAliases
     wins. Otherwise, when SSO is on, point the issuer host at the in-cluster
     ingress (fleet-ingress/traefik) so OIDC discovery, token, and JWKS calls
     stay inside the cluster instead of hairpinning to the public WAN address. */}}
{{- define "paperless.hostAliases" -}}
{{- if .Values.hostAliases -}}
{{ toYaml .Values.hostAliases }}
{{- else if and .Values.oidc.enabled .Values.oidc.issuerUrl -}}
{{- $host := (urlParse .Values.oidc.issuerUrl).host -}}
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
