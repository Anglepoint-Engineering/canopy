defmodule Canopy.Coverage.Node do
  defstruct cov: 0, not_cov: 0, children: %{}

  alias Canopy.Coverage.Line

  def tree_coverage_by_module(node, module, %Line{
        is_covered: is_covered,
        not_covered: not_covered
      }) do
    app = Application.get_application(module)

    # skip the Elixir prefix on all modules
    [_prefix | paths] = module |> Atom.to_string() |> String.split(".")

    node |> tree_coverage([app] ++ paths, {length(is_covered), length(not_covered)})
  end

  def tree_coverage_by_file_path(node, %Line{
        file_path: file_path,
        is_covered: is_covered,
        not_covered: not_covered
      }) do
    # skip the apps dir
    [_apps | paths] =
      file_path
      |> String.split("/")
      |> Enum.reject(&(&1 == "lib"))

    node |> tree_coverage(paths, {length(is_covered), length(not_covered)})
  end

  defp tree_coverage(_node, [], {cov, not_cov}), do: %__MODULE__{cov: cov, not_cov: not_cov}

  defp tree_coverage(
         %__MODULE__{children: children} = node,
         [current | rest],
         {cov, not_cov} = coverage
       ) do
    %__MODULE__{
      children:
        Map.put(
          children,
          current,
          Map.get(children, current, %__MODULE__{}) |> tree_coverage(rest, coverage)
        ),
      cov: node.cov + cov,
      not_cov: node.not_cov + not_cov
    }
  end
end
