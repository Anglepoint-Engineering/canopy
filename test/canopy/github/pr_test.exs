defmodule Canopy.Github.PrTest do
  use ExUnit.Case

  alias Canopy.Github.Pr

  @raw_pr_files_response [
    %{
      "sha" => "2310c3129a23b96c50697657af858f59d024d098",
      "filename" => ".gitattributes",
      "status" => "modified",
      "additions" => 1,
      "deletions" => 1,
      "changes" => 2,
      "blob_url" =>
        "https://github.com/githubtraining/hellogitworld/blob/343f6006cd4ed80cde061a2d44ee479a06e89a60/.gitattributes",
      "raw_url" =>
        "https://github.com/githubtraining/hellogitworld/raw/343f6006cd4ed80cde061a2d44ee479a06e89a60/.gitattributes",
      "contents_url" =>
        "https://api.github.com/repos/githubtraining/hellogitworld/contents/.gitattributes?ref=343f6006cd4ed80cde061a2d44ee479a06e89a60",
      "patch" =>
        "@@ -1,5 +1,5 @@\n # Auto detect text files and perform LF normalization\n-* text=auto\n+* text=jaga\n \n # Custom for Visual Studio\n *.cs     diff=csharp"
    }
  ]

  test "parse code changes" do
    assert [{".gitattributes", [2]}] = Pr.parse_code_changes(@raw_pr_files_response)
  end
end
