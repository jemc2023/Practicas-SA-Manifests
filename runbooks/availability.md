## Runbook 1: Violación del Presupuesto de Error - Disponibilidad (`SLO-AVAILABILITY-01`)

### 1. Información General

- **Alerta:** `SLOAvailabilityErrorBudgetBurnHigh`
- **Servicio Afectado:** `api-gateway`
- **Severidad:** `Critical` (PagerDuty / Intervención Inmediata)
- **Objetivo de Nivel de Servicio (SLO):** $99.0\%$ de disponibilidad en una ventana móvil de 7 días.
- **Criterio de Alerta:** La tasa de consumo (_Burn Rate_) del presupuesto de error supera $14.4\times$ en los últimos 15 minutos (se ha consumido o se está consumiendo el $\ge 2\%$ del presupuesto semanal en un intervalo muy corto).

### 2. Descripción del Problema

El servicio `api-gateway` está experimentando un incremento en la tasa de respuestas con errores de la serie HTTP `5xx`. El presupuesto de fallos permitido para la semana se está agotando a una velocidad crítica.

### 3. Procedimiento de Diagnóstico Paso a Paso

1. **Validación del Síntoma:**
   - Ingrese al tablero de Grafana **"Operación - Señales de Oro"**.
   - Confirme la caída sostenida en el panel de **Disponibilidad (SLI)** y el incremento en el panel de **Tasa de Error ($5xx$)**.
2. **Correlación de Cambios / Despliegues Recientes:**
   - Verifique en **ArgoCD** o **Argo Rollouts** si hubo alguna promoción de código o cambio de configuración en los últimos 30 minutos.
   - Si hay un despliegue en curso o reciente, identifique el _commit SHA_ y la versión activa.
3. **Identificación del Microservicio Causa Raíz (Traces):**
   - Abra la interfaz de **Jaeger / Tempo**.
   - Filtre por `service = api-gateway` y `error = true` dentro de la marca de tiempo reportada por la alerta.
   - Identifique el identificador de traza (`trace_id`) de las peticiones fallidas y siga el flujo de la llamada downstream (por ejemplo: `api-gateway` -> `orders-service` -> `database`).
4. **Inspección de Registros Centralizados (Logs):**
   - Abra **Loki / Grafana Explore** y ejecute la consulta vinculando el `trace_id` obtenido:
     ```logql
     {namespace="production"} |= "TRACE_ID_OBTENIDO"
     ```
   - Verifique el mensaje de excepción o la causa exacta (ej. tiempo de espera agotado, fallo de conexión a base de datos, error de autenticación).

### 4. Acciones de Mitigación y Recuperación

- **Opción A (Si el fallo se debe a un despliegue reciente):**
  - Ejecute la reversión inmediata de la versión a través de GitOps o ArgoCD:
    ```bash
    kubectl argo rollouts undo api-gateway -n production
    ```
- **Opción B (Si el fallo se debe a saturación de infraestructura):**
  - Verifique el escalado horizontal de pods (HPA). Escale manualmente el despliegue si los recursos están exhaustos:
    ```bash
    kubectl scale deployment/api-gateway --replicas=5 -n production
    ```
- **Opción C (Si el fallo es una dependencia externa o BD fuera de servicio):**
  - Active la bandera de características (_feature flag_) o el mecanismo de _Circuit Breaker_ / degradación grácil para responder con respuestas en caché o mensajes de degradación controlada al cliente.

### 5. Escalado y Cierre del Incidente

- **Si la falla no se resuelve en 15 minutos:** Escalar al ingeniero de guardia principal (_Secondary On-Call / Tech Lead_).
- **Una vez restablecido el SLI:** Documente la marca de tiempo de inicio, detección y resolución en el **Informe de Operación** y proceda al post-mortem.
