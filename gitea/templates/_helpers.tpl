{{- define "gitea.namespace" -}}
{{- .Values.namespaceOverride | default .Release.Namespace -}}
{{- end -}}

{{- define "gitea.labels" -}}
app.kubernetes.io/name: gitea
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/* Secret that holds generated credentials. */}}
{{- define "gitea.secretName" -}}
{{- printf "%s-secrets" .Release.Name -}}
{{- end -}}

{{/* Preserve generated values across upgrades via lookup. */}}
{{- define "gitea.postgresPassword" -}}
{{- $s := lookup "v1" "Secret" (include "gitea.namespace" .) (include "gitea.secretName" .) -}}
{{- if and $s (index ($s.data | default dict) "postgres-password") -}}
{{- index $s.data "postgres-password" | b64dec -}}
{{- else if .Values.postgres.password -}}
{{- .Values.postgres.password -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}

{{- define "gitea.adminPassword" -}}
{{- $s := lookup "v1" "Secret" (include "gitea.namespace" .) (include "gitea.secretName" .) -}}
{{- if and $s (index ($s.data | default dict) "admin-password") -}}
{{- index $s.data "admin-password" | b64dec -}}
{{- else if .Values.bootstrap.admin.password -}}
{{- .Values.bootstrap.admin.password -}}
{{- else -}}
{{- randAlphaNum 24 -}}
{{- end -}}
{{- end -}}

{{/* Service / Deployment name for the Gitea server. */}}
{{- define "gitea.serverHost" -}}
{{- .Release.Name -}}
{{- end -}}

{{- define "gitea.adminEmail" -}}
{{- .Values.bootstrap.admin.email | default (printf "admin@%s.local" .Release.Name) -}}
{{- end -}}

{{/* Port Gitea advertises in SSH clone URLs: explicit override, else the
     NodePort when one is set, else the listen port. */}}
{{- define "gitea.sshAdvertisedPort" -}}
{{- if gt (int (.Values.gitea.ssh.advertisedPort | default 0)) 0 -}}
{{- .Values.gitea.ssh.advertisedPort -}}
{{- else if and (eq (.Values.gitea.ssh.service.type | default "ClusterIP") "NodePort") (gt (int (.Values.gitea.ssh.service.nodePort | default 0)) 0) -}}
{{- .Values.gitea.ssh.service.nodePort -}}
{{- else -}}
{{- .Values.gitea.ssh.listenPort | default 2222 -}}
{{- end -}}
{{- end -}}

{{/* Host the app is published on. */}}
{{- define "gitea.publicHost" -}}
{{- if .Values.ingress.host -}}
{{- .Values.ingress.host -}}
{{- else -}}
{{- (urlParse (include "gitea.externalUrl" .)).host -}}
{{- end -}}
{{- end -}}

{{/* Public URL, defaulting to the chart-managed ingress host. */}}
{{- define "gitea.externalUrl" -}}
{{- if .Values.gitea.externalUrl -}}
{{- .Values.gitea.externalUrl -}}
{{- else if .Values.ingress.host -}}
{{- printf "http%s://%s" (ternary "s" "" .Values.ingress.tls) .Values.ingress.host -}}
{{- else -}}
{{- printf "http://%s.%s.svc.cluster.local:%d" (include "gitea.serverHost" .) (include "gitea.namespace" .) 3000 -}}
{{- end -}}
{{- end -}}

{{/* LDAP bind Secret + key: the directory service account, or a generated key. */}}
{{- define "gitea.ldapSecretName" -}}
{{- .Values.auth.ldap.existingSecret | default (include "gitea.secretName" .) -}}
{{- end -}}

{{- define "gitea.ldapSecretKey" -}}
{{- if .Values.auth.ldap.existingSecret -}}
{{- .Values.auth.ldap.existingSecretKey | default "LLDAP_LDAP_USER_PASS" -}}
{{- else -}}
{{- "ldap-bind-password" -}}
{{- end -}}
{{- end -}}

{{- define "gitea.hostAliases" -}}
{{- with .Values.hostAliases }}
{{ toYaml . }}
{{- end -}}
{{- end -}}
