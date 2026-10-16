## Runbook 2: Violación del Presupuesto de Error - Latencia (`SLO-LATENCY-01`)

### 1. Información General

- **Alerta:** `SLOLatencyErrorBudgetBurnHigh`
- **Servicio Afectado:** `api-gateway`
- **Severidad:** `Warning` / `Critical`
- **Objetivo de Nivel de Servicio (SLO):** $99.0\%$ de las peticiones atendidas en menos de $1000\text{ ms}$ ($1\text{s}$) en una ventana móvil de 7 días.
- **Criterio de Alerta:** La tasa de consumo del presupuesto de latencia supera $14.4\times$ en los últimos 15 minutos.

### 2. Descripción del Problema

El percentil de respuestas de la API ha bajado de sus estándares habituales: más del $1\%$ de las peticiones entrantes están tardando más de $1000\text{ ms}$ en responder, degradando la experiencia del usuario y agotando el presupuesto de error asignado a la latencia.

### 3. Procedimiento de Diagnóstico Paso a Paso

1. **Verificación de Métricas de Latencia:**
   - En Grafana, consulte la gráfica de **Latencia por Percentiles (p50, p90, p95, p99)**.
   - Identifique si la lentitud es generalizada o aislada en endpoints específicos (ej. `POST /checkout` vs `GET /products`).
2. **Análisis de Saturación de Recursos:**
   - Revise el panel de **Saturación (CPU y Memoria)** de los pods de `api-gateway` y sus servicios dependientes.
   - Verifique si existe _Throttling_ de CPU (_CPU Throttling_) mediante la métrica `container_cpu_cfs_throttled_periods_total`.
3. **Análisis de Trazas (Jaeger / Tempo):**
   - Busque trazas cuyo `duration > 1s`.
   - Expanda el árbol de ejecución de la traza para ubicar qué _span_ interno es el que está consumiendo la mayor parte del tiempo (ej. consulta lenta en la base de datos o llamada bloqueante a un microservicio de terceros).

### 4. Acciones de Mitigación y Recuperación

- **Opción A (Si hay CPU Throttling o saturación alta):**
  - Incremente los límites de CPU temporalmente en el repositorio GitOps o aumente las réplicas del servicio degradado.
- **Opción B (Si el problema es una base de datos o pool de conexiones exhausto):**
  - Reinicie las conexiones o incremente el pool de conexiones del microservicio afectado.
- **Opción C (Si la lentitud es en un servicio secundario no crítico):**
  - Habilite un _timeout_ más agresivo en la llamada cliente (ej. cortar la llamada a los $800\text{ ms}$) para evitar que el fallo de rendimiento se propague hacia la puerta de enlace (`api-gateway`).

### 5. Cierre y Seguimiento

- Confirme que el percentil $99$ de latencia cae nuevamente por debajo de los $1000\text{ ms}$.
- Si el problema persiste por más de 30 minutos sin causa clara de infraestructura, notifique al equipo de desarrollo responsable del código del microservicio.
