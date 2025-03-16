path_capture_group="\(.*\)" # capture group 1
action_capture_group="(\(.*\))" # capture group 2
reformatted="(\2)\t\1" # action followed by path separated with tab
sed_pattern="s/$path_capture_group $action_capture_group/$reformatted/p"

if yes no | "$TRY" "$CMD" 2>&1 | # Don't actually commit anything, just track changes
	sed -n "/(.*)/{$sed_pattern}" | # Reformat file change logs for ease of reading
	sort | diff -wB "$EXPECTED" -; then
	echo "Success" >&2
else
	echo "Fail" >&2
fi
