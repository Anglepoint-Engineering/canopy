defmodule Mix.Tasks.Brolly.Html do
  use Mix.Task

  require EEx
  alias Brolly.Storage

  def run(_) do
    Storage.template_path(["html", "report.eex"])
    |> EEx.eval_file(coverage_data: Storage.load!("node_coverage") |> :json.encode())
    |> Storage.artifact!("report.html")
  end
end
