defmodule Mix.Tasks.Canopy.Lcov do
  use Mix.Task

  alias Canopy.Storage

  def run(_) do
    records =
      Storage.load!("line_coverage")
      |> Enum.map(&generate_lcov_record/1)

    Storage.template_path(["lcov.eex"])
    |> EEx.eval_file(records: records)
    |> Storage.artifact!("lcov.info")
  end

  def generate_lcov_record(
        {module, %{file_path: file_path, is_covered: is_covered, not_covered: not_covered}}
      ) do
    coverage =
      (Enum.map(is_covered, &{&1, 1}) ++ Enum.map(not_covered, &{&1, 0}))
      |> Enum.sort_by(fn {line, _} -> line end)

    %{
      test: module,
      file_path: file_path,
      coverage: coverage,
      total_lines: length(is_covered) + length(not_covered),
      lines_covered: length(is_covered)
    }
  end
end
