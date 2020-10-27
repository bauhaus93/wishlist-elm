ELM = npx elm
UGLIFY = npx uglifyjs
WWW_DIR = www

all: $(WWW_DIR)/elm.js

run: $(WWW_DIR)/elm.js
	node app.js

deploy: $(WWW_DIR)/elm.js
	git push heroku main

.PHONY: npm
npm:
	npm install

$(WWW_DIR)/elm.js: src/*.elm src/Page/*.elm
	@$(ELM) make src/Main.elm --optimize --output=$(WWW_DIR)/elm.js && \
	$(UGLIFY) $(WWW_DIR)/elm.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | \
	$(UGLIFY) --mangle --output $(WWW_DIR)/elm.min.js

clean:
	@rm -fv $(WWW_DIR)/elm.js $(WWW_DIR)/elm.min.js

