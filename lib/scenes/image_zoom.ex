defmodule GerbileImv.Scene.ImageZoom do
  use Scenic.Scene

  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Components

  alias GerbileImv.Component.Image

  @impl Scenic.Scene
  def init(scene, param, _opts) do
    %{path: p} = param
    {width, height} = scene.viewport.size
    IO.inspect({width, height})

    # build the graph
    graph =
      Graph.build(font: :roboto, font_size: 16)
      |> Image.add_to_graph(%{path: p, dim: {width, height}}, id: :zoom_image)
      #|> Image.add_to_graph(%{path: "/home/geostartico/Pictures/gyro.jpg", dim: {width, height}}, id: :zoom_image)

    scene =
      scene
      |> assign(:graph, graph)
      |> push_graph(graph)

    {:ok, scene}
  end
  @impl Scenic.Scene
  def handle_input(inp, _, scene)do
    IO.inspect(inp)
    {:noreply, scene}
  end


end
