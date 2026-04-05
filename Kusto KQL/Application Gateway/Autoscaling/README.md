# App Gateway – Autoscaling KQL Queries

These KQL queries were built to analyse Azure Application Gateway autoscaling behaviour during **load and performance testing**. They all target the `AGWAccessLogs` table in Log Analytics.

---

## Prerequisites

- Diagnostic settings on your App Gateway must have **Access Logs** sent to a Log Analytics workspace.
- All queries assume the workspace is already selected as the scope in Log Analytics / Azure Monitor.

---

## Queries

### `Instance-IDs.kql`
**What it does:** Lists every distinct App Gateway instance ID that handled at least one request in the last 24 hours.  
**When to use it:** Quick sanity check — how many instances are currently (or were recently) active? Use the instance IDs to cross-reference other queries.

---

### `Instance-Count.kql`
**What it does:** Plots the number of distinct active instances in 5-minute buckets as a timechart.  
**When to use it:** The go-to visual for seeing *when* the gateway scaled out and in during a test. The step-ups in the chart correspond to autoscale events.

---

### `Instance-Activity-Window.kql`
**What it does:** For each instance, shows the first and last request it handled plus the total request count, ordered chronologically.  
**When to use it:** Confirms that autoscaling actually provisioned new instances (not just redistributed traffic). You can see each instance's activity window at a glance.

---

### `Instance-Lifecycle.kql` *(new)*
**What it does:** Calculates each instance's active duration in minutes (`ActiveDurationMinutes`) — the time between its first and last observed request.  
**When to use it:** Helps distinguish long-lived baseline instances from short-lived burst instances that scaled in once load dropped.

---

### `Scale-Out-Events.kql` *(new)*
**What it does:** Buckets *new* instance appearances by hour to produce a histogram of scale-out events.  
**When to use it:** Correlate scale-out timing against your load test ramp-up profile to validate that autoscaling triggered at the expected thresholds.

---

### `Request-Distribution.kql` *(new)*
**What it does:** Shows how many requests each instance handled and its percentage share of total traffic.  
**When to use it:** Check for uneven load distribution, which can indicate session affinity (cookie-based) is pinning traffic to specific instances, or that some instances scaled out too late to share the load.

---

### `Scaling-Summary.kql` *(new)*
**What it does:** Returns a single-row summary with peak, average, and minimum instance concurrency across all 5-minute buckets, plus the timestamp of peak concurrency.  
**When to use it:** Quick executive summary — *"we peaked at N instances at HH:MM"*.

---

## Common Adjustments

| Parameter | Where to change |
|---|---|
| **Time window** | Replace `ago(7d)` / `ago(24h)` with the exact test window, e.g. `TimeGenerated between (datetime(2026-04-01 09:00) .. datetime(2026-04-01 11:00))` |
| **Bucket size** | Change `bin(TimeGenerated, 5m)` to `1m` for finer granularity or `15m` for a broader view |
| **Table name** | `AGWAccessLogs` — confirm this matches your workspace's table name (older workspaces may use `AzureDiagnostics`) |

---

## Related Tables

- `AGWAccessLogs` — per-request access logs (used by all queries here)
- `AGWPerformanceLogs` — backend health, latency, and throughput metrics
- `AGWFirewallLogs` — WAF rule matches (if WAF is enabled)
- `AzureMetrics` — resource-level metrics including `InstanceCount` (autoscale metric)
