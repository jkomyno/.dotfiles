# gh over SSH can't reach the login keychain.
#
# An SSH session lands in a different macOS security session than the GUI login,
# so the keychain that stores gh's token is not readable there ("User
# interaction is not allowed" / empty keyring), and gh acts logged out. Route gh
# through the GUI session via keychain-run — but only over SSH, since locally the
# keychain is already accessible and the wrapper would add a needless sudo hop.
if (( $+commands[keychain-run] )); then
	gh() {
		if [[ -n $SSH_CONNECTION ]]; then
			keychain-run gh "$@"
		else
			command gh "$@"
		fi
	}
fi
