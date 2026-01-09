**B： Environment & Network Understanding**

**Separation and roles of dev / staging / production**

+--------+----------------+-------------------+-----------------------+---+
| **As   | **Development  | **Staging**       | **Production (prod)** |   |
| pect** | (dev)**        |                   |                       |   |
+========+================+===================+=======================+===+
| **Pur  | -   Feature    | -                 | -   Live system       |   |
| pose** |                |    Pre-production |     serving real      |   |
|        |   development, |     validation:   |     users and         |   |
|        |     local      |     full-stack    |     payments          |   |
|        |     testing,   |     integration,  |                       |   |
|        |     CI builds  |     performance,  | -   Process real      |   |
|        |                |     security      |     customer payments |   |
|        | -   Build and  |     tests         |     securely          |   |
|        |     test new   |                   |                       |   |
|        |     features   | -   Validate full | -   Example: User     |   |
|        |     safely     |     payment flow  |     pays \$50 \>      |   |
|        |                |     before going  |     system uses       |   |
|        | -   Example:   |     live          |     Bitcoin Mainnet   |   |
|        |     Connect    |                   |     \> real BTC       |   |
|        |     BTCPay to  | -   Example:      |     transferred,      |   |
|        |     Bitcoin    |     End-to-end    |     irreversible      |   |
|        |     Testnet to |     test --- user |                       |   |
|        |     simulate   |     pays 0.01     |                       |   |
|        |     payments   |     testnet BTC → |                       |   |
|        |     without    |     webhook fires |                       |   |
|        |     real       |     → status      |                       |   |
|        |     money.     |     updates in    |                       |   |
|        |                |     UI.           |                       |   |
+--------+----------------+-------------------+-----------------------+---+
| **Same | -   Codebase   |                   |                       |   |
| Across |     (via Git   |                   |                       |   |
| Env**  |     tags /     |                   |                       |   |
|        |     branches)  |                   |                       |   |
|        |                |                   |                       |   |
|        | -              |                   |                       |   |
|        | Infrastructure |                   |                       |   |
|        |     as Code    |                   |                       |   |
|        |     (Terr      |                   |                       |   |
|        | aform/Ansible) |                   |                       |   |
|        |                |                   |                       |   |
|        | -   Core       |                   |                       |   |
|        |                |                   |                       |   |
|        |   architecture |                   |                       |   |
|        |     (network   |                   |                       |   |
|        |     topology,  |                   |                       |   |
|        |     service    |                   |                       |   |
|        |     layout)    |                   |                       |   |
+--------+----------------+-------------------+-----------------------+---+
| **D    | -   Minimal    | -                 | -   Real user data,   |   |
| iffere |     data       |   Production-like |     real money        |   |
| nces** |                |     data          |                       |   |
|        |    (mock/fake) |     (anonymized)  | -   Real secrets      |   |
|        |                |                   |     (Vault/Secrets    |   |
|        | -   No real    | -   Real config,  |     Manager)          |   |
|        |     secrets    |     fake secrets  |                       |   |
|        |                |                   | -   Immutable deploys |   |
|        | -              | -   Manual deploy |     (tagged releases) |   |
|        |    Auto-deploy |     gates         |                       |   |
|        |     on PR      |                   | -                     |   |
|        |     merge      | -   Logging =     |    Logging/monitoring |   |
|        |                |     prod level    |     = full alerting   |   |
|        | -   Debug      |                   |                       |   |
|        |     logging ON |                   |                       |   |
+--------+----------------+-------------------+-----------------------+---+
| **     | -   Devs: full | -   Devs + QA:    | -   SRE/Infra:        |   |
| Access |     access     |     deploy &      |     deploy +          |   |
| Con    |     (SSH,      |     debug         |     emergency access  |   |
| trol** |     logs,      |                   |                       |   |
|        |     deploy)    | -   Security      | -   Devs: logs only   |   |
|        |                |     team: audit   |     (no SSH)          |   |
|        | -   No         |     access        |                       |   |
|        |     external   |                   | -   2FA + IP          |   |
|        |     access     | -   No customer   |     allowlist         |   |
|        |                |     access        |     required          |   |
+--------+----------------+-------------------+-----------------------+---+
| **T    | -   Unit tests | -   End-to-end    | -   Synthetic         |   |
| esting |                |     payment flows |     monitoring        |   |
| Role** | -   Local      |                   |                       |   |
|        |                | -   Load/stress   | -   Real-user metrics |   |
|        |    integration |     tests         |                       |   |
|        |                |                   | -   Guarantees:       |   |
|        | -   CI:        | -   Security      |     "System is safe,  |   |
|        |     build +    |     scans (OWASP, |     available, and    |   |
|        |     lint       |     SAST)         |     processing real   |   |
|        |                |                   |     payments"         |   |
|        |                | -   Guarantees:   |                       |   |
|        |                |     "If it works  |                       |   |
|        |                |     here, it      |                       |   |
|        |                |     should work   |                       |   |
|        |                |     in prod"      |                       |   |
+--------+----------------+-------------------+-----------------------+---+

**② Positioning of testnet / mainnet**

+----------+----------------------------+------------------------------+
| **       | **Testnet**                | **Mainnet**                  |
| Aspect** |                            |                              |
+==========+============================+==============================+
| **P      | Development, integration,  | Live Bitcoin network         |
| urpose** | and QA for                 | handling real user funds     |
|          | blockchain-dependent       |                              |
|          | features (e.g., BTCPay,    |                              |
|          | Lightning)                 |                              |
+----------+----------------------------+------------------------------+
| **Value  | Fake BTC (no monetary      | Real BTC (high monetary      |
| of       | value)                     | value)                       |
| Assets** |                            |                              |
+----------+----------------------------+------------------------------+
| **Ope    | Low: failures cause no     | Extreme: bugs = lost funds,  |
| rational | financial loss             | reputational damage, legal   |
| Risk**   |                            | risk                         |
+----------+----------------------------+------------------------------+
| **I      | Transactions can be reset  | All transactions are         |
| rreversi | (e.g., new testnet fork)   | permanent and irreversible   |
| bility** |                            |                              |
+----------+----------------------------+------------------------------+
| **Usage  | -   dev → staging: all     | -   prod only                |
| in       |     blockchain calls hit   |                              |
| Pi       |     testnet                | -   Access only after        |
| peline** |                            |     staging validation       |
|          | ```{=html}                 |     passes                   |
|          | <!-- -->                   |                              |
|          | ```                        | ```{=html}                   |
|          | -   Used for webhook,      | <!-- -->                     |
|          |     payment confirmation,  | ```                          |
|          |     and wallet sync tests  | -   Requires multi-sig       |
|          |                            |     approval for any wallet  |
|          |                            |     interaction              |
+----------+----------------------------+------------------------------+
