$JINMORI new project
cd project
src/Flip.sml << EOF
val _ = print "World, hello!"
EOF
src/alt.mlb << EOF
local
  $(SML_LIB)/basis/basis.mlb
in
  Flip.sml
end
EOF
$JINMORI build --bin alt
output=$(build/alt.dbg)
if [ "$output" = "World, hello!" ]; then
  exit 0
else
  exit 1
fi
