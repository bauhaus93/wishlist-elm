#/bin/sh

ELM_CMD='npx elm'
UGLIFY_CMD='npx uglifyjs'
PUBLIC_DIR='public'
ELM_FILE="$PUBLIC_DIR/elm.js"
ELM_MIN_FILE="$PUBLIC_DIR/elm.min.js"

$ELM_CMD make src/Main.elm --optimize --output=$ELM_FILE &&
	$UGLIFY_CMD $ELM_FILE --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' |
	$UGLIFY_CMD --mangle --output $ELM_MIN_FILE &&
	rm -f $ELM_FILE
