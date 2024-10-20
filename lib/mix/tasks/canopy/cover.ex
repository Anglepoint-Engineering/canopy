defmodule Mix.Tasks.Canopy.Cover do
  use Mix.Task

  @shortdoc "Test cross coverage of all umbrella apps together."

  require Logger
  alias Canopy.Storage
  alias Canopy.Coverage.Line

  def run(_) do
    :cover.start()

    compile_umbrella_apps()

    # Run tests for all apps
    Mix.Task.run("test")

    # Collect and generate coverage report
    {:result, coverage_data, _} = :cover.analyse(:coverage, :line)
    Logger.debug("captured coverage for: #{length(coverage_data)} LOC")

    coverage_data
    |> Line.lines_from_coverage()
    |> tap(&Logger.debug("parsed coverage for: #{map_size(&1)} module(s)"))
    |> Storage.persist!("line_coverage")

    :cover.stop()
  end

  defp compile_umbrella_apps do
    Mix.Dep.Umbrella.loaded()
    |> tap(&Logger.debug("compiling test coverage for: #{length(&1)} app(s)"))
    |> Enum.map(&(Path.join(&1.opts[:build], "ebin") |> String.to_charlist()))
    |> Enum.each(&:cover.compile_beam_directory(&1))
  end
end
