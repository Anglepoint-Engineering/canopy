defmodule Mix.Tasks.Canopy.Html do
  use Mix.Task

  require EEx
  alias Canopy.Storage

  def run(_) do
    Storage.template_path(["html", "report.eex"])
    |> EEx.eval_file(coverage_data: Storage.load!("node_coverage") |> :json.encode())
    |> Storage.artifact!("report.html")
  end
end
