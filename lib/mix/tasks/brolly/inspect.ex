defmodule Mix.Tasks.Brolly.Inspect do
  use Mix.Task

  @shortdoc "Inspect Brolly test coverage results."

  alias Brolly.Storage
  alias Brolly.Coverage.Node

  def run(_) do
    Storage.load!("node_coverage") |> render_layer()
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
        percent < 33.33 ->
          IO.ANSI.red()

        percent < 66.67 ->
          IO.ANSI.yellow()

        percent <= 100 ->
          IO.ANSI.green()

        true ->
          raise ArgumentError, message: "invalide percentage: #{percent}"
      end

    color <> (Float.round(percent, 1) |> Float.to_string()) <> IO.ANSI.reset()
  end
end
