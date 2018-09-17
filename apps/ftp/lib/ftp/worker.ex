require Logger

defmodule FTP.Worker do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{cwd: "/", root_dir: System.get_env("ROOTDIR") || File.cwd!} end)
  end

  def cwd(state, path) do
    Agent.update(state, fn (state) ->
      base = Map.get(state, :root_dir)
      cwd = Map.get(state, :cwd)
      new_wd = Path.expand(path, cwd)

      full_path = Path.join(base, new_wd)
      Logger.info "#{inspect self()} #{full_path} #{File.dir?(full_path)}"
      if File.dir?(full_path) do
        Map.put(state, :cwd, new_wd)
      else
        state
      end
    end)
  end

  def pwd(state) do
    Agent.get(state, &Map.get(&1, :cwd))
  end
end
