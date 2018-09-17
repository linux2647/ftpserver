defmodule FTP do
  @moduledoc """
  Documentation for FTP.
  """

  # use Application

  def init(_arg) do
    Agent.start_link(fn -> %{cwd: "/"} end)
  end
end
