defmodule Server.Command do
  def parse(line) do
    case String.split(line) do
      ["NOOP"] -> {:ok, {:noop}}
      ["PWD"] -> {:ok, {:pwd}}
      ["CWD", path] -> {:ok, {:cwd, path}}
      ["MKD", path] -> {:ok, {:mkdir, path}}
      ["RMD", path] -> {:ok, {:rmdir, path}}
      ["RMDA", path] -> {:ok, {:rm_tree, path}}
      ["PASV"] -> {:ok, {:pasv}}
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

  def run({:mkdir, path}, worker) do
    case FTP.Worker.mkdir(worker, path) do
      :ok -> {:ok, {257, "MKD command successful"}}
      {:error, error} -> {:error, {550, "Directory \"#{path}\" could not be created: \"#{inspect error}\""}}
    end
  end

  def run({:rmdir, path}, worker) do
    case FTP.Worker.rmdir(worker, path) do
      :ok -> {:ok, {250, "RMD command successful"}}
      {:error, error} -> {:error, {550, "Directory \"#{path}\" could not be removed: \"#{inspect error}\""}}
    end
  end

  def run({:rm_tree, path}, worker) do
    case FTP.Worker.rm_tree(worker, path) do
      :ok -> {:ok, {250, "RMDA command successful"}}
      {:error, error} -> {:error, {550, "Path \"#{path}\" could not be removed: \"#{inspect error}\""}}
    end
  end

  def run({:pasv}, worker) do
    case FTP.Worker.pasv(worker) do
      {:ok, {host, port}} -> {:ok, {227, "Entering Passive Mode (#{inspect host}, #{inspect port})"}}
      {:error, error} -> {:error, {550, "Unable to enter Passive Mode: \"#{inspect error}\""}}
    end
  end

  def run({:quit}, _worker) do
    {:quit, {221, "Goodbye."}}
  end
end
