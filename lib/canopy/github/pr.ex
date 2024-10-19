defmodule Canopy.Github.Pr do
  alias Canopy.Rest

  def get_files_changed(token, owner, repo, pr_number) do
    url = "https://api.github.com/repos/#{owner}/#{repo}/pulls/#{pr_number}/files"

    case Rest.get_json(url, github_headers(token)) do
      {:ok, json} -> {:ok, parse_code_changes(json)}
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

  def annotate_pr(token, owner, repo, sha, uncovered_files) do
    url = "https://api.github.com/repos/#{owner}/#{repo}/check-runs"

    Rest.post_json(url, github_headers(token), annotations_request(sha, uncovered_files))

    :ok
  end

  defp annotations_request(sha, uncovered_files) do
    %{
      "name" => "Canopy Coverage",
      "head_sha" => sha,
      "status" => "completed",
      "conclusion" => "success",
      "output" => %{
        "title" => "Annotation Results",
        "summary" => "Canopy code coverage analysis found issues.",
        "annotations" => uncovered_files |> Enum.flat_map(&annotation_request/1)
      }
    }
  end

  defp annotation_request(%{file_path: file_path, uncovered_lines: uncovered_lines}) do
    uncovered_lines
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
end
