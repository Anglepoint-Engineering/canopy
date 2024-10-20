defmodule Mix.Tasks.Canopy.Github do
  use Mix.Task

  require Logger
  alias Canopy.Github.Pr
  alias Canopy.Storage
  alias Canopy.Coverage.Line

  def run(_) do
    github_token!() |> process_pull_request!()
  end

  defp github_token! do
    System.get_env("GITHUB_TOKEN") || raise "No GitHub token found."
  end

  defp process_pull_request!(token) do
    event_data = System.get_env("GITHUB_EVENT_PATH") |> File.read!() |> :json.decode()
    {owner, repo} = extract_owner_repo!()

    with {:ok, files_changed} <- Pr.get_files_changed(token, owner, repo, event_data["number"]),
         missing_coverage <-
           code_changes_missing_coverage!(files_changed, Storage.load!("line_coverage")),
         :ok <-
           Pr.annotate_pr(
             token,
             owner,
             repo,
             get_in(event_data, ["pull_request", "head", "sha"]),
             missing_coverage
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

  defp code_changes_missing_coverage!(files_changed, line_coverage) do
    Logger.debug(
      "cross referencing code changes on: #{length(files_changed)} file(s), " <>
        "with line coverage on: #{map_size(line_coverage)} module(s)"
    )

    lines_by_file_name =
      line_coverage
      |> Enum.reduce(%{}, fn {_module, %Line{file_path: file_path} = line}, coverage ->
        Map.put(coverage, file_path, line)
      end)

    files_changed
    |> Enum.map(fn {file_name, lines_changed} ->
      Logger.debug("checking for crossover on: #{file_name}")

      case lines_by_file_name[file_name] do
        %Line{file_path: file_path, not_covered: not_covered} ->
          Logger.debug("intersecting missing coverage on: #{file_path}")

          case lines_changed |> intersection(not_covered) do
            [] -> nil
            uncovered_lines -> {file_path, uncovered_lines}
          end

        nil ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp intersection(a, b), do: Enum.filter(a, &Enum.member?(b, &1))
end
