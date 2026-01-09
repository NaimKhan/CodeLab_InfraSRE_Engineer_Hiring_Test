**3： Security Implementation**

**① Control List (What you do to protect what)**

+---+-----------+-----------------+-------------------------------------+
| * | *         | **What It       | **How It's Implemented in Our       |
| * | *Security | Protects**      | Environment**                       |
| S | Control** |                 |                                     |
| L |           |                 |                                     |
| * |           |                 |                                     |
| * |           |                 |                                     |
+===+===========+=================+=====================================+
| * | **WAF +   | Public APIs,    | F5 BIG-IP 2200S deployed in         |
| * | Rate      | webhook         | active/passive HA mode in our       |
| ① | L         | endpoints, and  | on-prem DC. Uses BIG-IP             |
| * | imiting + | admin portals   | ASM/Advanced WAF for Layer 7        |
| * | IP        | from DDoS,      | protection (blocks SQLi/XSS), rate  |
|   | Restr     | brute force,    | limiting policies (e.g., 100        |
|   | ictions** | SQLi, XSS, and  | req/min per IP), and IP allowlists  |
|   |           | unauthorized    | (only office + bastion IPs for      |
|   |           | access          | admin paths). No global CDN - all   |
|   |           |                 | traffic flows directly to DC.       |
+---+-----------+-----------------+-------------------------------------+
| * | **SSH &   | Linux servers   | At OS install: root login disabled, |
| * | OS        | from            | SSH port changed, key-only auth,    |
| ② | Ha        | unauthorized    | fail2ban for brute-force            |
| * | rdening** | shell access    | protection, minimal sudo users,     |
| * |           | and local       | password policy enforced,           |
|   |           | exploits        | unnecessary services/ports          |
|   |           |                 | disabled. In prod: VPN-only access. |
|   |           |                 | Regular patching via yum update.    |
+---+-----------+-----------------+-------------------------------------+
| * | **TLS     | HTTPS           | Certificates issued via internal CA |
| * | Ce        | integrity,      | or Let's Encrypt. Automated renewal |
| ③ | rtificate | trust, and      | script alerts 10 days before        |
| * | Man       | prevention of   | expiry. Manual revocation via       |
| * | agement** | MITM attacks    | runbook if private key compromised. |
+---+-----------+-----------------+-------------------------------------+
| * | **Secret  | API keys,       | **Cloud**: AWS IAM roles + KMS      |
| * | Man       | database        |                                     |
| ④ | agement** | credentials,    | **On-Prem**: Encrypted config files |
| * |           | access keys,    | (root-only, chmod 600)              |
| * |           | TLS certs       |                                     |
|   |           |                 | **Never in Git/Docker**             |
|   |           |                 | (.gitignore + runtime injection)    |
|   |           |                 |                                     |
|   |           |                 | **Rotate API keys every 90 days**,  |
|   |           |                 | with expiry alerts                  |
+---+-----------+-----------------+-------------------------------------+
| * | **Ce      | Accountability, | rsyslog + ELK stack for server and  |
| * | ntralized | forensic        | applications error, access logs to  |
| ⑤ | Audit     | tracing, and    | central Dell SC9000 storage via     |
| * | Logging** | compliance (PCI | shared path. 6-month log retention. |
| * |           | DSS, GDPR)      | All human actions (SSH, config      |
|   |           |                 | changes) logged.                    |
+---+-----------+-----------------+-------------------------------------+
| * | **Secure  | User sessions   | PHP apps: session.cookie_secure=1,  |
| * | Cookie &  | from theft,     | httponly=1, samesite=Lax. Apache:   |
| ⑥ | Session   | XSS, and        | X-Frame-Options=SAMEORIGIN,         |
| * | Policy**  | clickjacking    | X-XSS-Protection=1,                 |
| * |           |                 | X-Content-Type-Options=nosniff. No  |
|   |           |                 | wildcard domains; cookies scoped to |
|   |           |                 | app path only.                      |
+---+-----------+-----------------+-------------------------------------+
| * | **Strict  | Frontend APIs   | Allowed origins: only               |
| * | CORS      | from            | https://merchant.yourgateway.com    |
| ⑦ | Policy**  | cross-origin    | and https://app.yourgateway.com.    |
| * |           | data leaks      | Wildcard (\*) explicitly forbidden. |
| * |           |                 | Configured in F5 iRules and         |
|   |           |                 | application code.                   |
+---+-----------+-----------------+-------------------------------------+
| * | **Content | Web UI from     | CSP header: default-src \'self\';   |
| * | Security  | XSS, data       | connect-src \'self\'                |
| ⑧ | Policy    | exfiltration,   | https://api.stripe.com; script-src  |
| * | (CSP)**   | and malicious   | \'self\'. Inline scripts blocked.   |
| * |           | script          | Policy tested via report-only mode  |
|   |           | injection       | before enforcement.                 |
+---+-----------+-----------------+-------------------------------------+
| * | **Webhook | Payment         | Verify **HMAC signatures** using    |
| * | Ha        | confirmation    | shared secret.                      |
| ⑨ | rdening** | integrity from  |                                     |
| * |           | forgery,        | Enforce **idempotency** via         |
| * |           | replay, and     | Event-Id to prevent                 |
|   |           | duplication     | double-processing.                  |
|   |           |                 |                                     |
|   |           |                 | Reject events with **timestamp \>5  |
|   |           |                 | min old** (replay protection).      |
+---+-----------+-----------------+-------------------------------------+

