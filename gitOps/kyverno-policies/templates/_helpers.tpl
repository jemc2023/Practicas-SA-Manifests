{{/*
Nombre base del chart, respetando nameOverride.
*/}}
{{- define "kyverno-policies.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Nombre completo (fullname), respetando fullnameOverride y evitando
duplicar el nombre si Release.Name ya lo contiene.
*/}}
{{- define "kyverno-policies.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Versión del chart, saneada para usarla como label (sin '+').
*/}}
{{- define "kyverno-policies.chartLabel" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels comunes recomendados por Helm (app.kubernetes.io/*), fusionados con
commonLabels definidos por el usuario en values.yaml.
*/}}
{{- define "kyverno-policies.labels" -}}
helm.sh/chart: {{ include "kyverno-policies.chartLabel" . }}
app.kubernetes.io/name: {{ include "kyverno-policies.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}
