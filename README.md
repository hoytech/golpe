# golpe - C++ application framework

golpe is an opinionated framework for building C++ servers. It is specially tailored for building websocket servers that interact with an embedded LMDB database.

Most of the framework is configured in a declarative manner, by editing a file named `golpe.yaml`.

## Features

* [LMDB](https://lmdb.tech/) database integration
  * C++17 fork of [lmdbxx](https://github.com/hoytech/lmdbxx/)
  * [RasgueaDB](https://github.com/hoytech/rasgueadb) indexing and query layer
  * [Flatbuffers](https://google.github.io/flatbuffers/) for DB record encoding (and optionally network transports)
  * [Quadrable](https://github.com/hoytech/quadrable) integration for anti-entropy replication
* Fork of [uWebsockets 0.14](https://github.com/hoytech/uWebSockets) (last version with websocket client support)
* Automatic detection of `cmd_*.cpp` files and git-like subcommand dispatching
* [taocpp config](https://github.com/taocpp/config) setup and hot reloading app when config file changes
* Setup of [loguru](https://github.com/emilk/loguru) logging with nice defaults
* [docopt.cpp](https://github.com/docopt/docopt.cpp) integration for command-line argument processing
* Flexible `make` build framework
* Lots of little conveniences

## Setup

Coming soon

## Example apps

Coming soon
