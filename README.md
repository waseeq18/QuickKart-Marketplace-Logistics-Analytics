# QuickKart-Marketplace-Logistics-Analytics
This project presents an end-to-end analytics solution for QuickKart, a simulated two-sided e-commerce marketplace operating across multiple cities. The objective of the analysis was to investigate declining on-time delivery performance and understand its impact on customer retention, repeat purchases, and overall marketplace revenue (GMV).

**Approach**

1. Data loading & quality check — sanity-checked all 6 CSVs (row counts, nulls, date ranges, status distributions)
2. Exploratory analysis (Python/pandas) — built a master joined table, computed all Section A metrics, exported to Excel for Power BI
3. SQL queries (MySQL) — B1–B4 with full logic comments and index recommendations
4. Dashboard (Power BI Desktop) - Created business insights

<img width="610" height="390" alt="image" src="https://github.com/user-attachments/assets/00462973-d4ef-47a4-aea2-0435e3065e52" />

**Key Assumptions**

1. GMV: SUM(quantity × unit_price) before platform fee. Cancelled/Returned orders excluded from delay analysis but included in GMV totals.

2. Delayed order: delivery_status NOT IN ('OnTime', 'InTransit'). The InTransit status (5,043 shipments, all tied to 'Shipped' orders) is excluded from delay calculations as these orders have not yet resolved.

3. B3 threshold: The brief specifies ≥100 delivered orders per (seller, carrier, city). The actual data max is 36 orders per such combination — the dataset is too granular at that triple-key level. I used ≥50 orders at the (seller, carrier) level instead, which yields 1,598 meaningful combinations, and ≥20 at the triple-key level for city-level detail. I flagged this discrepancy — the brief's schema may have assumed heavier seller concentration.
4. First order (B2): Earliest created_at delivered order per customer. Tie-breaking is arbitrary (edge case).
   
5. Repeat customer: Cumulative — a customer counts as "repeat" in month M if they have ≥2 delivered orders through that month.

6. avg_delay_days (B3): Computed only for orders where delivered_at > promised_delivery_date (positive delay). Negative values (delivered early but flagged Late in status — data anomaly) excluded.

**Key Findings**

****Finding 1** — October & November Are Structurally Broken (Seasonality or Operational Collapse)**
The delay rate in Oct–Nov 2024 and again in Oct–Nov 2025 spikes from a baseline of ~20% to nearly 49% — more than double. This is not random variance; the exact same months repeat across both years. GMV in these months does not spike correspondingly, meaning this is not a volume-driven problem. This strongly suggests a carrier capacity or operational bottleneck during the festive/holiday season (Dussehra, Diwali, year-end).

**Recommendation:** Pre-negotiate carrier capacity in Q4. Activate InHouse fulfilment as overflow during Oct–Nov. Consider restricting fast-delivery eligibility during peak seasons to avoid SLA breaches.

****Finding 2** — **Delhivery** Is the Primary Delay Driver; **InHouse** Is the Benchmark**

<img width="596" height="202" alt="image" src="https://github.com/user-attachments/assets/639c3229-6b70-4895-a819-844aaec0e4fb" />

**Delhivery** carries the most volume AND has the worst delay rate — a double risk. **InHouse** at 7.8% is 4× more reliable but handles only 18% of shipments. The gap is not marginal; it is structural.

**Recommendation**: Shift 15–20% of Delhivery volume to InHouse on lanes where InHouse operates. Renegotiate Delhivery SLAs with penalty clauses. For Lucknow and Jaipur specifically (where Delhivery hits 86–87% delay), route all volume to BlueDart or Ekart immediately.


**Finding 3 — Lucknow and Jaipur Are Critically Broken Lanes (Delhivery-Specific)**

<img width="593" height="267" alt="image" src="https://github.com/user-attachments/assets/879a26eb-65bb-40c0-8bfb-ee43409d3be8" />

**Delhivery**'s delay rate in Lucknow and Jaipur is not a city problem — it is a carrier-lane problem. BlueDart and Ekart deliver at ~29% delay in the same cities. Delhivery appears to have a fulfilment or hub issue specific to these Tier-2 cities.


**Recommendation**: Immediately stop routing orders to Delhivery for Lucknow and Jaipur. Re-route to BlueDart or Ekart. This single change could reduce the overall delay rate by ~2–3 percentage points given these lanes' volume.


**Finding 4 — Electronics Carries 75.6% of GMV but Has the Worst Delay Rate**

<img width="584" height="246" alt="image" src="https://github.com/user-attachments/assets/6549d790-741b-4e0d-bac0-19f8b13fbd78" />


**Electronics** is not just the biggest category — it is the most delay-prone. This means delayed-GMV exposure is highly concentrated: a large fraction of the ₹980M in delayed GMV comes from Electronics orders.

**Recommendation**: Prioritise Electronics shipments in carrier SLA agreements. Review whether Electronics sellers are concentrated among the high-delay seller cohort (S0006, S0019, S0029, etc. — see B3 results).


**Finding 5 — Fast-Delivery Promise Is Being Broken at Scale**

1. 65,090 orders were marked is_fast_delivery_eligible = True
2. 21,419 of them (32.9%) were delayed — a broken 2-day delivery promise
3. ₹908,511,095 in GMV was delivered late despite a fast-delivery promise

This is the most directly customer-facing failure in the dataset. Every one of these is a broken promise to a customer who specifically chose a "guaranteed" delivery window.

**Recommendation**: Build a real-time monitoring dashboard for fast-delivery orders at risk (in-transit, approaching SLA breach). Proactively notify customers and offer compensation (vouchers) before the complaint arrives.


**Finding 6 — B2: First-Order Delay Has a Measurable Repeat Rate Impact**

<img width="593" height="163" alt="image" src="https://github.com/user-attachments/assets/0ac39269-1465-4496-bcf3-4a8e975bec2a" />

The gap is statistically present but smaller than typical industry benchmarks suggest (~1.1 percentage points). Two possible explanations: (a) QuickKart's 82.5% overall repeat rate means the customer base is highly sticky regardless — delays annoy but don't churn them; (b) most first-order delays are in the Late_1_2d bucket (mild), not severe 3–5 day delays, which would show a larger effect.

Note for live discussion: If we isolate customers whose first order was Late_3_5d or Late_5p (severe delay), the drop is likely larger. Worth testing in a follow-up cut.


**Recommendations Summary**


<img width="605" height="400" alt="image" src="https://github.com/user-attachments/assets/fb2ff147-685d-4c94-835e-1b7e8cb9a3e9" />


**How I verified the data:**

1. All SQL CTEs traced through manually with sample rows to validate logic
2. Window functions (cumulative order counts for B1, ROW_NUMBER for B2) verified step by step
3. Python aggregations cross-checked: totals match across sheets (e.g., sum of GMV_City_Category = Monthly_Summary total)
4. B4 rewrite confirmed to produce identical output to original naive query on a test subset
5. All findings above are based on actual computed numbers from the real dataset, not generated text


**AI Usage**

Used Claude (Anthropic) for:

1. Boilerplate structure of the Python EDA script, SQL file, and README template
2. DAX measure patterns for Power BI
3. Initial framework for business question framing

**What I did not use AI for:**

1. Business interpretation and recommendations — derived from my own analysis of the computed numbers
2. Index recommendations — derived from query execution paths
3. The Oct–Nov seasonality finding — identified by reading the monthly delay trend output
