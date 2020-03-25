# Deprecated, use `pyramid-realworld-example-app` instead

This Makefile was always out-of-date because it was impossible to test it. These days, we maintain a "best practice" showcase of a Python app at https://github.com/niteoweb/pyramid-realworld-example-app/ and that repo has a fully functional [Makefile](https://github.com/niteoweb/pyramid-realworld-example-app/blob/master/Makefile) built according to the specs below.


# Makefile
We use Makefiles for all our projects to have a memorable way to install and run them, while allowing discovering of advanced commands.

The idea is that if I switch to a project I haven't worked on in a while, I know that I can run tests with `make test` and that I can start the program with `make run`. Any other commands, and more info about what they do in the background is always available inside the Makefiles.

This is heaps better than having basic commands documented in the `docs` folder:
* I don't have to consult documentation all the time, for every project, since there are slight differences between projects. Instead we have sane default for the 20% of commands we type in 80% of the time.
* The commands in documentation tend to bitrot fast since only people new to the project use them directly, seniors either have bash aliases or other shortcuts made for themselves. By keeping shortcuts in Makefile, everyone uses them and they keep on working.

# How it works?

We use a `.installed` file to mark most recent installation timestamp. Then when you run, for example, `make run`, Makefile will check if environment specification files (such as `Pipfile` and `Pipfile.lock`) have been modified *after* `.installed`. If yes, then an installation is required, and `make run` will first run the `install` step, only then the `run` step.

This allows people that are not full-time on the project and/or do not have experience with projects build requirements, to stay away from traps such as "oh, you should first reinstall X because yesterday we added dependency Y". If dependencies change, `make` will know that (re)installation is required.

# API

All projects' Makefiles should provide the following commands, if applicable:

### `make`

See `make install`

### `make install`

Force re-installation of the project. Even if `.installed` is newer than `Pipfile` and `Pipfile.lock`.

### `make run`

Run the program. For example, start Pyramid webserver in development mode.

### `make unit`

Run all unit tests. Supports `filter=foo` to run only a subset of tests that have `foo` in their (file)name.

### `make browser-tests`

Run all Selenium-based browser tests. Supports `filter=foo` to run only a subset of tests that have `foo` in their (file)name.

### `make format`

Format the codebase, for example with `black`.

### `make sort`

Sort all imports, to avoid doing it manually.

### `make types`

Run static type analysis over the codebase, to chase down potential bugs.

### `make lint`

Run linters such as `flake8`, to chase down potential bugs

### `make tests`

Run all lintes, type checks, formatting and lastly all unit tests.

### `make pgsql`

Run Postgresql in frontend mode. Usually provided via a Docker container.

### `make start|stop-pgsql`

Start/stop Postgresql in backend mode. Usually provided via a Docker container.

### `make devdb`

Purge and recreate a development Postgresql database, populate it with dummy data. In projects that rely on databases, this step is usually required before running `make run`.

### `make clean`

Remove any installed/compiled files so we can start from scratch. Usually followed by `make install` to do a "nuke-from-orbit" type of re-installation in case of strange bugs.

# Example

See `Makefile` in this repository.

# Troubleshooting

### Unknown locale type error

In the terminal, find out the locale type supported by the system by running `locale -a`.

And then, add the following line to your Makefile with the supported locale type by your system.

```Makefile
export LC_CTYPE=en_GB.UTF-8
```
