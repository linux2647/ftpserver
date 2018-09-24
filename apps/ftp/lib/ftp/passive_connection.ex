defmodule PassiveConnection do
  use GenServer

  # Client

  def start_link(_opts) do
    {:ok, listening_socket} = :gen_tcp.listen(0, [:binary, packet: :line, active: false, reuseaddr: true])
    GenServer.start_link(__MODULE__, listening_socket)
  end

  def get_port(pid) do
    GenServer.call(pid, {:port})
  end

  def read(pid) do
    GenServer.call(pid, {:read})
  end

  def write(pid, data) do
    GenServer.call(pid, {:write, data})
  end

  def close(pid) do
    GenServer.call(pid, {:close})
  end

  # Server

  @impl true
  def init(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_call({:port}, _from, listening_socket) do
    {:reply, :inet.port(listening_socket), listening_socket}
  end

  @impl true
  def handle_call({:read}, _from, listening_socket) do
    {:ok, socket} = accept(listening_socket)
    {:ok, data} = :gen_tcp.recv(socket, 0)
    :gen_tcp.close(socket)
    :gen_tcp.close(listening_socket)
    {:reply, data, listening_socket}
  end

  @impl true
  def handle_call({:write, data}, _from, listening_socket) do
    {:ok, socket} = accept(listening_socket)
    :gen_tcp.send(socket, data)
    :gen_tcp.close(socket)
    :gen_tcp.close(listening_socket)
    {:noreply, listening_socket}
  end

  @impl true
  def handle_call({:close}, _from, listening_socket) do
    :gen_tcp.close(listening_socket)
    {:noreply, listening_socket}
  end

  defp accept(socket) do
    :gen_tcp.accept(socket)
  end
end
