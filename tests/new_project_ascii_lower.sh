cleanup () {
	if [ -e "$EXPECTED" ]; then
		rm -f "$EXPECTED"
	fi
}

trap 'cleanup' EXIT

printf "Making a new project with all lowercase ascii project name...\t" >&2

proj="project"
cap_proj="Project"

EXPECTED=$(mktemp)
CMD="$JINMORI new $proj"

pwd=$(pwd)

cat <<EOF | sort >"$EXPECTED"
(created dir)	$pwd/$proj
(created dir)	$pwd/$proj/src
(created dir)	$pwd/$proj/tests
(created dir)	$pwd/$proj/bin
(added)	$pwd/$proj/Makefile
(added)	$pwd/$proj/$proj.mlb
(added)	$pwd/$proj/$proj.tests.mlb
(added)	$pwd/$proj/src/src.mlb
(added)	$pwd/$proj/src/$cap_proj.sml
(added)	$pwd/$proj/src/Exec.sml
(added)	$pwd/$proj/tests/$cap_proj.sml
EOF

. "$TESTS/checkexpect.sh"
