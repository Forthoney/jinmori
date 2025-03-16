cleanup () {
	if [ -e "$EXPECTED" ]; then
		rm -f "$EXPECTED"
	fi
}

trap 'cleanup' EXIT

printf "Making a new project without providing default name...\t" >&2


EXPECTED=$(mktemp)
CMD="$JINMORI new"

. "$TESTS/checkexpect.sh"
