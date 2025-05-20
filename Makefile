all: test

setup:
	bin/setup

test:
	bundle exec rake test

lint:
	bundle exec rubocop

lint-fix:
	bundle exec rubocop -a

typecheck:
	bundle exec steep check

docs:
	bundle exec yard doc

console:
	bin/console

clean:
	rm -rf doc/ .yardoc/ coverage/

.PHONY: setup test all lint lint-fix typecheck docs console clean
