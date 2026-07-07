# TouchID-backed SSH (Secretive)

Authenticate SSH connections (for example `ssh m4pro`) with TouchID instead of a
key file on disk. The private key is generated inside the Mac's Secure Enclave
and can never be exported; every use pops a TouchID prompt. This is provided by
[Secretive](https://github.com/maxgoedjen/secretive), which exposes the Secure
Enclave keys through an SSH agent socket at
`~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh`.

## What the dotfiles track

- **The app.** `secretive` is in
  [`nanobrew-casks.Brewfile`](../install/macos/common/nanobrew-casks.Brewfile),
  so a fresh machine installs it automatically.

That is deliberately *all* that is tracked. The per-host SSH wiring lives in the
unmanaged `~/.ssh/config.local`, **not** in the tracked `~/.ssh/config`, because
only hosts whose `authorized_keys` hold your Secure Enclave public key should
route through Secretive. Pointing `IdentityAgent` at Secretive globally would
hijack *every* host — including ones that authenticate from your default
ssh-agent — and force a passphrase prompt (or an auth failure) on all of them.
Which hosts have an enclave key is machine-specific, so it belongs in
`config.local` alongside the host/IP/port.

## One-time setup

1. **Launch Secretive** (installed by the casks bundle) and let it install its
   agent, which creates the socket above.

2. **Create a key** in Secretive → *New Secret*. Enable *"Require Authentication
   before use"* (the TouchID gate). Copy its public key.

3. **Authorize the key on the remote:**

   ```sh
   pbpaste | ssh <host> 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
   ```

4. **Save the enclave public key locally** so ssh can select it, and point the
   host at Secretive in `~/.ssh/config.local`:

   ```sh
   # one-off: capture the enclave pubkey you just authorized
   ssh <host> 'grep secretive ~/.ssh/authorized_keys' > ~/.ssh/<host>_secretive.pub
   ```

   ```
   # ~/.ssh/config.local
   Host m4pro
     HostName <ip>
     Port <port>
     IdentityAgent ~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
     IdentityFile ~/.ssh/m4pro_secretive.pub
     IdentitiesOnly yes
   ```

   `IdentityAgent` routes only this host through Secretive; `IdentityFile` (the
   enclave *public* key) plus `IdentitiesOnly yes` makes ssh offer exactly that
   key, so it never falls back to an older on-disk key and never prompts for a
   passphrase — just TouchID.

5. **Connect.** `ssh m4pro` now prompts for TouchID.

## Keeping a fallback

The config above commits fully to the enclave key: if Secretive is not running,
its socket is gone and the host is unreachable until you start Secretive (or
temporarily comment out the `IdentityAgent`/`IdentityFile` lines to use your
old key). Your previous key still works — it just is not offered while these
lines are active. Leave the old key in the remote's `authorized_keys` as a
break-glass path.

## Removing it

Delete the enclave lines from the host's `~/.ssh/config.local` block (reverting
to your old `IdentityFile`), then remove the enclave key from the remote's
`~/.ssh/authorized_keys` and from Secretive.
