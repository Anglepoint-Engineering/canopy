defmodule Mix.Tasks.Canopy.Github do
  use Mix.Task

  alias Canopy.Github.Pr
  alias Canopy.Storage
  alias Canopy.Coverage.Line

  def run(_) do
    if System.get_env("GITHUB_EVENT_NAME") != "pull_request",
      do: raise("Not a pull request event.")

    github_token!() |> process_pull_request!()
  end

  defp github_token! do
    System.get_env("GITHUB_TOKEN") || raise "No GitHub token found."
  end

  defp process_pull_request!(token) do
    event_data = System.get_env("GITHUB_EVENT_PATH") |> File.read!() |> :json.decode()
    {owner, repo} = extract_owner_repo!()

    with {:ok, files_changed} <- Pr.get_files_changed(token, owner, repo, event_data["number"]),
         uncovered_files <-
           cross_reference_uncovered_files(files_changed, Storage.load!("line_coverage")),
         :ok <-
           Pr.annotate_pr(
             token,
             owner,
             repo,
             get_in(event_data, ["pull_request", "head", "sha"]),
             uncovered_files
           ) do
      :ok
    else
      error -> raise "Error processing pull request: #{inspect(error)}"
    end
  end

  defp extract_owner_repo! do
    case System.get_env("GITHUB_REPOSITORY") |> String.split("/") do
      [owner, repo] -> {owner, repo}
      result -> raise "unhandled github repo pattern: #{result}"
    end
  end

  defp cross_reference_uncovered_files(files_changed, line_coverage) do
    lines_by_file_name =
      line_coverage
      |> Enum.reduce(%{}, fn {_module, %Line{file_path: file_path} = line}, coverage ->
        Map.update(coverage, Path.basename(file_path), [], &(&1 ++ [line]))
      end)

    files_changed
    |> Enum.flat_map(fn {file_name, lines_changed} ->
      lines_by_file_name[file_name]
      |> Enum.map(fn %Line{file_path: file_path, is_covered: is_covered} ->
        {file_path, lines_changed -- is_covered}
      end)
    end)
  end
end
