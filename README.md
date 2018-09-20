# FTPServer

Simple FTP Server written in Elixir, to learn Elixir.

## Running

```shell
mix run --no-halt
```

Available environment variables:

* `FTP_ADDR` publicly accessible IP address for passive ports, defaults to `127.0.0.1`
* `FTP_PORT` port the server should listen on, defaults to 21
* `FTP_ROOT_DIR` directory the server should root itself to, defaults to current working directory

## Current status

So far, a TCP client can connect to the server, get the current directory, change to a different directory,
make a directory, delete a directory, delete a directory tree, start a passive mode connection,
and disconnect.  Lots more to come!
