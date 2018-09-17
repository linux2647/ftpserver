defmodule Server.Command do
  def parse(line) do
    case String.split(line) do
      ["NOOP"] -> {:ok, {:noop}}
      ["PWD"] -> {:ok, {:pwd}}
      ["CWD", path] -> {:ok, {:cwd, path}}
      ["MKDIR", path] -> {:ok, {:mkdir, path}}
      ["RMD", path] -> {:ok, {:rmdir, path}}
      ["HELP"] -> {:ok, {:help}}
      ["STAT"] -> {:ok, {:status}}
      ["QUIT"] -> {:ok, {:quit}}
      [command | _] -> {:error, {:unknown_command, command}}
      _ -> {:error, {:unknown_command, ""}}
    end
  end

  def run(command, worker)

  def run({:noop}, _worker) do
    {:ok, {200, "NOOP command successful"}}
  end

  def run({:pwd}, worker) do
    # path = worker.pwd()
    path = FTP.Worker.pwd(worker)
    {:ok, {257, "\"#{path}\" is the current directory"}}
  end

  def run({:cwd, path}, worker) do
    # worker.cwd(path)
    if FTP.Worker.cwd(worker, path) do
      {:ok, {250, "CWD command successful"}}
    else
      {:error, {550, "\"#{path}\": No such file or directory"}}
    end
  end

  def run({:quit}, _worker) do
    {:quit, {221, "Goodbye."}}
  end
end
