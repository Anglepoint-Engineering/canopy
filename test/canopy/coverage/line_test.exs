defmodule Canopy.Coverage.LineTest do
  alias Canopy.Coverage.Line
  use ExUnit.Case

  defmodule TestModule do
  end

  test "skip lines 1" do
    coverage_data = %{
      {TestModule, 1} => {0, 1},
      {TestModule, 5} => {1, 0}
    }

    assert %{TestModule => %Line{is_covered: [5]}} =
             Line.lines_from_coverage(coverage_data, MapSet.new())
  end
end
