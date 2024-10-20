defmodule Canopy.Coverage.NodeTest do
  use ExUnit.Case

  alias Canopy.Coverage.Line
  alias Canopy.Coverage.Node

  test "create node tree from lines" do
    assert %Node{
             cov: 3,
             not_cov: 3,
             children: %{
               canopy: %Node{
                 cov: 3,
                 not_cov: 3,
                 children: %{
                   "Canopy" => %Node{
                     cov: 3,
                     not_cov: 3,
                     children: %{"Storage" => %Node{cov: 3, not_cov: 3}}
                   }
                 }
               }
             }
           } =
             Node.tree_coverage_by_module(%Node{}, Canopy.Storage, %Line{
               is_covered: [1, 3, 5],
               not_covered: [2, 4, 6]
             })
  end
end
