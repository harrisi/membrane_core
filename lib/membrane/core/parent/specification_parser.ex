defmodule Membrane.Core.Parent.SpecificationParser do
  @moduledoc false
  use Bunch

  alias Membrane.Core.Parent.Link
  alias Membrane.Core.Parent.Link.Endpoint
  alias Membrane.{ChildrenSpec, Element, Pad, ParentError}

  require Membrane.Logger

  @type raw_link_t :: %Link{from: raw_endpoint_t(), to: raw_endpoint_t()}

  @type raw_endpoint_t :: %Endpoint{
          child: Element.name_t() | {Membrane.Bin, :itself},
          pad_spec: Pad.name_t() | Pad.ref_t(),
          pad_ref: Pad.ref_t() | nil,
          pid: pid() | nil,
          pad_props: map()
        }

  @spec parse([ChildrenSpec.builder_t()]) ::
          {[ChildrenSpec.Builder.child_spec_t()], [raw_link_t]} | no_return
  def parse(specifications) when is_list(specifications) do
    {children, links} =
      specifications
      |> List.flatten()
      |> Enum.map(fn
        %ChildrenSpec.Builder{links: links, children: children, status: :done} = builder ->
          if links == [] and children == [] do
            Membrane.Logger.warn(
              "The specification you have passed: #{builder} has no effect - it doesn't produce any children nor links."
            )
          end

          {Enum.reverse(children), Enum.reverse(links)}

        _other ->
          from_spec_error(specifications)
      end)
      |> Enum.unzip()

    links =
      links
      |> List.flatten()
      |> Enum.filter(fn link -> Map.has_key?(link, :from_pad) end)
      |> Enum.map(fn %{} = link ->
        %Link{
          id: make_ref(),
          from: %Endpoint{
            child: link.from,
            pad_spec: link.from_pad,
            pad_props: link.from_pad_props
          },
          to: %Endpoint{
            child: link.to,
            pad_spec: link.to_pad,
            pad_props: link.to_pad_props
          }
        }
      end)

    children = children |> List.flatten()
    {children, links}
  end

  def parse(specification), do: from_spec_error([specification])

  @spec from_spec_error([ChildrenSpec.builder_t()]) :: no_return
  defp from_spec_error(specifications) do
    raise ParentError, """
    Invalid specifications: #{inspect(specifications)}. The link lacks it destination.
    See `#{inspect(ChildrenSpec)}` for information on how to specify children and links
    beween them.
    """
  end
end