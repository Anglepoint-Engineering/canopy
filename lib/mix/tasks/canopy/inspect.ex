defmodule Mix.Tasks.Canopy.Inspect do
  use Mix.Task

  @shortdoc "Inspect canopy test coverage results."

  alias Canopy.Storage
  alias Canopy.Coverage.Node

  def run(_) do
    Storage.load!("line_coverage")
    |> Enum.reduce(%Node{}, fn {module, line}, node ->
      node |> Node.tree_coverage_by_module(module, line)
    end)
    |> render_layer()
  end

  defp render_layer(%Node{children: children}) do
    :io.format("~-18s ~-12s ~s~n", ["APPS", "LOC", "COVERAGE"])

    children
    |> Enum.map(fn {path, %Node{cov: cov, not_cov: not_cov}} ->
      loc = cov + not_cov

      percent =
        if not_cov > 0 do
          100 * cov / (cov + not_cov)
        else
          100.0
        end

      {path, loc, percent}
    end)
    |> Enum.sort_by(fn {_, loc, _} -> loc end, :desc)
    |> Enum.each(fn {path, loc, percent} ->
      :io.format("~-18s ~-12w ~s~n", [
        path,
        loc,
        percent |> color_escape_coverage!()
      ])
    end)
  end

  defp color_escape_coverage!(percent) do
    color =
      cond do
        percent < 20 ->
          IO.ANSI.red()

        percent < 40 ->
          IO.ANSI.light_red()

        percent < 60 ->
          IO.ANSI.yellow()

        percent < 80 ->
          IO.ANSI.light_green()

        percent <= 100 ->
          IO.ANSI.green()

        true ->
          raise ArgumentError, message: "invalide percentage: #{percent}"
      end

    color <> (Float.round(percent, 1) |> Float.to_string()) <> IO.ANSI.reset()
  end
end
