all: test

setup:
	bin/setup

test:
	bundle exec rake test

lint:
	bundle exec rubocop

lint-fix:
	bundle exec rubocop -a

sigs:
	bundle exec rbs -I sig validate

docs:
	bundle exec yard doc

console:
	bin/console

clean:
	rm -rf doc/ .yardoc/ coverage/

.PHONY: setup test all lint lint-fix sigs docs console clean
