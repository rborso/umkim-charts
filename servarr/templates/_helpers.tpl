{{- define "servarr.image" -}}
{{- $reg := .root.Values.global.imageRegistry | default "" -}}
{{- $img := .app.image -}}
{{- if $reg -}}{{ printf "%s/%s" $reg $img }}{{- else -}}{{ $img }}{{- end -}}:{{ .app.tag | default "latest" }}
{{- end -}}

{{- define "servarr.labels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end -}}
