.PHONY: setup migrate test clean

setup:
	psql -f schema/setup.sql

migrate:
	psql -f schema/migrations/*.sql

test:
	psql -f tests/run_tests.sql

clean:
	@echo "Drop and recreate database manually"
