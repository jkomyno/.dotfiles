# PR Examples from Composio SDK

These are real PRs merged into the Composio SDK by jkomyno. Use them as style reference.

## Example 1: Simple bug fix

**Title:** `fix(py): gemini for Tool Router`
**Branch:** `fix/gemini`

**Body:**
```
This PR:
- closes [PLEN-1036](https://linear.app/composio/issue/PLEN-1036/unable-to-use-tool-router-with-gemini-provider)
- fixes Gemini for Tool Router
```

## Example 2: Feature with code examples and context

**Title:** `feat(core): add typed schema for connection expired webhook events`
**Branch:** `feat/accept-conn-expired-events`

**Body:**
```
This PR:
- closes [PLEN-1398](https://linear.app/composio/issue/PLEN-1398)
- breaking:
  - metadata changed from typed object (with trigger_slug, trigger_id, etc.) to `Record<string, unknown>`
  - Any consumer accessing `result.rawPayload.metadata.trigger_slug` after verifyWebhook will get a compile error

## Summary

Add Zod schema (TypeScript) and TypedDict (Python) for typed handling of `composio.connected_account.expired` webhook events.

**Schemas:**
- `ConnectionExpiredEventSchema`: Full webhook event envelope validation
- `SingleConnectedAccountDetailedResponseSchema`: Matches `GET /api/v3/connected_accounts/{id}` response
- `WebhookConnectionMetadataSchema`: Project and org ID metadata

**Usage (TypeScript):**
\```typescript
import { ConnectionExpiredEventSchema } from '@composio/core';

const result = ConnectionExpiredEventSchema.safeParse(webhookPayload);
if (result.success) {
  const { data, metadata } = result.data;
  console.log(`Connection ${data.id} expired for user ${data.user_id}`);
  console.log(`Toolkit: ${data.toolkit.slug}`);
}
\```

**Usage (Python):**
\```python
from composio import is_connection_expired_event, ConnectionExpiredEvent

if is_connection_expired_event(payload):
    event: ConnectionExpiredEvent = payload  # type: ignore
    print(f"Connection {event['data']['id']} expired")
\```

## Context

This builds on #2553 which loosened V3 detection to accept any `composio.*` event type. Users can now type-safely parse connection expiration events in their webhook handlers.
```

## Example 3: Quick fix with short description

**Title:** `fix(core): loosen V3 webhook schema to accept any composio.* event type`
**Branch:** `fix/plen-1397-webhook-v3-detection`

**Body:**
```
This PR:
- closes [PLEN-1397](https://linear.app/composio/issue/PLEN-1397/verified-webhook-rolled-back-to-v2-format)
- loosens up webhook v3 schema
```

## Example 4: Feature with additional context

**Title:** `feat(ts/e2e): add Node.js e2e test about file roundtrip`
**Branch:** `feat/e2e-tests-file-roundtrip-2`

**Body:**
```
This PR:
- builds on top of https://github.com/ComposioHQ/composio/pull/2540
- closes [PLEN-1349](https://linear.app/composio/issue/PLEN-1349/add-tests-to-check-integrity-of-file-uploaded-from-sdk)
- adds Node.js e2e tests to verify the absence of file corruption in the upload/download roundtrip
```

## Example 5: Complex feature with before/after comparison

**Title:** `feat(ts/e2e): restore DEBUG.log, env var validation`
**Branch:** `fix/e2e-debug-log-restore`

**Body:**
```
This PR:
- closes [PLEN-1350](https://linear.app/composio/issue/PLEN-1350/fixtse2e-restore-lost-functionality)
- restores some Node.js e2e test behavior that was accidentally deleted
  - adds back DEBUG.log stdout/stderr forward for debuggability
  - adds back explicit env var validation, when `e2e(import.meta.url, { env: { ... }  })` is passed
```

## Example 6: Multi-concern fix with follow-up notes

**Title:** `fix(ts/core): trigger payload (v1, v2, v3)`
**Branch:** `fix/ts-trigger-webhooks-payload-v1-v2-v3`

**Body:**
```
This PR:
- closes [PLEN-1076](https://linear.app/composio/issue/PLEN-1076/webhook-signature-verification-failing-with-triggers-sdk)
- unifies webhook and pusher payload parsing in Triggers.ts via the new `tryParseVersionedPayload()` function
  - I manually checked the zod schemas from the Hermes repo
- adds ts example to subscribe to a webhook
- adds tests to make sure Python and TypeScript implementations of webhook handling are aligned
```
