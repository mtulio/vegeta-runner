# vegeta-runner

[Vegeta](https://github.com/tsenart/vegeta) load test environment to run ramp-ups / batteries (while ATM of dev this repo it was not supported).

## Install

To install environment, the vegeta, please run:

`make install`

To force and version:

`make install VG_VERSION=x.x.x`

If you already have installed you can force the download:

`make download`
OR
`make upgrade`
OR
`make clean && make install`

## Setup

To setup environment, please create config files inside input directory. See [Readme](input/README.md)

## commands

### run

To run the tests, just tell what definition file of your test plan:

`make run INPUT_PLAN=input/sample-plan.conf`
