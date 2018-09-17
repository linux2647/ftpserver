# FTPServer

Simple FTP Server written in Elixir, to learn Elixir.

## Running

```shell
mix run --no-halt
```

Available environment variables:

* `PORT` port the server should listen on, defaults to 21
* `ROOTDIR` directory the server should root itself to, defaults to current working directory

## Current status

So far, a TCP client can connect to the server, get the current directory, change to a different directory, and disconnect.  Lots more to come!
