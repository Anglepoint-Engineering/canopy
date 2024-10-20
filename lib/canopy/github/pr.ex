defmodule Canopy.Github.Pr do
  alias Canopy.Rest
  alias Canopy.Coverage.Line
  alias Canopy.Coverage.Node

  def get_files_changed(token, owner, repo, pr_number) do
    url = "https://api.github.com/repos/#{owner}/#{repo}/pulls/#{pr_number}/files"

    case Rest.get_json(url, github_headers(token)) do
      {:ok, response} -> {:ok, parse_code_changes(response)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp github_headers(token) do
    [
      {~c"Authorization", ~c"token #{token}"},
      {~c"Accept", ~c"application/vnd.github.v3+json"}
    ]
  end

  def parse_code_changes(files_response) when is_list(files_response) do
    files_response
    |> Enum.map(&{&1["filename"], extract_changed_lines(&1["patch"] || "")})
  end

  defp extract_changed_lines(patch) do
    String.split(patch, "\n")
    |> parse_patch_lines([], nil)
  end

  defp parse_patch_lines([], acc, _), do: Enum.reverse(acc)

  defp parse_patch_lines([line | rest], acc, current_line_info) do
    case Regex.run(~r/^@@ \-[\d,]+ \+(\d+),?(\d+)? @@/, line) do
      [_, start_line_str, _] ->
        start_line = String.to_integer(start_line_str)
        parse_patch_lines(rest, acc, {start_line - 1, start_line - 1})

      _ ->
        {_, current_line_num} = current_line_info || {0, 0}

        cond do
          String.starts_with?(line, "+") ->
            parse_patch_lines(
              rest,
              [current_line_num + 1 | acc],
              {current_line_num, current_line_num + 1}
            )

          String.starts_with?(line, "-") ->
            parse_patch_lines(rest, acc, {current_line_num, current_line_num})

          true ->
            parse_patch_lines(rest, acc, {current_line_num, current_line_num + 1})
        end
    end
  end

  def annotate_pr(token, owner, repo, sha, coverage, mode) do
    url = "https://api.github.com/repos/#{owner}/#{repo}/check-runs"

    case Rest.post_json(
           url,
           github_headers(token),
           annotations_request(sha, coverage, mode)
         ) do
      {:ok, _response} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp annotations_request(sha, coverage, mode) do
    annotations = coverage |> Enum.flat_map(&annotation_request/1)

    %{
      "name" => "Canopy Coverage",
      "head_sha" => sha,
      "status" => "completed",
      "conclusion" =>
        if Enum.empty?(annotations) do
          "success"
        else
          case mode do
            :info -> "success"
            :warn -> "action_required"
            :fail -> "failure"
          end
        end,
      "output" => %{
        "title" => "Coverage Results",
        "summary" =>
          if Enum.empty?(annotations) do
            "Code changes have complete coverage."
          else
            "Coce changes are missing some coverage."
          end,
        "details" => umbrella_overview(coverage),
        "annotations" => annotations
      }
    }
  end

  defp annotation_request(%Line{file_path: file_path, not_covered: not_covered}) do
    not_covered
    |> Enum.map(
      &%{
        "path" => file_path,
        "start_line" => &1,
        "end_line" => &1,
        "annotation_level" => "warning",
        "message" => "Line not covered by tests."
      }
    )
  end

  defp umbrella_overview(coverage) do
    %Node{children: apps} =
      coverage
      |> Enum.reduce(%Node{}, fn {file_path, line}, node ->
        node |> Node.tree_coverage_by_file_path(file_path, line)
      end)

    details =
      apps
      |> Enum.map(fn {app, %Node{cov: cov, not_cov: not_cov}} ->
        "#{app} - lines covered: #{cov}, not covered: #{not_cov}"
      end)
      |> Enum.join("\n")

    "Umbrella Coverage:\n#{details}"
  end
end
