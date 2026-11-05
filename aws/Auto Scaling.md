# AWS Auto Scaling

AWS Auto Scaling monitors your applications and automatically adjusts capacity to maintain steady, predictable performance at the lowest possible cost.

---

## 1. Scaling Strategies: Horizontal vs. Vertical

### Horizontal Auto Scaling (Scale Out / Scale In)
* **Definition:** Adding or removing **multiple instances** with the **same configuration**.
* **Scale Out:** Automatically spin up additional EC2 instances when application load increases.
* **Scale In:** Terminate extra EC2 instances when demand subsides to optimize costs.
* **Automation:** Fully managed and automated using **AWS Auto Scaling Groups (ASG)**.
* **Downtime:** **Zero downtime**; user traffic is dynamically distributed across active instances via a load balancer.

### Vertical Scaling (Scale Up / Scale Down)
* **Definition:** Changing the compute specifications (CPU, RAM, Storage) of a **single instance**.
* **Implementation:** Usually a manual process on AWS EC2.
* **Manual Lifecycle:**
  1. Launch `t3.micro` instance.
  2. Experience resource exhaustion ➔ Stop/terminate `t3.micro`.
  3. Launch / modify instance type to `t3.small`.
  4. Experience resource exhaustion again ➔ Stop/terminate `t3.small`.
  5. Launch / modify instance type to `t3.medium`.
* **Drawbacks:**
  * **Time-consuming process.**
  * **Application downtime:** Stopping and resizing an instance requires downtime.
  * **Hardware ceiling:** Limited by the maximum specifications available for a single machine.

---

## 2. Horizontal Auto Scaling Policy Types

AWS Auto Scaling Groups support multiple policy types to control automated scaling:

### 1. Metric-Based Scaling
Scales dynamically based on CloudWatch metric thresholds.
* **Target Tracking Scaling:** Automatically increases or decreases capacity to keep a specific metric at or near a target value.
  * *Example:* Maintain average CPU utilization of the instance pool at 60%.
* **Step Scaling:** Adjusts capacity in steps based on the size of the metric alarm breach.
  * *Example:* Add 1 instance if CPU is between 60% and 75%; add 3 instances if CPU exceeds 75%.
* **Simple Scaling:** Waits for a cooldown period before adjusting capacity based on an alarm.

### 2. Scheduled Scaling
Scales capacity automatically based on predictable, recurring calendar events or timeframes.
* Useful when traffic increases and decreases on a regular, predictable schedule.
* *Example:* Scale out to 10 instances every weekday at 8:30 AM before business hours, and scale in to 2 instances at 7:00 PM.

### 3. Predictive Scaling (ML-based)
Uses Machine Learning models to analyze historical traffic patterns and forecast future capacity demands.
* Proactively launches instances ahead of anticipated traffic spikes.
* Eliminates instance warm-up delays and ensures capacity is ready *before* traffic arrives.
* Can be combined with dynamic (metric-based) scaling for maximum responsiveness.

---

## 3. Comparison Summary

| Attribute | Horizontal Scaling (Scale Out/In) | Vertical Scaling (Scale Up/Down) |
| :--- | :--- | :--- |
| **Method** | Add / remove identical instances | Upgrade / downgrade single instance size |
| **Automation** | Fully automated via Auto Scaling Groups | Typically manual (Stop ➔ Change Type ➔ Start) |
| **Downtime** | 0% (Zero downtime) | Requires downtime during instance reboot/resize |
| **Availability** | High Availability (Spans multiple AZs) | Single point of failure |
| **Cost Efficiency** | Pay only for what is currently needed | May lead to over-provisioning during off-peak hours |
| **Scaling Limit** | Practically unlimited (distributed across AZs) | Bound by highest single EC2 instance specs |
