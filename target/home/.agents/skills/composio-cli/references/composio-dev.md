# Composio Dev

Load this file only when the user explicitly needs developer-project workflows. Do not lead with `composio dev` for ordinary top-level CLI usage.

## Use `dev init` To Bind A Directory

Use `composio dev init` when the user wants to attach the current directory to a developer project.

If later commands complain about missing developer project context, come back to `dev init`.

```bash
composio dev init -y --no-browser
```

## Run Tools In A Developer Project

Top-level `composio execute` and `composio link` act on your own account, in your consumer project. To run a tool inside a developer project, as its playground test user or the user given by `--user-id`, use `composio dev playground-execute`. It takes the same `-d`, `--get-schema`, and `--dry-run` flags as `execute`.

If it reports that the toolkit is not connected for that user, connect it with `composio dev connected-accounts link <toolkit>`, then retry.

```bash
composio dev playground-execute GMAIL_SEND_EMAIL --get-schema
composio dev playground-execute GMAIL_SEND_EMAIL -d '{ recipient_email: "a@b.com", subject: "Hello", body: "World" }'
composio dev connected-accounts link gmail
```

## Inspect Toolkits And Versions

Use toolkit commands to inspect developer-scoped capabilities:

```bash
composio dev toolkits list
composio dev toolkits info github
composio dev toolkits search "email"
composio dev toolkits version github
```

## Manage Auth Configs

Use auth-config commands when the user is configuring developer-project authentication behavior:

```bash
composio dev auth-configs list
```

## Manage Connected Accounts

Use developer connected-account commands when the user is working with developer-project users or auth-config-specific flows.

Top-level `composio link` is consumer-only. Use `dev connected-accounts link` for developer-project flows.

```bash
composio dev connected-accounts list
```

## Work With Triggers

Use trigger commands when the user is creating, inspecting, or listening to developer-project triggers.

```bash
composio dev triggers list
composio dev triggers info AGENT_MAIL_NEW_EMAIL_TRIGGER
```

## Inspect Logs

Use logs when the user is debugging tool executions or trigger deliveries inside a developer project.

```bash
composio dev logs tools
composio dev logs triggers
```

## Switch Or Inspect Org And Project Context

Use these commands when the user needs to confirm or change the active developer scope:

If the user wants to act on their own account rather than in a developer project, return to the top-level workflow instead of staying in `composio dev`.

```bash
composio orgs list
composio dev projects list
```
