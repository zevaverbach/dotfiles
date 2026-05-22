# Email Command Gateway Authentication: Comprehensive Research Report

## 1. TOTP Tokens Embedded in Email Body

### How It Works

The sender generates a TOTP code locally (using a shared secret + current Unix time / 30-second step), embeds it in the email body (e.g., as a header line `AUTH: 483291` or structured field), and the receiving server independently computes the expected TOTP from the same shared secret and validates the code. The server should accept codes within a +/- 1 window (90 seconds total) to account for email delivery delays.

### Implementation Pattern

```typescript
// Using otplib (TypeScript-first, audited crypto)
import { authenticator } from 'otplib';

// Setup: both sender and server share this secret
const sharedSecret = authenticator.generateSecret(); // base32 encoded

// Sender side: generate token to embed in email
const token = authenticator.generate(sharedSecret);
// Email body: "CMD: deploy-staging\nAUTH: ${token}"

// Server side: validate token from parsed email
const isValid = authenticator.verify({ token: extractedToken, secret: sharedSecret });
// verify() checks current window +/- 1 step by default
```

### Key Libraries

| Library | Language | Notes |
|---------|----------|-------|
| **[otplib](https://github.com/yeojz/otplib)** | TypeScript/JS | TypeScript-first, async-first, uses @noble/hashes (audited). Supports Node, Bun, Deno, Browser. RFC 4226 + RFC 6238. |
| **[otpauth](https://github.com/hectorm/otpauth)** | JS | HOTP/TOTP for Node, Deno, Bun, browsers. Lightweight alternative. |
| **[JS-OTP](https://github.com/jiangts/JS-OTP)** | JS | Minimal pure-JS HOTP/TOTP. Good for embedded/constrained environments. |
| **[pyotp](https://github.com/pyauth/pyotp)** | Python | Standard Python TOTP/HOTP library. |
| **[totp-kt](https://github.com/robinohs/totp-kt)** | Kotlin | HOTP/TOTP for JVM/Android. |

### Practical Considerations

- **Email delay problem**: TOTP codes expire in 30 seconds. Email delivery can take 1-60+ seconds. Mitigation: widen the acceptance window to +/- 2 or even +/- 5 steps (giving 2.5-5.5 minutes). This reduces security slightly but is necessary for email's async nature.
- **TOTP alone is insufficient**: TOTP proves the sender knows the shared secret and sent the message recently, but does NOT prove the email wasn't intercepted and replayed within the window. Combine with nonce tracking (see Section 8).

---

## 2. HMAC-Based Email Authentication

### How It Works

The sender computes `HMAC-SHA256(shared_secret, canonical_message)` and includes the resulting hex digest in the email (e.g., as a footer or header). The server reconstructs the canonical message from the email body and independently computes the HMAC. If signatures match, the message is authentic and unmodified.

### Implementation Pattern

```typescript
import { createHmac } from 'crypto';

// Canonical string: include timestamp + command to prevent tampering
const timestamp = Math.floor(Date.now() / 1000).toString();
const command = 'deploy-staging';
const canonical = `${timestamp}\n${command}`;

// Sender side
const signature = createHmac('sha256', sharedSecret)
  .update(canonical)
  .digest('hex');

// Email body format:
// TIMESTAMP: 1711137600
// CMD: deploy-staging
// SIG: a3f2b8c1d4e5...

// Server side
const expectedSig = createHmac('sha256', sharedSecret)
  .update(`${parsedTimestamp}\n${parsedCommand}`)
  .digest('hex');

// CRITICAL: use timing-safe comparison
import { timingSafeEqual } from 'crypto';
const isValid = timingSafeEqual(
  Buffer.from(signature, 'hex'),
  Buffer.from(expectedSig, 'hex')
);

// Also check timestamp freshness
const age = Math.floor(Date.now() / 1000) - parseInt(parsedTimestamp);
if (age > 300) reject(); // 5-minute window
```

### Best Practices (from GitGuardian, Authgear)

1. **Sign a canonical string**, not just the body -- include timestamp, command, and any parameters
2. **Use HMAC-SHA256** minimum (SHA-512 for higher security)
3. **Always use timing-safe comparison** (`crypto.timingSafeEqual` in Node, `hmac.compare_digest()` in Python) to prevent timing attacks
4. **Include timestamp in signed payload** and reject messages older than 5 minutes
5. **Rotate secrets periodically** -- support two active secrets during rotation window
6. **Never transmit the secret** -- it exists only on sender and server

### Python Implementation

```python
import hmac
import hashlib
import time

shared_secret = b'your-shared-secret-here'
timestamp = str(int(time.time()))
command = 'deploy-staging'
canonical = f'{timestamp}\n{command}'.encode()

signature = hmac.new(shared_secret, canonical, hashlib.sha256).hexdigest()

# Verification
def verify(parsed_ts, parsed_cmd, parsed_sig, secret):
    canonical = f'{parsed_ts}\n{parsed_cmd}'.encode()
    expected = hmac.new(secret, canonical, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, parsed_sig)
```

### HMAC vs TOTP for Email Commands

| Factor | TOTP | HMAC |
|--------|------|------|
| Proves message integrity | No (only time-based) | Yes (signs the content) |
| Replay window | 30s per step | Configurable timestamp check |
| Implementation complexity | Lower | Medium |
| Content binding | None (same code for any command) | Yes (signature covers command) |
| **Recommendation** | Good for simple auth | Better for command auth |

**Strategic insight**: HMAC is superior for email command gateways because the signature is bound to the specific command content. A TOTP code proves "the sender had the secret at time T" but an HMAC proves "the sender authorized THIS SPECIFIC COMMAND at time T."

---

## 3. How Major Platforms Handle Email-Triggered Authentication

### IFTTT

- **Trigger mechanism**: Send email to `trigger@applet.ifttt.com` from your registered email address
- **Authentication**: Sender email address matching only -- must come from the email address associated with your IFTTT account
- **Security model**: Relies entirely on email provider's FROM validation. No cryptographic verification. Supports file attachments (creates public URL).
- **Weakness**: Trivially spoofable if attacker knows your email address. No 2FA on the email trigger itself.

### Zapier

- **Trigger mechanism**: "New Inbound Email" trigger with custom `@zapiermail.com` address
- **Authentication**: Obscurity-based -- each Zap gets a unique, random `@zapiermail.com` address that acts as a shared secret
- **Additional filtering**: Can add Filter steps to check sender address, subject patterns, or body content
- **Security model**: The randomized email address IS the authentication. Anyone who discovers the address can trigger the Zap. No cryptographic verification.
- **Mitigation**: Add a Filter by Zapier step to whitelist sender addresses

### GitHub Actions (via Email)

- **No direct email trigger**: GitHub Actions does not support email as a trigger mechanism
- **API-based triggering**: Uses `repository_dispatch` events triggered via API with a Personal Access Token (PAT) with `repo` scope
- **Workaround pattern**: Email -> Inbound parse service (Mailgun/SendGrid) -> webhook -> GitHub API `repository_dispatch`
- **Authentication at each hop**: Email auth (SPF/DKIM/DMARC), webhook signature verification, GitHub PAT

### GitLab CI (Pipeline Triggers)

- **Trigger mechanism**: Pipeline trigger tokens via API (`POST /api/v4/projects/:id/trigger/pipeline`)
- **Authentication**: Dedicated trigger tokens (separate from personal access tokens) with `api` scope
- **No direct email trigger**: Like GitHub, requires API call. Token impersonates user's project access level.
- **Token management**: Created at Settings > CI/CD > Pipeline triggers. Each token can have a description and can be revoked independently.

### Mailgun Inbound Webhooks

- **Signature verification**: HMAC-SHA256 based
- **How it works**:
  1. Mailgun sends `timestamp`, `token`, and `signature` with each webhook
  2. Concatenate `timestamp` + `token` (no separator)
  3. HMAC-SHA256 the result using your **Webhook Signing Key** (NOT your API key -- separate key in Dashboard > Settings > API Keys)
  4. Compare resulting hexdigest to the `signature` value
- **Replay prevention**: Cache the `token` value and reject duplicate tokens
- **Timestamp validation**: Optionally reject if timestamp is too old
- **TLS certificate**: Mailgun includes a TLS client certificate with webhook requests for transport-level validation

```typescript
import { createHmac, timingSafeEqual } from 'crypto';

function verifyMailgun(timestamp: string, token: string, signature: string, signingKey: string): boolean {
  const encoded = createHmac('sha256', signingKey)
    .update(timestamp + token)
    .digest('hex');
  return timingSafeEqual(Buffer.from(encoded), Buffer.from(signature));
}
```

### SendGrid Inbound Parse

- **Signature verification**: ECDSA (Elliptic Curve Digital Signature Algorithm)
- **How it works**: SendGrid signs the payload with a private key; you verify with their public key
- **Critical detail**: Use the RAW request body for verification -- do not parse or modify before validating
- **Key management**: Download public key from SendGrid dashboard and store on your server
- **Payload format**: `multipart/form-data` encoding (attachments delivered as file parts)

### Cloudflare Email Workers

- **Mechanism**: Route inbound email to a Cloudflare Worker via Email Routing
- **Authentication**: Worker receives full email (from, to, headers, raw body stream) and implements custom logic
- **No built-in auth**: You implement your own authentication in the Worker (check sender, parse TOTP/HMAC from body, etc.)
- **Advantage**: Runs on Cloudflare edge, integrates with D1 database, KV store, and can call external APIs
- **Example use**: Parse inbound email, verify HMAC signature in body, trigger webhook to downstream service

---

## 4. Open-Source Email-to-Command Projects

### PopExe (Email Command Execution)
- **Repo**: [github.com/msalguer/PopExe](https://github.com/msalguer/PopExe)
- **What it does**: Reads emails via POP3/SMTP, extracts commands, executes them on the host PC
- **Language**: PowerShell-based ecosystem
- **Auth**: Uses authenticated POP3 email account (Gmail, Yahoo). Commands are PowerShell scripts, batch files, or console executables.
- **Limitation**: Authentication is email-account-level only -- no per-message cryptographic verification

### Laravel Mailbox (Inbound Email Processing Framework)
- **Repo**: [github.com/beyondcode/laravel-mailbox](https://github.com/beyondcode/laravel-mailbox)
- **Package**: `composer require beyondcode/laravel-mailbox`
- **What it does**: Catches incoming emails from Mailgun, SendGrid, or local driver and routes them to handler classes (like route handlers for HTTP)
- **Language**: PHP/Laravel
- **Auth**: Inherits authentication from the email service driver (Mailgun signature verification, SendGrid ECDSA). Stores inbound emails in database with configurable retention.
- **Use pattern**: Define mailbox handlers that match email patterns and execute logic

### Hermes Secure Email Gateway
- **Repo**: [github.com/deeztek/Hermes-Secure-Email-Gateway](https://github.com/deeztek/Hermes-Secure-Email-Gateway)
- **What it does**: Full email gateway with SPF/DKIM/DMARC, spam/virus filtering, encryption
- **Platform**: Ubuntu 20.04 LTS
- **Relevance**: Not command execution, but comprehensive email authentication implementation

### Stalwart Mail Server
- **Repo**: [github.com/stalwartlabs/stalwart](https://github.com/stalwartlabs/stalwart)
- **Language**: Rust
- **What it does**: Full mail server with SMTP, IMAP, JMAP, CalDAV, CardDAV, WebDAV
- **Auth**: Built-in DMARC, DKIM, SPF, ARC support
- **Relevance**: Could serve as the inbound email receiver in an email-to-command architecture

### Chainmail (Blockchain-Authenticated Email)
- **Repo**: [github.com/circlefin/chainmail](https://github.com/circlefin/chainmail)
- **What it does**: Authenticated email using blockchain signatures
- **Relevance**: Novel approach to email authentication using on-chain verification

### Cloudflare Email Workers (Platform, not project)
- **Docs**: [developers.cloudflare.com/email-routing/email-workers/](https://developers.cloudflare.com/email-routing/email-workers/)
- **What it does**: Process inbound email with serverless Workers
- **Auth**: Implement your own (full access to headers, body, envelope)
- **Advantage**: Edge-deployed, integrates with D1/KV/R2, can trigger any API

---

## 5. iOS Shortcuts for TOTP/Crypto with Biometric Gates

### Native iOS Shortcuts Crypto Capabilities

iOS Shortcuts natively supports:
- **Base64 Encode/Decode**: Built-in action
- **Generate Hash**: MD5 and SHA1 only (no SHA256, no HMAC)
- **No native TOTP generation**: Shortcuts cannot natively compute HMAC-SHA1/256 which TOTP requires

### Workarounds for TOTP in iOS Shortcuts

**Option A: SwiftOTP App + Siri Shortcuts Integration**
- **Repo**: [github.com/brunophilipe/SwiftOTP](https://github.com/brunophilipe/SwiftOTP)
- TOTP/HOTP app written in Swift with Siri and Shortcuts integration
- Exposes an intent that places the OTP code on the pasteboard for 3 seconds
- Shortcut can: require Face ID -> call SwiftOTP intent -> get TOTP code -> compose email with code

**Option B: Scriptable App (JavaScript Runtime on iOS)**
- Scriptable runs JavaScript on iOS with access to the Web Crypto API
- Community discussion confirms HMAC-SHA256 can be generated via Scriptable
- Pattern: Shortcuts action "Run Scriptable Script" -> JS computes TOTP/HMAC -> returns result to Shortcuts
- [Automators Talk thread on HMAC-SHA256 in Scriptable](https://talk.automators.fm/t/is-there-a-way-to-generate-a-sha256-hmac-hash-in-scriptable/9762)

**Option C: Built-in iOS Authenticator (iOS 15+)**
- iOS has a built-in TOTP authenticator at Settings > Passwords > [site] > Set Up Verification Code
- AutoFill pastes codes automatically
- But: not directly accessible from Shortcuts automation

### Biometric Gate Implementation

**iOS 18+ Method**: The Shortcuts app has a native "Require Authentication" / "Authenticate" action:
1. Create Shortcut
2. First action: "Authenticate" (triggers Face ID/Touch ID)
3. If auth fails -> Stop Shortcut
4. If auth succeeds -> proceed with TOTP generation and email sending

**Pre-iOS 18 Method**: Use the "Lock Screen" action (iOS 16.4+) or PreBoard app method to require biometric re-authentication.

**RoutineHub Shortcut**: [Authentication Shortcut](https://routinehub.co/shortcut/5537/) -- community shortcut that implements Face ID gate before proceeding.

### Recommended iOS Architecture

```
[User taps shortcut]
  -> [Face ID authentication required]
  -> [Scriptable: compute HMAC-SHA256(secret, timestamp + command)]
  -> [Shortcuts: compose email with command + signature + timestamp]
  -> [Send email via Mail action]
```

---

## 6. Alfred Workflows for Auth Token Generation on Mac

### Existing Alfred TOTP Workflows

**alfred-totp** (Primary recommendation)
- **Repo**: [github.com/gyaneesh/alfred-totp](https://github.com/gyaneesh/alfred-totp)
- Keyword: type "otp" then service name
- TOTP code auto-pasted to topmost app + copied to clipboard
- **Secrets stored in macOS Keychain** via `security` command (hardware-backed on Apple Silicon)

**alfred-workflow-gauth (Google Authenticator for Alfred)**
- **Repo**: [github.com/moul/alfred-workflow-gauth](https://github.com/moul/alfred-workflow-gauth)
- Google Authenticator equivalent for Alfred
- Generates TOTP codes on demand

**alfred-mfa-workflow**
- **Repo**: [github.com/u-minor/alfred-mfa-workflow](https://github.com/u-minor/alfred-mfa-workflow)
- Uses `oathtool` (installable via `brew install oath-toolkit`) for TOTP generation
- Secret keys encrypted with OpenSSL RSA key

**alfred-ente-auth (Ente Auth Integration)**
- **Repo**: [github.com/chkpwd/alfred-ente-auth](https://github.com/chkpwd/alfred-ente-auth)
- Integrates with Ente Auth (open-source authenticator)
- Uses Ente CLI to export secrets, stores in macOS Keychain

### Command-Line TOTP Tool (Underlies Several Workflows)

```bash
brew install oath-toolkit
# Generate TOTP from base32 secret:
oathtool --totp -b "JBSWY3DPEHPK3PXP"
# Output: 283914
```

### Custom Alfred Workflow for Email Command Auth

You could build a custom Alfred workflow that:
1. User types `cmd deploy-staging` in Alfred
2. Alfred script reads shared secret from Keychain
3. Computes HMAC-SHA256 using `openssl` or `oathtool`
4. Composes email with command + timestamp + signature
5. Opens in Mail.app or sends via `sendmail`/API

```bash
# In Alfred script filter:
SECRET=$(security find-generic-password -a "email-cmd-secret" -w)
TIMESTAMP=$(date +%s)
CMD="$1"
SIG=$(echo -n "${TIMESTAMP}\n${CMD}" | openssl dgst -sha256 -hmac "$SECRET" | awk '{print $2}')
# Pass to next action: compose email
```

---

## 7. Android Equivalents (Tasker, Automate)

### Tasker TOTP/HMAC Generation

**Tasker JavaScriptlet Approach** (Most flexible):

Tasker supports JavaScriptlet actions that can run arbitrary JavaScript. Using a pure-JS HMAC-SHA256 implementation:

- **Pure JS HMAC-SHA256**: [GitHub Gist by stevendesu](https://gist.github.com/stevendesu/2d52f7b5e1f1184af3b667c0b5e054b8) -- minimal, no dependencies, designed for minification
- Pattern:
  1. Store shared secret in Tasker variable
  2. JavaScriptlet computes HMAC-SHA256 or TOTP
  3. Compose email with result
  4. Send via email action

```javascript
// Tasker JavaScriptlet for TOTP generation
// Uses the otpauth algorithm directly

function hmacSha1(key, message) {
  // Pure JS HMAC implementation (or use bundled crypto-js)
  // ...
}

function generateTOTP(secret) {
  const epoch = Math.floor(Date.now() / 1000);
  const counter = Math.floor(epoch / 30);
  // HMAC-SHA1(secret, counter) -> truncate -> 6 digits
  // ...
  return code;
}

var totp = generateTOTP(global('SECRET'));
setGlobal('TOTP_CODE', totp);
```

**Tasker + AndOTP Integration**:
- [AndOTP](https://github.com/andOTP/andOTP) (unmaintained but functional) supports BroadcastReceivers
- Tasker can trigger broadcasts to AndOTP for backup operations
- However, direct TOTP extraction via broadcast is not supported

**Tasker + Aegis Integration**:
- Aegis Authenticator is the actively maintained successor to AndOTP
- Supports encrypted backups that Tasker could potentially parse

### Biometric Gate on Android

**Tasker Biometric Plugin**:
- Tasker supports the "Fingerprint" action and "Authentication Required" profile
- Can require biometric authentication before executing a task
- Pattern: Profile trigger -> Biometric auth -> JavaScriptlet HMAC -> Send email

**AutoInput Plugin**:
- Can interact with authenticator apps to extract displayed TOTP codes
- More fragile (relies on screen scraping) but works with any authenticator app

**Android Keystore + Biometric**:
- Android's Keystore system can store cryptographic keys that require biometric auth to use
- Keys stored in TEE (Trusted Execution Environment) or Strongbox
- Requires a native app wrapper, not directly accessible from Tasker

### Automate App (Alternative to Tasker)

- Flow-based automation with JavaScript expression support
- Can compute hashes and send emails
- Less community tooling than Tasker but more visual workflow design

---

## 8. Best Practices for Securing Email-Based Automation from Spoofing

### Layer 1: Email Authentication (Necessary but Not Sufficient)

**SPF (Sender Policy Framework)**:
- Publish DNS TXT record listing authorized sending IPs
- Keep under 10 DNS lookups
- Start with `~all` (softfail), move to `-all` after testing
- Also publish SPF for parked/non-sending domains

**DKIM (DomainKeys Identified Mail)**:
- Use 2048-bit keys (1024-bit is deprecated)
- Rotate keys periodically
- Sign with domain alignment (d= matches From: domain)

**DMARC (Domain-based Message Authentication, Reporting & Conformance)**:
- Start with `p=none` (monitoring), graduate to `p=quarantine`, then `p=reject`
- Requires both SPF and DKIM alignment
- Enable reporting (`rua=`) to monitor authentication failures

**Critical limitation**: SPF/DKIM/DMARC protect against domain spoofing but NOT against compromised legitimate accounts. If an attacker gains access to the authorized sender's email, these protocols provide zero protection.

### Layer 2: Cryptographic Message Authentication

**HMAC signing** (recommended):
- Sign `timestamp + nonce + command` with shared secret
- Verify signature on server side with timing-safe comparison
- Reject messages older than 5 minutes
- Rotate secrets periodically

**TOTP embedding** (simpler alternative):
- Include TOTP code in email body
- Widen acceptance window for email delivery delays (+/- 2-5 steps)
- Less secure than HMAC because code is not bound to message content

### Layer 3: Replay Attack Prevention

1. **Nonce tracking**: Include a unique random nonce in each email. Server stores seen nonces in Redis/database with TTL. Reject any duplicate nonce.
2. **Timestamp enforcement**: Reject messages with timestamp older than N minutes (5 min recommended)
3. **Sequence numbers**: Optional monotonically increasing counter. Server rejects any sequence number <= last seen.
4. **TOTP token caching**: If using TOTP, cache used tokens and reject reuse within the validity window.

```typescript
// Redis-based nonce + timestamp verification
import Redis from 'ioredis';
const redis = new Redis();

async function verifyMessage(nonce: string, timestamp: number): Promise<boolean> {
  // Check timestamp freshness (5 minute window)
  const age = Math.floor(Date.now() / 1000) - timestamp;
  if (age > 300 || age < -30) return false; // reject old or future-dated

  // Check nonce uniqueness (store with 10-min TTL)
  const key = `email-nonce:${nonce}`;
  const wasSet = await redis.set(key, '1', 'EX', 600, 'NX');
  return wasSet === 'OK'; // returns null if nonce already existed
}
```

### Layer 4: Defense in Depth

1. **Allowlist sender addresses**: Only process emails from known addresses (first-pass filter)
2. **Rate limiting**: Max N commands per hour per sender
3. **Command allowlisting**: Only allow specific predefined commands, never arbitrary execution
4. **Confirmation for destructive actions**: Require a second email confirmation for destructive commands (delete, deploy-prod)
5. **Audit logging**: Log every received command email with full headers, authentication result, action taken
6. **Alerting**: Notify admin on authentication failures, unusual command patterns, or rate limit hits

### Recommended Architecture (Multi-Layer)

```
[Sender Device]
  -> Face ID / biometric gate
  -> Generate HMAC-SHA256(secret, timestamp + nonce + command)
  -> Compose email: CMD, TIMESTAMP, NONCE, SIG fields
  -> Send via authenticated email account (SPF/DKIM/DMARC aligned)

[Receiving Server]
  -> Mailgun/SendGrid/Cloudflare Email Worker receives email
  -> Verify webhook signature (Mailgun HMAC / SendGrid ECDSA)
  -> Parse email body for CMD, TIMESTAMP, NONCE, SIG
  -> Verify HMAC signature (timing-safe)
  -> Check timestamp freshness (< 5 min)
  -> Check nonce uniqueness (Redis)
  -> Check sender allowlist
  -> Check command allowlist
  -> Execute command
  -> Log and alert
```

---

## Strategic Synthesis

### Three Scenarios Emerge

**Scenario A: Quick & Simple (Personal Use)**
- iOS Shortcut with Face ID gate -> SwiftOTP for TOTP -> embed in email
- Alfred workflow for Mac with Keychain-stored secret
- Server checks TOTP + sender address
- Good enough for low-risk personal automation

**Scenario B: Moderate Security (Team/Business)**
- HMAC-SHA256 signing with shared secret per user
- Mailgun inbound webhook with signature verification
- Redis-based nonce tracking + timestamp enforcement
- SPF/DKIM/DMARC on sender domain
- Suitable for internal automation, non-destructive commands

**Scenario C: High Security (Production/Infrastructure)**
- Full multi-layer architecture (all 4 layers above)
- Cloudflare Email Workers for edge processing
- HMAC + nonce + timestamp + sender allowlist + command allowlist
- Separate confirmation flow for destructive commands
- Hardware-backed key storage (macOS Keychain / Android Keystore)
- Audit logging and alerting

### Second-Order Effects to Consider

1. **Key distribution problem**: However you share secrets, that channel becomes the weakest link. Consider using a key exchange protocol or deriving keys from a password both parties know.
2. **Email reliability**: Email is inherently unreliable. Commands may be delayed or lost. Design for idempotency.
3. **Vendor lock-in**: Mailgun/SendGrid webhook formats differ. Abstract the verification layer.
4. **Secret rotation**: Plan for secret rotation from day one. Support two active secrets during transition.
5. **Mobile battery/network**: TOTP generation on mobile is lightweight, but sending email requires network. Consider queuing failed sends.

---

## Sources

- [otplib - TypeScript OTP library](https://github.com/yeojz/otplib)
- [otpauth - JS OTP library](https://github.com/hectorm/otpauth)
- [JS-OTP - Pure JS HOTP/TOTP](https://github.com/jiangts/JS-OTP)
- [HMAC Secrets Explained - GitGuardian](https://blog.gitguardian.com/hmac-secrets-explained-authentication/)
- [How to Generate and Verify HMAC Signatures - Authgear](https://www.authgear.com/post/generate-verify-hmac-signatures)
- [Mailgun Webhook Signature Verification](https://documentation.mailgun.com/docs/mailgun/user-manual/webhooks/securing-webhooks)
- [SendGrid Inbound Parse Security](https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/securing-your-parse-webhooks)
- [Cloudflare Email Workers](https://developers.cloudflare.com/email-routing/email-workers/)
- [PopExe - Email Command Execution](https://github.com/msalguer/PopExe)
- [Laravel Mailbox](https://github.com/beyondcode/laravel-mailbox)
- [SwiftOTP - iOS OTP with Shortcuts](https://github.com/brunophilipe/SwiftOTP)
- [alfred-totp - Alfred TOTP Workflow](https://github.com/gyaneesh/alfred-totp)
- [alfred-workflow-gauth - Google Auth for Alfred](https://github.com/moul/alfred-workflow-gauth)
- [alfred-mfa-workflow](https://github.com/u-minor/alfred-mfa-workflow)
- [alfred-ente-auth - Ente Auth for Alfred](https://github.com/chkpwd/alfred-ente-auth)
- [AndOTP - Android OTP](https://github.com/andOTP/andOTP)
- [totp-kt - Kotlin TOTP](https://github.com/robinohs/totp-kt)
- [Pure JS HMAC-SHA256](https://gist.github.com/stevendesu/2d52f7b5e1f1184af3b667c0b5e054b8)
- [Web Crypto API TOTP Generation](https://shkspr.mobi/blog/2025/03/using-the-web-crypto-api-to-generate-totp-codes-in-javascript-without-3rd-party-libraries/)
- [SPF/DKIM/DMARC Best Practices 2026](https://www.uriports.com/blog/spf-dkim-dmarc-best-practices/)
- [Stalwart Mail Server](https://github.com/stalwartlabs/stalwart)
- [Chainmail - Blockchain Email Auth](https://github.com/circlefin/chainmail)
- [Replay Attack Prevention with Nonces](https://dev.to/raselmahmuddev/protecting-api-requests-using-nonce-redis-and-time-based-validation-11nd)
- [HMAC Verification Tokens - Rotational Labs](https://rotational.io/blog/hmac-verification-tokens/)
- [GitLab Pipeline Trigger Tokens](https://docs.gitlab.com/ci/triggers/)
- [RoutineHub Authentication Shortcut](https://routinehub.co/shortcut/5537/)
- [TOTP via Web Crypto API](https://dev.to/alex_tokyo/generating-2fa-one-time-passwords-in-js-using-web-crypto-api-1hfo)
- [Hermes Secure Email Gateway](https://github.com/deeztek/Hermes-Secure-Email-Gateway)
