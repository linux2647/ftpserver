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
      ["LIST"] -> {:ok, {:list}}
      ["RETR", path] -> {:ok, {:retrieve, path}}
      ["STOR", path] -> {:ok, {:store, path}}
      ["HELP"] -> {:ok, {:help}}
      ["STAT"] -> {:ok, {:status}}
      ["QUIT"] -> {:ok, {:quit}}
      [command | _] -> {:error, {:unknown_command, command}}
      _ -> {:error, {:unknown_command, ""}}
    end
  end

  def run({:noop}, _worker, _opts) do
    {:ok, {200, "NOOP command successful"}}
  end

  def run({:pwd}, worker, _opts) do
    path = FTP.Worker.pwd(worker)
    {:ok, {257, "\"#{path}\" is the current directory"}}
  end

  def run({:cwd, path}, worker, _opts) do
    if FTP.Worker.cwd(worker, path) do
      {:ok, {250, "CWD command successful"}}
    else
      {:error, {550, "\"#{path}\": No such file or directory"}}
    end
  end

  def run({:mkdir, path}, worker, _opts) do
    case FTP.Worker.mkdir(worker, path) do
      :ok -> {:ok, {257, "MKD command successful"}}
      {:error, error} -> {:error, {550, "Directory \"#{path}\" could not be created: \"#{inspect error}\""}}
    end
  end

  def run({:rmdir, path}, worker, _opts) do
    case FTP.Worker.rmdir(worker, path) do
      :ok -> {:ok, {250, "RMD command successful"}}
      {:error, error} -> {:error, {550, "Directory \"#{path}\" could not be removed: \"#{inspect error}\""}}
    end
  end

  def run({:rm_tree, path}, worker, _opts) do
    case FTP.Worker.rm_tree(worker, path) do
      :ok -> {:ok, {250, "RMDA command successful"}}
      {:error, error} -> {:error, {550, "Path \"#{path}\" could not be removed: \"#{inspect error}\""}}
    end
  end

  def run({:pasv}, worker, _opts) do
    case FTP.Worker.pasv(worker) do
      {:ok, pasv_conn} -> {:ok, {227, "Entering Passive Mode (#{pasv_conn})"}}
      {:error, error} -> {:error, {550, "Unable to enter Passive Mode: \"#{inspect error}\""}}
    end
  end

  def run({:list}, worker, opts) do
    case FTP.Worker.list(worker, Map.get(opts, :write_callback)) do
      {:ok, message} -> {:ok, {226, message}}
      {:error, error} -> {:error, {550, "Unable to list directory contents: #{inspect error}"}}
    end
  end

  def run({:retrieve, path}, worker, opts) do
    case FTP.Worker.retrieve(worker, Map.get(opts, :write_callback), path) do
      {:ok, message} -> {:ok, {226, message}}
      {:error, error} -> {:error, {550, "Unable to retrieve file: #{inspect error}"}}
    end
  end

  def run({:store, path}, worker, opts) do
    case FTP.Worker.store(worker, Map.get(opts, :write_callback), path) do
      {:ok, message} -> {:ok, {226, message}}
      {:error, error} -> {:error, {550, "Unable to retrieve file: #{inspect error}"}}
    end
  end

  def run({:status}, worker, _opts) do
    case FTP.Worker.stat(worker) do
      {:ok, message} -> {:ok, {211, message}}
      {:error, error} -> {:error, {451, "Unable to retrieve status: #{inspect error}"}}
    end
  end

  def run({:quit}, _worker, _opts) do
    {:quit, {221, "Goodbye."}}
  end
end
