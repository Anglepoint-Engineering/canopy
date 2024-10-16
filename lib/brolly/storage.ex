defmodule Brolly.Storage do
  @work_dir "./brolly"
  @spec persist!(term(), binary()) :: term()
  def persist!(data, file) do
    File.mkdir_p!(@work_dir)

    "#{@work_dir}/#{file}.bin"
    |> File.write!(data |> :erlang.term_to_binary())

    data
  end

  @spec load!(binary()) :: term()
  def load!(file) do
    "#{@work_dir}/#{file}.bin"
    |> File.read!()
    |> :erlang.binary_to_term()
  end

  @spec template_path([binary()]) :: binary()
  def template_path(path) do
    Mix.Project.deps_paths()
    |> Map.get(:brolly)
    |> Path.join((["priv", "templates"] ++ path) |> Path.join())
  end

  @spec artifact!(term(), binary()) :: no_return()
  def artifact!(data, file) do
    File.mkdir_p!(@work_dir)

    "#{@work_dir}/#{file}" |> File.write!(data)
  end
end
