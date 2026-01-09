**4： Governance Fit**

**Governance Flow for Infrastructure Changes**

**② Case**

**Improvement Idea**

**Problem**

PM-defined fixed subdomain and environment rules reduce delivery
velocity and create central bottlenecks for low-risk, team-scoped
changes, while still requiring PM involvement for non-business-critical
decisions.

**Proposed Solution**

Adopt a policy-driven governance model using parameterized IaC:

-   Core constraints (naming patterns, TLS, network boundaries) remain
    fixed

-   Teams request changes via configuration within approved guardrails

**Outcome / Benefit**

-   Maintains PM control over architecture invariants

-   Enables faster, auditable, self-service changes

-   Reduces operational overhead without increasing risk

**Example**

Fraud team deployed fraud.stg.app.com via Terraform config while
complying with approved subdomain policies.

**2. Normal Change Flow (Proposal → Agreement → Implementation)**

**Change Proposal (GitHub PR)**

-   Submitted to infra-changes repository

-   Scope: spec / architecture / IaC / security

-   Includes: risk level and rollback plan

**Why**: Ensures full traceability and enforces reversible, reviewable
changes.

**Review & Agreement**

-   PM: validates business scope and intent

-   Infra/SRE: reviews operability, scalability, and failure modes

-   Security: validates policy and access boundaries

**Why**: Prevents unreviewed risk from reaching production systems.

**Implementation via IaC & CI/CD**

-   Changes applied through CI/CD pipelines (dev → staging → production)

-   Production deployment requires successful staging validation

**Why:** Eliminates manual configuration drift and reduces human error.

**Post-Change Validation**

-   24-hour monitoring and alert review window

-   Runbooks and diagrams updated if applicable

Example: Webhook rate limit increased from 100→200 RPS after staging
verification.

**3. Emergency Changes (Without Prior Approval)**

**Allowed only when:**

-   P1 / P2 incident (payment outage, active security attack)

-   Change affects specification, architecture, IaC, or security
    configuration

-   Change is minimal, time-bound, and rollback-able

-   Approved by at least 1 SRE and 1 Security engineer, with written
    approval logged (Slack/Teams)

**Mandatory follow-up:**

-   Post-incident GitHub PR submitted within 24 hours, linking approval
    logs

-   Root cause, blast radius, and remediation steps documented

**Not considered governance changes:**

-   Service restart

-   Scaling workers

-   Blocking IPs / traffic

(These are incident response actions.)

**Example:**

During an active SQL injection attack, F5 WAF rules were updated
immediately and retroactively approved via a follow-up PR the next
business day.
