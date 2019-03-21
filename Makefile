# Convenience makefile to build the dev env and run common commands
# This example is for a pipenv-based pyramid project
.EXPORT_ALL_VARIABLES:
PIPENV_VENV_IN_PROJECT = 1

.PHONY: all
all: .installed

.PHONY: install
install:
	@rm -f .installed  # force re-install
	@make .installed

.installed: Pipfile Pipfile.lock
	@echo "Pipfile(.lock) is newer than .installed, (re)installing"
	@pipenv install --dev
	@pipenv run pre-commit install -f --hook-type pre-commit
	@pipenv run pre-commit install -f --hook-type pre-push
	@echo "This file is used by 'make' for keeping track of last install time. If Pipfile or Pipfile.lock are newer then this file (.installed) then all 'make *' commands that depend on '.installed' know they need to run pipenv install first." \
		> .installed

# Start database in docker in foreground
.PHONY: pgsql
pgsql: .installed
	@docker run -it --rm -v $(shell pwd)/.docker:/docker-entrypoint-initdb.d -p 5432:5432 postgres:9.6-alpine

.PHONY: start-pgsql
start-pgsql: .installed
	@docker start pgsql || docker run -d -v $(shell pwd)/.docker:/docker-entrypoint-initdb.d -p 5432:5432 --name pgsql postgres:9.6-alpine

.PHONY: clean-pgsql
clean-pgsql: .installed
	@docker stop pgsql || true
	@docker rm pgsql || true

.PHONY: stop-pgsql
stop-pgsql: .installed
	@docker stop pgsql || true

# Drop, recreate and populate development database with demo content
.PHONY: db
db: devdb

.PHONY: devdb
devdb: .installed
	@pipenv run python -m myapp.scripts.drop_tables
	@pipenv run alembic -c etc/development.ini -n app:myapp upgrade head
	@pipenv run python -m myapp.scripts.populate

# open devdb with pgweb, a fantastic browser-based postgres browser
.PHONY: pgweb
pgweb:
	@docker run -p 8081:8081 --rm -it --link pgsql:pgsql -e "DATABASE_URL=postgres://myapp_devpgsql:5432/myapp_dev?sslmode=disable" sosedoff/pgweb

# Run development server
.PHONY: run
run: .installed
	@pipenv run pserve etc/development.ini

# Testing and linting targets
.PHONY: lint
lint: .installed
	@pipenv run pre-commit run --all-files --hook-stage push

.PHONY: type
type: types

.PHONY: types
types: .installed
	@pipenv run mypy src/myapp

.PHONY: sort
sort: .installed
	@pipenv run isort -rc --atomic src/myapp
	@pipenv run isort -rc --atomic setup.py

.PHONY: fmt
fmt: format

.PHONY: black
black: format

.PHONY: format
format: .installed sort
	@pipenv run black src/myapp
	@pipenv run black setup.py

# anything, in regex-speak
filter = "."
# additional arguments for pytest
args = ""
pytest_args = --cov=myapp --cov-branch --ini etc/test.ini --ignore=src/myapp/store/tests/browser -k $(filter) $(args)

.PHONY: unit
unit: .installed
	@pipenv run python -m myapp.scripts.drop_tables -c etc/test.ini
	@pipenv run pytest src/myapp --cov-report html --cov-report xml:cov.xml --cov-report term-missing --cov-fail-under=100 $(pytest_args)

.PHONY: unit-watch
unit-watch: .installed
	@pipenv run ptw --beforerun "python -m myapp.scripts.drop_tables -c etc/test.ini" src/myapp -- $(pytest_args)

.PHONY: test
test: tests

.PHONY: tests
tests: format lint types unit

.PHONY: browser
browser: browser-tests

.PHONY: browser-tests
browser-tests: .installed
	@pipenv run python -m myapp.scripts.drop_tables -c etc/test.ini
	@MOZ_HEADLESS=1 REDIS_URL="sqla+postgresql://myapp_dev@localhost/myapp_test" pipenv run pytest -k $(filter) src/myapp/store/tests/browser \
		--splinter-webdriver firefox

.PHONY: clean
clean:
	@if [ -d ".venv/" ]; then pipenv --rm; fi
	@rm -rf .coverage htmlcov/ src/myapp.egg-info xunit.xml \
	    .git/hooks/pre-commit .git/hooks/pre-push
	@rm -f .installed
