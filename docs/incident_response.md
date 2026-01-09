**①Case 1: All webhooks fail for 30 minutes**

**①Impact / Risk (1‒2 lines)**

Payment status synchronization completely broken between gateway and
merchant systems. Transaction visibility halted, high risk of duplicate
charges and financial reconciliation failures.

**② What to check in the first 5 minutes (max 5 items):**

1.  **API Health & SSL:**

-   curl -I https://api.example.com/health  #HTTP status

-   openssl s_client -connect payment-api.com:443 -brief \# SSL level
    validity

-   curl -s -o /dev/null -w \"%{http_code}\"
    <https://payment-api.com/health> #Application level

2.  **Infrastructure Dashboard**

-   Check Grafana: Payment success rate dropped below 95%?

-   Verify Prometheus alert: \`webhook_failure_rate \> 10%\`?

-   5xx/timeout errors in webhook worker logs: journalctl -u
    webhook-worker \--since \"30 min ago\"

```{=html}
<!-- -->
```
-   CPU/Memory alerts

-   git log \--oneline -3 #Last deployment

-   docker ps \| grep -E \"(payment\|webhook)\" #Container status

3.  **Recent Changes**

-   git log \--since=\"1 hour ago\"

-   docker ps \--last 10

-   Deployment pipeline status (GitHub/GitLab)

4.  **Security Config**

-   terraform state show module.waf 2\>/dev/null \| head -20 \# WAF
    changes (if using Terraform)

-   terraform plan -target=module.waf #WAF changes

-   iptables -L -n -v \| tail -20 \# Firewall rules (recent blocks)

5.  **Error Patterns**

-   tail -100 /var/log/app/error.log \| grep -E \"(payment\|webhook)\"
    #Recent errors

-   tail -100 /var/log/nginx/access.log \| awk \'{print \$9}\' \| sort
    \| uniq -c #HTTP error codes

**③Top 3 root-cause hypotheses (prioritized) + verification steps**

**1. External Payment Provider API Outage**

**Command 1:** Check provider status page

curl -s https://status.stripe.com \| grep -A5 \"API\"

**Why:** Quickest way to know if it\'s their problem

**Expected if true:** Shows \"degraded\", \"outage\", or \"incident\"

**Command 2:** Test API connectivity

curl -I https://api.stripe.com/v1/health -u \"sk_test_xxx:\" -w
\"%{http_code}\\n\"

**Why:** Direct API test bypassing our application

**Expected if true:** Returns 5xx (500, 503, 504) or timeout

**Command 3:** SSL handshake test

openssl s_client -connect api.stripe.com:443 -brief 2\>&1 \| head -5

**Why:** Check if SSL/TLS connection works at protocol level

**Expected if true:** Shows \"SSL handshake failed\" or \"certificate
verify failed\"

**2. Rate Limiting**

**Verification Steps:**

**Command 1:** Check rate limit headers

curl -I https://api.stripe.com/v1/charges -u \"sk_test_xxx:\" 2\>&1 \|
grep -i \"rate-limit\"

**Why:** API returns rate limit headers in response

**Expected if true:** Shows \"RateLimit-Limit: 100\",
\"RateLimit-Remaining: 0\"

**Command 2:** Check our NGINX rate limit logs

tail -10 /var/log/nginx/rate_limit.log \| grep \"429\"

**Why:** Our own rate limiting might be blocking requests

**Expected if true:** Multiple \"429 Too Many Requests\" entries

**Command 3:** Check active connections

netstat -an \| grep \":443\" \| grep ESTABLISHED \| wc -l

**Why:** High connections might trigger rate limits

**Expected if true:** Number \> 1000 (unusually high)

**3. SSL Certificate Expiry**

**Verification Steps:**

**Command 1:** Check certificate expiry date

openssl s_client -connect api.stripe.com:443 2\>/dev/null \| openssl
x509 -noout -dates

**Why:** Certificates auto-expire every 90 days (Let\'s Encrypt)

**Expected if true:** \"notAfter=Dec 31 23:59:59 2023 GMT\" (past date)

**Command 2:** Verify certificate chain

echo \| openssl s_client -connect api.stripe.com:443 -showcerts
2\>/dev/null \| openssl verify -CApath /etc/ssl/certs

**Why:** Missing intermediate certificates break chain

**Expected if true:** Returns \"error 20: unable to get local issuer
certificate\"

**Command 3:** Check from container perspective

docker exec payment-gateway sh -c \"echo \| openssl s_client -connect
api.stripe.com:443 2\>&1 \| grep -i verify\"

**Why**: Container might have different certs than host

**Expected if true:** Shows \"certificate verify failed\" or
\"self-signed certificate\"

**Output Interpretation:**

-   **200 OK**: Provider is up, look elsewhere

-   **429 Too Many Requests**: Rate limit hit

-   **500/502/503/504**: Provider outage

-   **SSL handshake failed**: Certificate/TLS issue

-   **Connection refused/timed out**: Network/firewall issue

**④Top 2 temporary mitigations ("stop the bleeding")**

**1. Stop Automatic Retries + Persist Payloads\"**

**Action**: Immediately halt all automatic webhook retries to prevent
API quota exhaustion or IP blocking. Persist every failed payload (with
headers, timestamp, and error code) to durable storage like (S3, DB,
Kafka dead-letter topic) or a dead-letter queue.

**Why this works**:

-   Stops the incident from worsening (matches symptom: "increased
    retries")

-   Ensures no event is lost (enables recovery)

-   Allows safe, idempotent replay later to restore consistency without
    double-counting

**Recovery**:\
After fixing the root cause (e.g., expired cert, rate limit), replay
payloads in small batches using idempotency keys (e.g., Idempotency-Key:
\<payment_id\>) to guarantee exactly-once processing.

**2: Quarantine Failing Webhook Targets**\
Identify and temporarily disable delivery to specific failing external
endpoints (e.g., merchants returning 429/5xx), while allowing healthy
ones to proceed. Failed events are saved to a DLQ.

**Why**:

1.  Reduces blast radius (not all merchants affected)

2.  Prevents one bad actor from blocking the entire queue

3.  Enables partial recovery even during incident

4.  Complements global stop (Mitigation #1) for finer control

**⑤Top 2 permanent fixes (recurrence prevention)**

**1. Per-Merchant Circuit Breakers**\
Automatically quarantine failing webhook targets (e.g., after 5
errors/minute) while allowing healthy merchants to receive updates. This
prevents one broken integration from blocking the entire queue - the
real cause behind "all webhooks fail" incidents. Failed events are
routed to a dead-letter queue (DLQ) for safe replay, ensuring zero data
loss and partial availability during outages.

-   On 5+ failures in 60s → open the circuit → skip delivery → save to
    DLQ.

-   After 45 minutes → auto-close the circuit → resume delivery.

-   Alerts notify the team: Webhook circuit opened for
    merchant=shop.example.com.

**Why this solves the root problem**:\
The symptom "all webhooks fail" is typically caused by **head-of-line
blocking** --- where a single failing merchant stalls the entire
delivery pipeline. Per-merchant circuit breakers **isolate the faulty
endpoint** without affecting others, stop retry storms, avoid
system-wide outages, and maintain partial service continuity. This
directly addresses the true root cause of Case 1, not just its symptoms.

By isolating only, the problematic merchant:

-   **Healthy merchants keep receiving status updates** → partial system
    availability is preserved

-   **Retry storms stop immediately** → no risk of IP blocking or API
    quota exhaustion

-   **The team gains time** to contact the merchant or fix integration
    without full outage

-   **No data loss** - quarantined events remain in DLQ for replay after
    recovery

**2. Idempotent Webhook Delivery with Unique Event IDs**\
Assign a **globally unique event ID** (e.g., evt_pay_12345_20260109) to
every webhook at creation time. Merchants must deduplicate incoming
events using this ID (e.g., store processed IDs in a DB with 7--30 day
TTL).

**Why this is a permanent fix for Case 1**:

-   During the 30-minute outage, failed webhooks can be safely replayed
    any number of times.

-   Even if replayed 10 times, only the first attempt is processed -
    eliminating double-payment risk.

-   No need to store millions of events forever; just keep processed IDs
    for as long as replay is needed (e.g., 7 days).

-   Lightweight, scalable, and aligned with industry standards (Stripe,
    PayPal, AWS SNS).

**⑥Proposal for monitoring / alert additions (2 items)**

**Proposal 1: Alert on Webhook Delivery Failure Rate per Merchant**

**What to monitor**:

-   webhook_delivery_failed_total{merchant=\"X\"} (Prometheus counter)

-   Calculate **failure rate**:
    rate(webhook_delivery_failed_total\[5m\]) /
    rate(webhook_delivery_total\[5m\])

**Alert condition**:

**FIRE** if failure rate **\> 80% for any merchant** over **5 minutes**

**Why this helps**:

-   Catches **single-merchant outages early** (before it blocks the
    whole queue)

-   Prevents **Case 1** by triggering **auto-quarantine or manual
    investigation** within minutes, not hours

-   Reduces noise: only alerts when a **specific merchant** is broken,
    not global flakiness

**Proposal 2: Alert on Webhook Queue Backlog Growth**

**What to monitor**:

-   Queue depth in your message system (e.g.,
    kafka_topic_partition_lag{topic=\"webhooks\"} or
    redis_llen{key=\"webhook_queue\"})

**Alert condition**:

**FIRE** if queue depth **increases by \>200% in 10 minutes** AND
**delivery rate drops by \>50%**

**Why this helps**:

-   Detects **head-of-line blocking** even if you don't know which
    merchant is failing

-   Shows **systemic impact** - e.g., "Queue grew from 50 -\> 1000 in 10
    min"

-   Triggers **immediate mitigation** (e.g., pause consumers, quarantine
    suspect targets)

**⑦Post-incident follow-up**

**What to Add to the Runbook**

-   **\[Mitigation\]** Immediately halt automatic retries if webhook
    failure rate \>80% for any merchant.

-   **\[Isolation\]** Quarantine failing merchants automatically (via
    circuit breaker) or manually via CLI:

-   **\[Recovery\]** Replay failed events from DLQ in batches of 100,
    with 2s delay, using idempotent delivery.

-   **\[Verification\]** After fix, confirm:

> Queue depth returning to normal (\<50)
>
> Webhook success rate \>99% for 10 min
>
> No duplicate payment IDs in logs (grep \"payment_id\" \| sort \| uniq
> -d)

**What to Record in the Postmortem**

-   **Root Cause**: e.g., "Merchant X's API returned 429 due to
    unannounced rate limit change."

-   **Detection Gap**: "No per-merchant failure alert → outage detected
    only after 30 min by customers."

-   **Impact**:

> Duration: 30 minutes
>
> Affected: 12,500 payment status updates delayed
>
> No data loss, no double payments

-   **Action Items**:

> Implement per-merchant circuit breakers (Fix #1)
>
> Enforce unique event IDs + deduplication (Fix #2)
>
> Add webhook failure rate & queue backlog alerts (Monitoring Proposals)

-   **Prevention Validation**:

> "Tested replay with 500 events → 0 duplicates"
>
> "Simulated merchant failure → circuit breaker activated in \<2 min"

**\
Bypass External Payment Provider Temporarily**

**Action:** Switch to backup payment provider\
**How:**

Update Docker environment to use backup endpoint

**docker-compose down**

sed -i \'s/api.stripe.com/backup-api.payment.com/g\' docker-compose.yml

**docker-compose up -d**

OR Update Terraform to modify routing

> terraform apply -target=aws_route53_record.payment_api \\
>
> -var=\'payment_endpoint=\"backup-api.payment.com\"\' \\
>
> -auto-approve

**Why: If Payment gateway is down, immediately route traffic to backup
provider to restore payments.**
