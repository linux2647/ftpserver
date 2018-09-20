require Logger

defmodule FTP.Worker do
  use Agent

  def start_link(_opts) do
    raw_listen_addr = System.get_env("FTP_ADDR") || "127.0.0.1"
    listen_addr = case :inet.parse_address(to_charlist(raw_listen_addr)) do
      {:ok, ip_addr} -> ip_addr
      _ -> {127,0,0,1}
    end

    Agent.start_link(fn -> %{
        cwd: "/",
        root_dir: System.get_env("FTP_ROOT_DIR") || File.cwd!,
        listen_addr: listen_addr,
        pasv: nil,
      } end)
  end

  def cwd(agent, path) do
    Agent.update(agent, fn (state) ->
      {new_wd, full_path} = safe_path_join(state, path)

      Logger.info "#{inspect self()} #{full_path} #{File.dir?(full_path)}"
      if File.dir?(full_path) do
        Map.put(state, :cwd, new_wd)
      else
        state
      end
    end)
  end

  def pwd(agent) do
    Agent.get(agent, &Map.get(&1, :cwd))
  end

  def mkdir(agent, name) do
    state = Agent.get(agent, fn (state) -> state end)
    {_, full_path} = safe_path_join(state, name)
    File.mkdir_p(full_path)
  end

  def rmdir(agent, path) do
    state = Agent.get(agent, fn (state) -> state end)
    {_, full_path} = safe_path_join(state, path)
    File.rmdir(full_path)
  end

  def rm_tree(agent, path) do
    state = Agent.get(agent, fn (state) -> state end)
    {_, full_path} = safe_path_join(state, path)
    {status, _} =  File.rm_rf(full_path)
    status
  end

  def pasv(agent) do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, packet: :line, active: false, reuseaddr: true])
    {:ok, host} = Agent.get_and_update(agent, fn (state) ->
      host = Map.get(state, :listen_addr)
      existing_socket = Map.get(state, :pasv)
      if existing_socket != nil do
        :gen_tcp.close existing_socket
      end

      new_state = Map.put(state, :pasv, socket)
      {{:ok, host}, new_state}
    end)

    {:ok, port} = :inet.port socket
    {:ok, {host, port}}
  end

  defp safe_path_join(state, path) do
    base = Map.get(state, :root_dir)
    cwd = Map.get(state, :cwd)

    new_wd = Path.expand(path, cwd)
    full_path = Path.join(base, new_wd)
    
    {new_wd, full_path}
  end
end
