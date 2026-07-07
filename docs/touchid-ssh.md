# TouchID-backed SSH (Secretive)

Authenticate SSH connections (for example `ssh m4pro`) with TouchID instead of a
key file on disk. The private key is generated inside the Mac's Secure Enclave
and can never be exported; every use pops a TouchID prompt. This is provided by
[Secretive](https://github.com/maxgoedjen/secretive), which exposes the Secure
Enclave keys through an SSH agent socket.

## What the dotfiles track

- **The app.** `secretive` is in
  [`nanobrew-casks.Brewfile`](../install/macos/common/nanobrew-casks.Brewfile),
  so a fresh machine installs it automatically.
- **The SSH wiring.** [`~/.ssh/config`](../target/home/.ssh/config) has a
  `Match exec` block that routes SSH through Secretive's agent **only when its
  socket exists**. Until you complete the one-time setup below the block is inert,
  so SSH keeps using your normal keys and a fresh machine works out of the box.
  `github.com` is pinned to the default agent (`IdentityAgent SSH_AUTH_SOCK`) so
  git-over-SSH is never affected.

The one thing that is **not** tracked is which private machine you point at: host,
IP, and port belong in the unmanaged `~/.ssh/config.local` (see the note at the top
of `~/.ssh/config`).

## One-time setup on a new machine

1. **Launch Secretive** (installed by the casks bundle) and allow it to install
   its agent. It creates the socket at
   `~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh`,
   which is exactly what the tracked `~/.ssh/config` guards on.

2. **Create a key** in Secretive → *New Secret*. Enable *"Require
   Authentication before use"* (that is the TouchID gate). Copy its public key.

3. **Authorize the key on the remote.** Append the public key to the remote's
   `~/.ssh/authorized_keys`, e.g.:

   ```sh
   pbpaste | ssh m4pro 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
   ```

4. **(Optional) Register it with GitHub too**, so git-over-SSH also runs under
   TouchID: `gh ssh-key add <pubfile> --title "$(hostname -s) secure enclave"`.
   (You would then drop the `IdentityAgent SSH_AUTH_SOCK` pin on `github.com`.)

5. **Connect.** `ssh m4pro` now prompts for TouchID. Because the socket exists,
   the tracked `Match exec` block activates and offers the Secure Enclave key.

## Forcing TouchID for a specific host

By default SSH also still offers any on-disk `IdentityFile` for a host, so an
older key keeps working as a fallback. To require the TouchID key for a given
remote, add `IdentitiesOnly yes` to that host in `~/.ssh/config.local`:

```
Host m4pro
  HostName <ip>
  Port <port>
  IdentitiesOnly yes
```

## Removing it

Delete the key in Secretive and remove the corresponding line from the remote's
`~/.ssh/authorized_keys`. With the socket gone (or Secretive uninstalled) the
`Match exec` guard is false again and SSH reverts to your normal keys.