**② Configuration Example (Chosen: IP Restriction Approach)**

**Tool**: F5 BIG-IP 2200S (on-prem)\
**Policy**: Restrict access to /webhook and /admin endpoints to only
trusted IPs

**Implementation**:

-   In F5 GUI: **Local Traffic \> Profiles \> HTTP**

-   Create HTTP Profile with **Allowed IP List**:

    -   203.0.113.10/32 (Corporate Office)

    -   198.51.100.5/32 (SRE Bastion Host)

-   Attach this profile to the Virtual Server

-   **Result**: All other IPs receive **HTTP 403 Forbidden**

**③ Operational Procedures**

**Secret Rotation Procedure**

We rotate secrets to minimize the impact of a potential leak. The
process is safe, automated where possible, and includes validation to
avoid service disruption.

The system cannot be down while rotating Secret. Therefore, we must work
step by step, incorporating safety checks.

**Rotating a Payment API Key**

1.  **Preparation**

    -   Generate a new API key in the provider portal

    -   Store the new key securely in AWS Secrets Manager (for cloud) or
        > an encrypted config file (for on-prem DC).

    -   Deploy a new version of the app that reads both old and new keys
        > (dual-read mode).

2.  **Cutover**

    -   Update the app configuration to use only the new key.

    -   Revoke or disable the old key in the provider portal.

    -   Perform a rolling restart of the service (no downtime).

3.  **Validation**

    -   Run synthetic test: curl -H \"X-API-Key: \<new_key\>\"
        > https://api/webhook

    -   Check logs for "Using rotated secret" and **zero 401/403
        > errors**

\> Expect HTTP 200.

4.  **Cleanup**

    -   Delete the old key from Secrets Manager / config file.

    -   Update the runbook in Confluence:

After 24 hours, deleted the old API key from Secrets Manager. Wrote in
Confluence: 'Rotated by Naim on 2026-01-09'

-   **Rotation Frequency**:

```{=html}
<!-- -->
```
-   **API keys**: Every **90 days** (or immediately if leaked)

-   **Wallet access keys**: Every **30 days** (note: Bitcoin private
    keys are never rotated - we rotate *access* keys only)

-   **TLS certificates**: Automated renewal via script; manual check 10
    days before expiry

```{=html}
<!-- -->
```
-   **Access Permission Review**

```{=html}
<!-- -->
```
-   Quarterly IAM audits; auto-revoke on employee offboarding.

-   Remove unused permissions (principle of least privilege)

```{=html}
<!-- -->
```
-   **Exception Handling**

```{=html}
<!-- -->
```
-   **Emergency prod access** requires:

    -   Approval from **2 SREs**

    -   A **Jira ticket** with business justification

-   **Post-incident:** Review why exception was needed and improve
    automation
