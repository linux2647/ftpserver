defmodule Server do
  require Logger

  @moduledoc """
  Documentation for Server.
  """

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Server.TaskSupervisor, fn -> hello(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp hello(socket) do
    {:ok, {ip_address, _port}} = :inet.peername(socket)
    ip_address_str = ip_address |> Tuple.to_list |> Enum.join(".")
    Logger.info("Connected from #{ip_address_str}")

    {:ok, worker} = DynamicSupervisor.start_child(FTP.Worker.Supervisor, FTP.Worker)
    write_line(socket, {:ok, {220, "Hello from FTPServer, written in Elixir"}})
    serve(socket, worker)
  end

  defp serve(socket, worker) do
    msg = with {:ok, data} <- read_line(socket),
               {:ok, command} <- Server.Command.parse(data),
               do: Server.Command.run(command, worker)

    response = write_line(socket, msg) 

    unless response == :quit do
      serve(socket, worker)
    end
  end

  defp read_line(socket) do :gen_tcp.recv(socket, 0) end

  defp write_line(socket, {:ok, {status_code, message}}) do
    :gen_tcp.send(socket, "#{status_code} #{message}\r\n")
  end

  defp write_line(socket, {:error, {:unknown_command, command}}) do
    :gen_tcp.send(socket, "500 #{command} not understood\r\n")
  end

  defp write_line(socket, {:error, {status_code, message}}) do
    :gen_tcp.send(socket, "#{status_code} #{message}\r\n")
  end

  defp write_line(socket, {:error, message}) do
    :gen_tcp.send(socket, "500 #{message}\r\n")
  end

  defp write_line(_socket, {:quit, _text}) do
    # :gen_tcp.send(socket, text) #TODO this generates an error later on
    :quit
  end
end
