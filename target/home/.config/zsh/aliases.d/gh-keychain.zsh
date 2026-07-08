# gh over SSH can't reach the login keychain.
#
# An SSH session lands in a different macOS security session than the GUI login,
# so gh can't read its token from the login keychain there ("User interaction is
# not allowed" / empty keyring) and acts logged out.
#
# The only thing that actually needs the GUI session is *reading the token*, so
# pull it out once via keychain-run and hand it to a NATIVE gh as $GH_TOKEN.
# Running gh natively (rather than inside the GUI session via keychain-run) keeps
# your real ~/.ssh/config in effect, so gh subcommands that shell out to
# git-over-ssh (`repo clone`, `pr checkout`, `repo sync`, ...) still resolve
# github.com correctly instead of falling through to the GUI session's ssh.
if (( $+commands[keychain-run] )); then
	gh() {
		if [[ -n $SSH_CONNECTION && -z $GH_TOKEN ]]; then
			local _gh_token
			_gh_token="$(keychain-run gh auth token 2>/dev/null)"
			if [[ -n $_gh_token ]]; then
				GH_TOKEN="$_gh_token" command gh "$@"
				return
			fi
		fi
		command gh "$@"
	}
fi
