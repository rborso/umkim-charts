{{- define "servarr.image" -}}
{{- $reg := .root.Values.global.imageRegistry | default "" -}}
{{- $img := .app.image -}}
{{- if not $img -}}
{{- fail (printf "apps.%s.image is not set" .name) -}}
{{- end -}}
{{- if not .app.tag -}}
{{- fail (printf "apps.%s.tag is not set; every component must be pinned to an exact tag (see docs/versioning-plan.md)" .name) -}}
{{- end -}}
{{- if $reg -}}{{ printf "%s/%s" $reg $img }}{{- else -}}{{ $img }}{{- end -}}:{{ .app.tag }}
{{- end -}}

{{- define "servarr.labels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end -}}
