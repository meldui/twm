defmodule Twm.TailwindCssVersionsTest do
  use ExUnit.Case, async: true

  describe "Tailwind CSS v3.3 features" do
    test "supports text line height syntax" do
      assert Twm.merge("text-red text-lg/7 text-lg/8") == "text-red text-lg/8"
    end

    test "supports logical properties" do
      assert Twm.merge(
               "start-0 start-1 end-0 end-1 ps-0 ps-1 pe-0 pe-1 ms-0 ms-1 me-0 me-1 rounded-s-sm rounded-s-md rounded-e-sm rounded-e-md rounded-ss-sm rounded-ss-md rounded-ee-sm rounded-ee-md"
             ) ==
               "start-1 end-1 ps-1 pe-1 ms-1 me-1 rounded-s-md rounded-e-md rounded-ss-md rounded-ee-md"
    end

    test "supports logical property conflicts with physical properties" do
      assert Twm.merge(
               "start-0 end-0 inset-0 ps-0 pe-0 p-0 ms-0 me-0 m-0 rounded-ss rounded-es rounded-s"
             ) == "inset-0 p-0 m-0 rounded-s"
    end

    test "supports hyphens utilities" do
      assert Twm.merge("hyphens-auto hyphens-manual") == "hyphens-manual"
    end

    test "supports gradient position utilities" do
      assert Twm.merge(
               "from-0% from-10% from-[12.5%] via-0% via-10% via-[12.5%] to-0% to-10% to-[12.5%]"
             ) == "from-[12.5%] via-[12.5%] to-[12.5%]"
    end

    test "does not conflict gradient position with gradient color" do
      assert Twm.merge("from-0% from-red") == "from-0% from-red"
    end

    test "supports list image utilities" do
      assert Twm.merge(
               "list-image-none list-image-[url(./my-image.png)] list-image-[var(--value)]"
             ) == "list-image-[var(--value)]"
    end

    test "supports caption utilities" do
      assert Twm.merge("caption-top caption-bottom") == "caption-bottom"
    end

    test "supports line clamp utilities" do
      assert Twm.merge("line-clamp-2 line-clamp-none line-clamp-[10]") == "line-clamp-[10]"
    end

    test "supports animation delay and duration utilities" do
      assert Twm.merge("delay-150 delay-0 duration-150 duration-0") == "delay-0 duration-0"
    end

    test "supports justify utilities" do
      assert Twm.merge("justify-normal justify-center justify-stretch") == "justify-stretch"
    end

    test "supports content utilities" do
      assert Twm.merge("content-normal content-center content-stretch") == "content-stretch"
    end

    test "supports whitespace utilities" do
      assert Twm.merge("whitespace-nowrap whitespace-break-spaces") == "whitespace-break-spaces"
    end
  end

  describe "Tailwind CSS v3.4 features" do
    test "supports dynamic viewport units" do
      assert Twm.merge("h-svh h-dvh w-svw w-dvw") == "h-dvh w-dvw"
    end

    test "supports has pseudo-class variants" do
      assert Twm.merge(
               "has-[[data-potato]]:p-1 has-[[data-potato]]:p-2 group-has-[:checked]:grid group-has-[:checked]:flex"
             ) == "has-[[data-potato]]:p-2 group-has-[:checked]:flex"
    end

    test "supports text wrap utilities" do
      assert Twm.merge("text-wrap text-pretty") == "text-pretty"
    end

    test "supports size utilities" do
      assert Twm.merge("w-5 h-3 size-10 w-12") == "size-10 w-12"
    end

    test "supports subgrid utilities" do
      assert Twm.merge("grid-cols-2 grid-cols-subgrid grid-rows-5 grid-rows-subgrid") ==
               "grid-cols-subgrid grid-rows-subgrid"
    end

    test "supports min/max width utilities" do
      assert Twm.merge("min-w-0 min-w-50 min-w-px max-w-0 max-w-50 max-w-px") ==
               "min-w-px max-w-px"
    end

    test "supports forced color adjust utilities" do
      assert Twm.merge("forced-color-adjust-none forced-color-adjust-auto") ==
               "forced-color-adjust-auto"
    end

    test "supports appearance utilities" do
      assert Twm.merge("appearance-none appearance-auto") == "appearance-auto"
    end

    test "supports float and clear logical properties" do
      assert Twm.merge("float-start float-end clear-start clear-end") == "float-end clear-end"
    end

    test "supports universal selector utilities" do
      assert Twm.merge("*:p-10 *:p-20 hover:*:p-10 hover:*:p-20") == "*:p-20 hover:*:p-20"
    end
  end

  describe "Tailwind CSS v4.0 features" do
    test "supports 3D transform utilities" do
      assert Twm.merge("transform-3d transform-flat") == "transform-flat"
    end

    test "supports individual rotation utilities" do
      assert Twm.merge("rotate-12 rotate-x-2 rotate-none rotate-y-3") ==
               "rotate-x-2 rotate-none rotate-y-3"
    end

    test "supports perspective utilities" do
      assert Twm.merge("perspective-dramatic perspective-none perspective-midrange") ==
               "perspective-midrange"
    end

    test "supports perspective origin utilities" do
      assert Twm.merge("perspective-origin-center perspective-origin-top-left") ==
               "perspective-origin-top-left"
    end

    test "supports linear gradient utilities" do
      assert Twm.merge("bg-linear-to-r bg-linear-45") == "bg-linear-45"
    end

    test "supports gradient background utilities" do
      assert Twm.merge("bg-linear-to-r bg-radial-[something] bg-conic-10") == "bg-conic-10"
    end

    test "supports inset ring utilities" do
      assert Twm.merge("ring-4 ring-orange inset-ring inset-ring-3 inset-ring-blue") ==
               "ring-4 ring-orange inset-ring-3 inset-ring-blue"
    end

    test "supports field sizing utilities" do
      assert Twm.merge("field-sizing-content field-sizing-fixed") == "field-sizing-fixed"
    end

    test "supports color scheme utilities" do
      assert Twm.merge("scheme-normal scheme-dark") == "scheme-dark"
    end

    test "supports font stretch utilities" do
      assert Twm.merge("font-stretch-expanded font-stretch-[66.66%] font-stretch-50%") ==
               "font-stretch-50%"
    end

    test "supports grid span utilities" do
      assert Twm.merge("col-span-full col-2 row-span-3 row-4") == "col-2 row-4"
    end

    test "supports CSS variable gradient utilities" do
      assert Twm.merge("via-red-500 via-(--mobile-header-gradient)") ==
               "via-(--mobile-header-gradient)"
    end

    test "supports typed CSS variable gradient utilities" do
      assert Twm.merge("via-red-500 via-(length:--mobile-header-gradient)") ==
               "via-red-500 via-(length:--mobile-header-gradient)"
    end
  end

  describe "Tailwind CSS v4.1 features" do
    test "supports baseline alignment utilities" do
      assert Twm.merge("items-baseline items-baseline-last") == "items-baseline-last"
      assert Twm.merge("self-baseline self-baseline-last") == "self-baseline-last"
    end

    test "supports safe alignment utilities" do
      assert Twm.merge("place-content-center place-content-end-safe place-content-center-safe") ==
               "place-content-center-safe"

      assert Twm.merge("items-center-safe items-baseline items-end-safe") == "items-end-safe"
    end

    test "supports text wrapping utilities" do
      assert Twm.merge("wrap-break-word wrap-normal wrap-anywhere") == "wrap-anywhere"
    end

    test "supports text shadow utilities" do
      assert Twm.merge("text-shadow-none text-shadow-2xl") == "text-shadow-2xl"
    end

    test "supports text shadow with colors and box shadow" do
      assert Twm.merge(
               "text-shadow-none text-shadow-md text-shadow-red text-shadow-red-500 shadow-red shadow-3xs"
             ) == "text-shadow-md text-shadow-red-500 shadow-red shadow-3xs"
    end

    test "supports mask composite utilities" do
      assert Twm.merge("mask-add mask-subtract") == "mask-subtract"
    end

    test "supports complex mask utilities" do
      assert Twm.merge(
               "mask-(--foo) mask-[foo] mask-none mask-linear-1 mask-linear-2 mask-linear-from-[position:test] mask-linear-from-3 mask-linear-to-[position:test] mask-linear-to-3 mask-linear-from-color-red mask-linear-from-color-3 mask-linear-to-color-red mask-linear-to-color-3 mask-t-from-[position:test] mask-t-from-3 mask-t-to-[position:test] mask-t-to-3 mask-t-from-color-red mask-t-from-color-3 mask-radial-(--test) mask-radial-[test] mask-radial-from-[position:test] mask-radial-from-3 mask-radial-to-[position:test] mask-radial-to-3 mask-radial-from-color-red mask-radial-from-color-3"
             ) ==
               "mask-none mask-linear-2 mask-linear-from-3 mask-linear-to-3 mask-linear-from-color-3 mask-linear-to-color-3 mask-t-from-3 mask-t-to-3 mask-t-from-color-3 mask-radial-[test] mask-radial-from-3 mask-radial-to-3 mask-radial-from-color-3"
    end

    test "supports mask position utilities" do
      assert Twm.merge(
               "mask-(--something) mask-[something] mask-top-left mask-center mask-(position:--var) mask-[position:1px_1px] mask-position-(--var) mask-position-[1px_1px]"
             ) == "mask-[something] mask-position-[1px_1px]"
    end

    test "supports mask size utilities" do
      assert Twm.merge(
               "mask-(--something) mask-[something] mask-auto mask-[size:foo] mask-(size:--foo) mask-size-[foo] mask-size-(--foo) mask-cover mask-contain"
             ) == "mask-[something] mask-contain"
    end

    test "supports mask type utilities" do
      assert Twm.merge("mask-type-luminance mask-type-alpha") == "mask-type-alpha"
    end

    test "supports shadow opacity utilities" do
      assert Twm.merge("shadow-md shadow-lg/25 text-shadow-md text-shadow-lg/25") ==
               "shadow-lg/25 text-shadow-lg/25"
    end

    test "supports drop shadow utilities" do
      assert Twm.merge(
               "drop-shadow-some-color drop-shadow-[#123456] drop-shadow-lg drop-shadow-[10px_0]"
             ) == "drop-shadow-[#123456] drop-shadow-[10px_0]"

      assert Twm.merge("drop-shadow-[#123456] drop-shadow-some-color") ==
               "drop-shadow-some-color"

      assert Twm.merge("drop-shadow-2xl drop-shadow-[shadow:foo]") == "drop-shadow-[shadow:foo]"
    end
  end

  describe "Tailwind CSS v4.1.5 features" do
    test "supports line height sizing units" do
      assert Twm.merge("h-12 h-lh") == "h-lh"
      assert Twm.merge("min-h-12 min-h-lh") == "min-h-lh"
      assert Twm.merge("max-h-12 max-h-lh") == "max-h-lh"
    end
  end
end
