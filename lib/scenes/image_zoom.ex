defmodule GerbileImv.Scene.ImageZoom do
  use Scenic.Scene

  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Components

  alias GerbileImv.Component.Image

  @impl Scenic.Scene
  def init(scene, _param, _opts) do
    {width, height} = scene.viewport.size
    IO.inspect({width, height})
    col = width / 6

    # build the graph
    graph =
      Graph.build(font: :roboto, font_size: 16)
      |> Image.add_to_graph(%{path: "/home/geostartico/Pictures/gyro.jpg", dim: {width, height}}, id: :zoom_image)

    scene =
      scene
      |> assign(:graph, graph)
      |> push_graph(graph)

    {:ok, scene}
  end

end
