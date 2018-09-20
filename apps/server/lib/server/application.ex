defmodule Server.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("FTP_PORT") || "21")

    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Server.Worker.start_link(arg)
      # {Server.Worker, arg},
      {Task.Supervisor, name: Server.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> Server.accept(port) end}, restart: :permanent),
      {DynamicSupervisor, name: FTP.Worker.Supervisor, strategy: :one_for_one}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
