# kyverno-policies

Chart de Helm que empaqueta 4 políticas de [Kyverno](https://kyverno.io/) para
gobierno de workloads:

| Política | Kind | Objetivo |
|---|---|---|
| `disallow-latest-tag` | ClusterPolicy | Exige tag explícito y prohíbe `:latest` |
| `require-resources-limits` | ClusterPolicy | Exige `requests`/`limits` de CPU y memoria por contenedor |
| `require-run-as-nonroot` | ClusterPolicy | Exige `securityContext.runAsNonRoot: true` |
| `cosign` (verificación de firma) | Policy (namespaced) | Verifica la firma cosign de las imágenes que matcheen el patrón configurado |

## Origen

Este chart parte de los manifiestos sueltos en `kyverno-policies/` (`cosign.yaml`,
`latest-tag.yaml`, `req-limits.yaml`, `run-nonroot.yaml`) y aplica buenas
prácticas de Helm:

- **Cada política es activable/desactivable** con `policies.<nombre>.enabled`,
  para poder reusar el chart en clústeres que no necesiten las 4.
- **`validationFailureAction` y `background` parametrizados** por política, más
  un **override global** (`global.validationFailureAction`) para desplegar
  todo en modo `Audit` durante un rollout y pasar a `Enforce` después sin
  tocar cada política (ver `values-audit-rollout.yaml`).
- **Nada hardcodeado**: el namespace/secret/llave pública de `cosign`, los
  namespaces excluidos de `require-resources-limits` y los patrones de imagen
  vienen de `values.yaml`.
- **El namespace de la `Policy` de cosign ya no está fijo en `sa-p5`**: por
  defecto usa `.Release.Namespace` (el namespace donde se instala el
  release); se puede fijar explícitamente con `policies.cosignVerifyImages.namespace`.
- **Labels estándar** `app.kubernetes.io/*` y `helm.sh/chart` en todos los
  objetos, vía `_helpers.tpl`.
- **`values.schema.json`** para validar la entrada (incluye enums para
  `validationFailureAction` y `failurePolicy`).

## Instalación

```bash
# Namespace de la Policy de cosign = el namespace del release
helm install kyverno-policies ./kyverno-policies --namespace sa-p5

# Validar el renderizado antes de instalar
helm template kyverno-policies ./kyverno-policies
helm lint ./kyverno-policies

# Rollout progresivo: todo en modo Audit primero
helm install kyverno-policies ./kyverno-policies -f values-audit-rollout.yaml
```

## Valores principales

| Parámetro | Descripción | Default |
|---|---|---|
| `global.validationFailureAction` | Sobrescribe `Enforce`/`Audit` en TODAS las políticas | `""` (respeta cada política) |
| `policies.disallowLatestTag.enabled` | Habilita la política de tag `:latest` | `true` |
| `policies.requireResourceLimits.enabled` | Habilita la política de requests/limits | `true` |
| `policies.requireResourceLimits.excludeNamespaces` | Namespaces excluidos | `[argocd, kyverno, kube-system, argo-rollouts]` |
| `policies.requireRunAsNonRoot.enabled` | Habilita la política de non-root | `true` |
| `policies.cosignVerifyImages.enabled` | Habilita la verificación de firma cosign | `true` |
| `policies.cosignVerifyImages.namespace` | Namespace de la `Policy` | `""` (usa `.Release.Namespace`) |
| `policies.cosignVerifyImages.imageReferences` | Patrones de imagen a verificar | `["ghcr.io/jemc2023/*:*"]` |
| `policies.cosignVerifyImages.imageRegistrySecrets` | Secrets con credenciales del registry | `["ghcr-secret"]` |
| `policies.cosignVerifyImages.publicKeys` | Llave pública cosign (PEM) | ver `values.yaml` |

Consulta `values.yaml` para la lista completa y comentada.

## Notas de diseño

- `require-resources-limits` complementa (no reemplaza) al `LimitRange`/
  `ResourceQuota` del chart `cluster-governance`: el `LimitRange` inyecta
  valores por defecto cuando el Pod no los especifica, mientras que esta
  política **rechaza** el Pod si no los especifica explícitamente.
- El secret referenciado en `imageRegistryCredentials.secrets` (por defecto
  `ghcr-secret`) debe existir **en el mismo namespace** que la `Policy` de
  cosign; este chart no lo crea, solo lo referencia.
- `background: false` en la política de cosign es intencional: las políticas
  `verifyImages` de Kyverno no soportan scans en background sobre recursos ya
  existentes, solo admisión en tiempo real.
