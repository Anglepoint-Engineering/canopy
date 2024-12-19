defmodule Canopy.Coverage.Line do
  defstruct file_path: nil, is_covered: [], not_covered: []

  def lines_from_coverage(coverage_data, ignore_modules) do
    coverage_data
    |> Enum.reject(fn {{module, _line}, _count} -> MapSet.member?(ignore_modules, module) end)
    |> Enum.reduce(%{}, &bucket_line_coverage/2)
    |> Enum.map(&add_file_path/1)
    |> Enum.into(%{})
  end

  defp bucket_line_coverage({{module, line}, coverage}, acc) when is_integer(line) do
    Map.update(acc, module, %__MODULE__{}, fn %__MODULE__{
                                                is_covered: is_covered,
                                                not_covered: not_covered
                                              } =
                                                existing ->
      case line do
        # this is triggered by macro code
        1 ->
          existing

        line ->
          if covered?(coverage) do
            %__MODULE__{existing | is_covered: is_covered ++ [line]}
          else
            %__MODULE__{existing | not_covered: not_covered ++ [line]}
          end
      end
    end)
  end

  defp covered?({1, 0}), do: true
  defp covered?({0, 1}), do: false
  defp covered?(coverage), do: raise("unhandled coverage result: #{coverage}")

  defp add_file_path({module, %__MODULE__{} = line}) do
    file_path = module.module_info(:compile)[:source] |> Path.relative_to(File.cwd!())
    {module, %__MODULE__{line | file_path: file_path}}
  end
end
