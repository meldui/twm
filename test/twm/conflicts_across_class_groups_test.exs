defmodule Twm.ConflictsAcrossClassGroupsTest do
  use ExUnit.Case, async: true

  import Twm

  test "handles conflicts across class groups correctly" do
    assert merge("inset-1 inset-x-1") == "inset-1 inset-x-1"
    assert merge("inset-x-1 inset-1") == "inset-1"
    assert merge("inset-x-1 left-1 inset-1") == "inset-1"
    assert merge("inset-x-1 inset-1 left-1") == "inset-1 left-1"
    assert merge("inset-x-1 right-1 inset-1") == "inset-1"
    assert merge("inset-x-1 right-1 inset-x-1") == "inset-x-1"
    assert merge("inset-x-1 right-1 inset-y-1") == "inset-x-1 right-1 inset-y-1"
    assert merge("right-1 inset-x-1 inset-y-1") == "inset-x-1 inset-y-1"
    assert merge("inset-x-1 hover:left-1 inset-1") == "hover:left-1 inset-1"
  end

  test "ring and shadow classes do not create conflict" do
    assert merge("ring shadow") == "ring shadow"
    assert merge("ring-2 shadow-md") == "ring-2 shadow-md"
    assert merge("shadow ring") == "shadow ring"
    assert merge("shadow-md ring-2") == "shadow-md ring-2"
  end

  test "touch classes do create conflicts correctly" do
    assert merge("touch-pan-x touch-pan-right") == "touch-pan-right"
    assert merge("touch-none touch-pan-x") == "touch-pan-x"
    assert merge("touch-pan-x touch-none") == "touch-none"
    assert merge("touch-pan-x touch-pan-y touch-pinch-zoom") == "touch-pan-x touch-pan-y touch-pinch-zoom"
    assert merge("touch-manipulation touch-pan-x touch-pan-y touch-pinch-zoom") == "touch-pan-x touch-pan-y touch-pinch-zoom"
    assert merge("touch-pan-x touch-pan-y touch-pinch-zoom touch-auto") == "touch-auto"
  end

  test "line-clamp classes do create conflicts correctly" do
    assert merge("overflow-auto inline line-clamp-1") == "line-clamp-1"
    assert merge("line-clamp-1 overflow-auto inline") == "line-clamp-1 overflow-auto inline"
  end
end