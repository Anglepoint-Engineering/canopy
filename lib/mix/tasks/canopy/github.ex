defmodule Mix.Tasks.Canopy.Github do
  use Mix.Task

  require Logger
  alias Canopy.Github.Pr
  alias Canopy.Storage
  alias Canopy.Coverage.Line

  @modes [:info, :warn, :fail]
  @default_mode :warn
  def run(args) do
    {opts, _remaining_args, _invalid} =
      OptionParser.parse(args,
        switches: [mode: :string],
        aliases: [m: :mode]
      )

    opts =
      case opts[:mode] do
        nil ->
          Keyword.put(opts, :mode, @default_mode)

        mode ->
          if Enum.member?(@modes, String.to_atom(mode)) do
            opts
          else
            raise ArgumentError, message: "unsupported mode: #{mode}"
          end
      end

    github_token!() |> process_pull_request!(opts)
  end

  defp github_token! do
    System.get_env("GITHUB_TOKEN") || raise "No GitHub token found."
  end

  defp process_pull_request!(token, mode: mode) do
    event_data = System.get_env("GITHUB_EVENT_PATH") |> File.read!() |> :json.decode()
    {owner, repo} = extract_owner_repo!()

    with {:ok, files_changed} <- Pr.get_files_changed(token, owner, repo, event_data["number"]),
         coverage <- code_change_coverage!(files_changed, Storage.load!("line_coverage")),
         :ok <-
           Pr.annotate_pr(
             token,
             owner,
             repo,
             get_in(event_data, ["pull_request", "head", "sha"]),
             coverage,
             mode
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

  defp code_change_coverage!(files_changed, line_coverage) do
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
      lines_changed |> line_intersection(lines_by_file_name[file_name])
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp line_intersection(_lines_changed, nil), do: nil

  defp line_intersection(lines_changed, %Line{
         file_path: file_path,
         is_covered: is_covered,
         not_covered: not_covered
       }) do
    Logger.debug("intersecting coverage on: #{file_path}")

    case {lines_changed |> intersection(is_covered), lines_changed |> intersection(not_covered)} do
      {[], []} ->
        nil

      {is_covered, not_covered} ->
        %Line{file_path: file_path, is_covered: is_covered, not_covered: not_covered}
    end
  end

  defp intersection(a, b), do: Enum.filter(a, &Enum.member?(b, &1))
end
