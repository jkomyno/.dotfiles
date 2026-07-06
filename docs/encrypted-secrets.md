# Encrypted secrets (mise + age)

Per-project secrets (API keys, database passwords, tokens) are stored **encrypted
inline** in each project's `mise.toml` using [mise's built-in `age`
encryption](https://mise.jdx.dev/environments/secrets/age.html). mise decrypts them
automatically when you `cd` into the project, so day to day it behaves exactly like a
plaintext `[env]` block — but the value at rest is ciphertext, safe to commit and safe
if a malicious `postinstall` script or a leaked backup grabs the file.

The `age` CLI is **not** required: mise has age support built in.

## How this repo wires it up

Two things are needed, and **both are already tracked** in
[`target/home/.config/mise/config.toml`](../target/home/.config/mise/config.toml), so
they deploy with the dotfiles and need no manual step on a new machine:

```toml
[settings]
# age encryption is experimental
experimental = true

[settings.age]
# use the Ed25519 SSH key as the age identity, not an age-keygen key file
ssh_identity_files = ["~/.ssh/id_ed25519"]
```

We deliberately use the **SSH key** as the age identity instead of running
`age-keygen`. `age-keygen` writes a raw, unprotected private key to
`~/.config/mise/age.txt`; anyone who steals that file decrypts everything, which defeats
the point. A passphrase-protected SSH key can instead live in the macOS Keychain and is
never stored in plaintext. (mise also falls back to `~/.ssh/id_ed25519` and
`~/.ssh/id_rsa` by default, but pinning the identity here is explicit and portable.)

## The one irreducible manual step

Encryption is asymmetric: a value encrypted for a given key can only be decrypted by
**that same private key**. That private key is a secret, so — by definition — it cannot
live in this public-ish dotfiles repo. Everything else is automated; this one thing is
not, and no encryption scheme can make it so.

So "just works on a new MacBook" means: once your age identity key is present at
`~/.ssh/id_ed25519`, every encrypted `mise.toml` value across all your projects decrypts
automatically, with nothing else to configure.

> **Important:** `setup.sh` bootstrap generates a *fresh, passphrase-less* `id_ed25519`
> per machine (see [`install/common/ssh.sh`](../install/common/ssh.sh)) for Git signing
> and GitHub auth. That auto-generated key is **not** a good age identity: it is unique
> to the machine (so it can't decrypt secrets encrypted elsewhere) and has no passphrase
> (so it's weak at rest). For portable, secure secrets, carry **one dedicated
> passphrase-protected key** to every machine and let it be `~/.ssh/id_ed25519`.

### First-time setup of the age identity key

Do this once, ever, and reuse the key on every machine:

```bash
# 1. Create a dedicated Ed25519 key WITH a passphrase (age at-rest protection depends on it).
ssh-keygen -t ed25519 -C "age-identity" -f ~/.ssh/id_ed25519
#    (enter a strong passphrase when prompted)

# 2. Store it in your password manager / hardware key so you can restore it on new machines.
```

### On each new MacBook

```bash
# Restore the key from your password manager to ~/.ssh/id_ed25519 (chmod 600), then:
/usr/bin/ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

`ssh-add --apple-use-keychain` caches the passphrase in the macOS Keychain, so mise
never prompts for it again. That is the entire per-machine setup — the mise flag and the
`ssh_identity_files` setting already arrived with the dotfiles.

## Daily use

Store a secret (run inside the project directory that owns it):

```bash
# --prompt reads the value without echoing it or leaking it to shell history
mise set --age-encrypt --prompt DB_PASSWORD
```

It lands encrypted in that directory's `mise.toml`:

```toml
[env]
DB_PASSWORD = { age = "YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IHNzaC1lZDI1NTE5..." }
```

Read it back / confirm decryption works:

```bash
mise set DB_PASSWORD   # prints the decrypted value
mise env | grep DB     # decrypted into the loaded environment
echo "$DB_PASSWORD"     # available to any process mise launches
```

To encrypt to an explicit recipient (e.g. adding a second machine's public key so both
keys can decrypt), pass it directly instead of relying on the default:

```bash
mise set --age-encrypt --age-ssh-recipient ~/.ssh/id_ed25519.pub --prompt API_TOKEN
```

## Notes and gotchas

- **Trust:** mise won't read a project `mise.toml` it doesn't trust. Run `mise trust`
  once per project (mise prompts you the first time).
- **Strict mode is on** (`age.strict = true`, the default): if the identity key is
  missing or can't decrypt a value, mise **fails** rather than silently loading a partial
  environment. That's the safe behavior. On a machine where you deliberately have no key,
  `mise settings set age.strict=false` skips undecryptable values instead of erroring.
- **Rotating machines:** to let a new key decrypt existing secrets, re-run
  `mise set --age-encrypt --age-ssh-recipient <old.pub> --age-ssh-recipient <new.pub> ...`
  for each secret. There is no bulk re-encrypt; carrying one key around avoids this
  entirely.
- The encrypted `mise.toml` values are per-project and live in each project's repo, **not**
  in this dotfiles repo. This repo only carries the global wiring (the flag + the setting).

## References

- mise age secrets: <https://mise.jdx.dev/environments/secrets/age.html>
- Source blog post (SSH-key-recipient approach):
  <https://blog.sh1ma.dev/en/articles/20260706_mise_age_encrypt_env>
