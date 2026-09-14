{{- define "sa-platform.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "sa-platform.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "sa-platform.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "sa-platform.labels" -}}
helm.sh/chart: {{ include "sa-platform.chart" . }}
app: {{ .Chart.Name }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "sa-platform.selectorLabels" -}}
app: {{ .Chart.Name }}
{{- end }}


{{- /*
  Renderiza las annotations de checksum (config y secret) que van en
  spec.template.metadata.annotations de cada Deployment, para forzar un
  rollout automático cuando cambia el ConfigMap o el Secret asociado.
  Uso:
    {{- include "sa-platform.checksumAnnotations" (dict "context" $) | nindent 8 }}
*/ -}}
{{- define "sa-platform.checksumAnnotations" -}}
checksum/config: {{ include (print .context.Template.BasePath "/configmap.yaml") .context | sha256sum }}
checksum/secret: {{ include (print .context.Template.BasePath "/secrets.yaml") .context | sha256sum }}
{{- end -}}
