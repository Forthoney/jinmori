cleanup () {
	if [ -e "$EXPECTED" ]; then
		rm -f "$EXPECTED"
	fi
}

trap 'cleanup' EXIT

printf "Setting up jinmori without existing installation at specified location...\t" >&2

EXPECTED=$(mktemp)
CMD="$JINMORI setup --dest $JINMORI_TOP/destination"

cat <<EOF | sort >"$EXPECTED"
(added)	$JINMORI_TOP/destination/bin/jinmori
(created dir)	$JINMORI_TOP/destination
(created dir)	$JINMORI_TOP/destination/deps
(created dir)	$JINMORI_TOP/destination/bin
EOF

. "$TESTS/checkexpect.sh"
