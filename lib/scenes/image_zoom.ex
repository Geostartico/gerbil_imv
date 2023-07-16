defmodule GerbileImv.Scene.ImageZoom do
  use Scenic.Scene

  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Components

  alias GerbileImv.Component.Image
  @button_width 30
  @impl Scenic.Scene
  def init(scene, param, _opts) do
    %{path: p} = param
    IO.puts(p)
    {width, height} = scene.viewport.size
    IO.inspect({width, height})

    # build the graph
    graph =
      Graph.build(font: :roboto, font_size: 16)
      |> Image.add_to_graph(%{path: p, dim: {width, height}}, id: :zoom_image)
      |> button("crop", translate: {20, 5}, id: :crop_image)
      |> button("back", id: :back_button, translate: {width - @button_width, 0})
      #|> Image.add_to_graph(%{path: "/home/geostartico/Pictures/gyro.jpg", dim: {width, height}}, id: :zoom_image)

    scene =
      scene
      |> assign(:graph, graph)
      |> assign(:img, p)
      |> push_graph(graph)

    {:ok, scene}
  end
  @impl Scenic.Scene
  def handle_input(inp, _, scene) do
    IO.inspect(inp)
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_event({:click, :crop_image}, _, scene) do
    {:ok, p} = fetch(scene, :img)
    Scenic.ViewPort.set_root(scene.viewport, GerbileImv.Scene.ImageCrop, %{path: p})
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_event({:click, :back_button}, _, scene)do
    {:ok, p} = fetch(scene, :img)
    if(Scenic.Assets.Stream.exists?("loaded_image")) do
      :ok = Scenic.Assets.Stream.delete("loaded_image")
      IO.puts("deleting #{Scenic.Assets.Stream.exists?("loaded_image")}")
    end
    Scenic.ViewPort.set_root(scene.viewport, GerbileImv.Scene.DirTree, %{path: Path.dirname(p)})
  end

end
