# Azure Front Door

KQL queries for analyzing Azure Front Door traffic patterns, request routing, and regional distribution in Log Analytics / Azure Monitor.

## Contents

| File | Description |
|------|-------------|
| `Count-requests-by-regions-pie-chart.kql` | KQL query that counts incoming requests grouped by client region and renders the results as a pie chart. |
| `Requests-to-origins-descending.kql` | KQL query that lists requests forwarded to each origin backend, sorted in descending order by request count. |
| `Requests-to-routing-rule-count-bar-chart.kql` | KQL query that counts requests matched by each Front Door routing rule and renders a bar chart. |
| `Traffic-to-regions-in-15m-buckets.kql` | KQL query that aggregates traffic by destination region in 15-minute time buckets for trend analysis. |

## Usage

Run these queries in [Azure Monitor Log Analytics](https://portal.azure.com) against a workspace that has Azure Front Door diagnostic logs (`FrontDoorAccessLog`) enabled.
