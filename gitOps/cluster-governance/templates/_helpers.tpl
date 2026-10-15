{{/*
Nombre base del chart, respetando nameOverride.
*/}}
{{- define "cluster-governance.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Nombre completo (fullname) usado como prefijo de los recursos.
Respeta fullnameOverride, y evita duplicar el nombre si Release.Name ya lo contiene.
*/}}
{{- define "cluster-governance.fullname" -}}
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
Nombre del namespace gestionado por el chart: usa .Values.namespace.name
si se define, o cae por defecto al fullname del chart.
*/}}
{{- define "cluster-governance.namespaceName" -}}
{{- default (include "cluster-governance.fullname" .) .Values.namespace.name -}}
{{- end -}}

{{/*
Nombre de la ServiceAccount de la aplicación.
*/}}
{{- define "cluster-governance.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (printf "%s-sa" (include "cluster-governance.fullname" .)) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Versión del chart, saneada para usarla como label (sin '+').
*/}}
{{- define "cluster-governance.chartLabel" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels comunes recomendados por Helm (app.kubernetes.io/*), fusionados con
commonLabels definidos por el usuario en values.yaml.
*/}}
{{- define "cluster-governance.labels" -}}
helm.sh/chart: {{ include "cluster-governance.chartLabel" . }}
app.kubernetes.io/name: {{ include "cluster-governance.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Selector labels: subconjunto estable usado en selectores (no debe cambiar entre upgrades).
*/}}
{{- define "cluster-governance.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cluster-governance.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
