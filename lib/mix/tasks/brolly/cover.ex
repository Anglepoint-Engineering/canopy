defmodule Mix.Tasks.Brolly.Cover do
  use Mix.Task

  @shortdoc "Test cross coverage of all umbrella apps together."

  alias Brolly.Storage
  alias Brolly.Coverage.Line
  alias Brolly.Coverage.Node

  def run(_) do
    :cover.start()

    compile_umbrella_apps()

    # Run tests for all apps
    Mix.Task.run("test")

    # Collect and generate coverage report
    {:result, coverage_data, _} = :cover.analyse(:coverage, :line)

    coverage_data
    |> Line.lines_from_coverage()
    |> Storage.persist!("line_coverage")
    |> Node.node_tree_from_lines()
    |> Storage.persist!("node_coverage")

    :cover.stop()
  end

  defp compile_umbrella_apps do
    Mix.Dep.Umbrella.loaded()
    |> Enum.map(&(Path.join(&1.opts[:build], "ebin") |> String.to_charlist()))
    |> Enum.each(&:cover.compile_beam_directory(&1))
  end
end
