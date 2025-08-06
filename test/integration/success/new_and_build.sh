$JINMORI new project
cd project
$JINMORI build
output=$(build/project.dbg)
if [ "$output" = "Hello, world!" ]; then
  exit 0
else
  exit 1
fi
