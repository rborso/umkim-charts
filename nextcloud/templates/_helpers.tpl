{{- define "nextcloud.namespace" -}}
{{- .Values.namespaceOverride | default .Release.Namespace -}}
{{- end -}}

{{- define "nextcloud.labels" -}}
app.kubernetes.io/name: nextcloud
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/* Secret that holds generated credentials. */}}
{{- define "nextcloud.secretName" -}}
{{- printf "%s-secrets" .Release.Name -}}
{{- end -}}

{{/* Preserve generated values across upgrades via lookup. */}}
{{- define "nextcloud.postgresPassword" -}}
{{- $s := lookup "v1" "Secret" (include "nextcloud.namespace" .) (include "nextcloud.secretName" .) -}}
{{- if and $s (index ($s.data | default dict) "postgres-password") -}}
{{- index $s.data "postgres-password" | b64dec -}}
{{- else if .Values.postgres.password -}}
{{- .Values.postgres.password -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}

{{- define "nextcloud.adminPassword" -}}
{{- $s := lookup "v1" "Secret" (include "nextcloud.namespace" .) (include "nextcloud.secretName" .) -}}
{{- if and $s (index ($s.data | default dict) "admin-password") -}}
{{- index $s.data "admin-password" | b64dec -}}
{{- else if .Values.bootstrap.admin.password -}}
{{- .Values.bootstrap.admin.password -}}
{{- else -}}
{{- randAlphaNum 24 -}}
{{- end -}}
{{- end -}}

{{/* Service / Deployment name for the Nextcloud server. */}}
{{- define "nextcloud.serverHost" -}}
{{- .Release.Name -}}
{{- end -}}

{{- define "nextcloud.collaboraHost" -}}
{{- printf "%s-collabora" .Release.Name -}}
{{- end -}}

{{- define "nextcloud.adminEmail" -}}
{{- .Values.bootstrap.admin.email | default (printf "admin@%s.local" .Release.Name) -}}
{{- end -}}

{{/* Public URL, defaulting to the chart-managed ingress host. */}}
{{- define "nextcloud.externalUrl" -}}
{{- if .Values.nextcloud.externalUrl -}}
{{- .Values.nextcloud.externalUrl -}}
{{- else if .Values.ingress.host -}}
{{- printf "http%s://%s" (ternary "s" "" .Values.ingress.tls) .Values.ingress.host -}}
{{- else -}}
{{- printf "http://%s.%s.svc.cluster.local" (include "nextcloud.serverHost" .) (include "nextcloud.namespace" .) -}}
{{- end -}}
{{- end -}}

{{- define "nextcloud.publicHost" -}}
{{- if .Values.ingress.host -}}
{{- .Values.ingress.host -}}
{{- else -}}
{{- (urlParse (include "nextcloud.externalUrl" .)).host -}}
{{- end -}}
{{- end -}}

{{/* Collabora URL the browser loads: explicit publicUrl, else in-cluster. */}}
{{- define "nextcloud.collaboraWopiUrl" -}}
{{- if .Values.collabora.publicUrl -}}
{{- .Values.collabora.publicUrl -}}
{{- else -}}
{{- printf "http://%s.%s.svc.cluster.local:9980" (include "nextcloud.collaboraHost" .) (include "nextcloud.namespace" .) -}}
{{- end -}}
{{- end -}}
{{/* In-cluster Collabora address. The Nextcloud server fetches WOPI discovery
     itself, so it must use an address the pod can reach: the public hostname
     resolves to the site WAN, and a router that refuses RFC1918-to-public
     requests (or forward-auth on the route) rejects that fetch. */}}
{{- define "nextcloud.collaboraInternalUrl" -}}
{{- printf "http://%s.%s.svc.cluster.local:9980" (include "nextcloud.collaboraHost" .) (include "nextcloud.namespace" .) -}}
{{- end -}}

{{/* aliasgroup: which Nextcloud URL may use this Collabora. */}}
{{- define "nextcloud.collaboraAliasGroup" -}}
{{- .Values.collabora.aliasGroup | default (include "nextcloud.externalUrl" .) -}}
{{- end -}}

{{/* LDAP bind Secret + key: the directory service account, or a generated key. */}}
{{- define "nextcloud.ldapSecretName" -}}
{{- .Values.auth.ldap.existingSecret | default (include "nextcloud.secretName" .) -}}
{{- end -}}

{{- define "nextcloud.ldapSecretKey" -}}
{{- if .Values.auth.ldap.existingSecret -}}
{{- .Values.auth.ldap.existingSecretKey | default "LLDAP_LDAP_USER_PASS" -}}
{{- else -}}
{{- "ldap-bind-password" -}}
{{- end -}}
{{- end -}}

{{- define "nextcloud.hostAliases" -}}
{{- with .Values.hostAliases }}
{{ toYaml . }}
{{- end -}}
{{- end -}}
