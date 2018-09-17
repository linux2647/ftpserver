defmodule FTPTest do
  use ExUnit.Case
  doctest FTP

  test "greets the world" do
    assert FTP.hello() == :world
  end
end
