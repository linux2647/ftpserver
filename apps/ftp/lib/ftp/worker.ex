require Logger

defmodule FTP.Worker do
  use Agent
  use Bitwise

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
    {:ok, pasvconn} = PassiveConnection.start_link([])
    {:ok, host} = Agent.get_and_update(agent, fn (state) ->
      host = Map.get(state, :listen_addr)
      existing_socket = Map.get(state, :pasv)
      if existing_socket != nil do
        PassiveConnection.close(pasvconn)
      end

      new_state = Map.put(state, :pasv, pasvconn)
      {{:ok, host}, new_state}
    end)

    {:ok, port} = PassiveConnection.get_port(pasvconn)
    pasv_string = ip_port_to_pasv(host, port)
    {:ok, pasv_string}
  end

  def list(agent, write_back) do
    pasv_conn = Agent.get(agent, fn (state) -> Map.get(state, :pasv) end)
    unless pasv_conn == nil do
      write_back.(150, "Opening ASCII mode data connection for file list")

      current_path = get_current_path(agent)
      listing = get_listing(current_path)
      PassiveConnection.write(pasv_conn, listing)
      PassiveConnection.close(pasv_conn)

      {:ok, "Transfer complete"}
    else
      {:error, "Passive mode required"}
    end
  end

  defp safe_path_join(state, path) do
    base = Map.get(state, :root_dir)
    cwd = Map.get(state, :cwd)

    new_wd = Path.expand(path, cwd)
    full_path = Path.join(base, new_wd)
    
    {new_wd, full_path}
  end

  defp get_current_path(agent) do
    state = Agent.get(agent, fn (state) -> state end)
    safe_path_join(state, ".")
  end

  defp ip_port_to_pasv(ip, port) do
    upper_port = port >>> 8
    lower_port = port &&& 255
    {a, b, c, d} = ip
    # Convert IP and port (e.g. 64943) to (192,168,1,22,253,175)
    "#{a},#{b},#{c},#{d},#{upper_port},#{lower_port}"
  end

  defp get_listing(path) do
    {message, status} = System.cmd("ls", ["-l", path], stderr_to_stdout: true)
    if status == 0 do
      [_total | listing] = String.split(String.trim(message), "\n")
      listing |> Enum.join("\n")
    else
      message
    end
  end
end
