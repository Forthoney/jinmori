cleanup () {
	if [ -e "$EXPECTED" ]; then
		rm -f "$EXPECTED"
	fi
}

trap 'cleanup' EXIT

printf "Setting up jinmori without existing installation...\t" >&2

EXPECTED=$(mktemp)
CMD="$JINMORI setup"

cat <<EOF | sort >"$EXPECTED"
(added)	$HOME/.jinmori/bin/jinmori
(created dir)	$HOME/.jinmori
(created dir)	$HOME/.jinmori/deps
(created dir)	$HOME/.jinmori/bin
EOF

. "$TESTS/checkexpect.sh"
