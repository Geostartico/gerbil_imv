defmodule GerbileImv.Scene.ImageCrop do
  use Scenic.Scene

  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Components

  alias GerbileImv.Component.CropImage

  @impl Scenic.Scene
  def init(scene, param, _opts) do
    p = "/home/geostartico/Pictures/gyro.jpg"
    {width, height} = scene.viewport.size

    img = Evision.imread(p) 
          |> Evision.Mat.to_nx()
    {img_height, img_width, _} = Nx.shape(img)
    # build the graph
    graph =
      Graph.build(font: :roboto, font_size: 16)
      |> CropImage.add_to_graph(%{path: p, dim: %{max_x: img_width, max_y: img_height, min_x: 0, min_y: 0}, pin: {0,0}}, id: :crop_image)
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
