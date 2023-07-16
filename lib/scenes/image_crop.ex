defmodule GerbileImv.Scene.ImageCrop do
  use Scenic.Scene

  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Components

  alias GerbileImv.Component.CropImage

  @top_padding 40
  @button_height 40
  @button_width 100

  @impl Scenic.Scene
  def init(scene, param, _opts) do
    
    p = case param do
      %{path: pa} -> Path.expand(pa)
      _ -> raise "You must provide an image to view"
    end
    {width, height} = scene.viewport.size
    IO.puts(p)
    img = Evision.imread(p) 
          |> Evision.Mat.to_nx()
    {img_height, img_width, _} = Nx.shape(img)
    # build the graph
    graph =
      Graph.build(font: :roboto, font_size: 16)
      |> CropImage.add_to_graph(%{path: p, dim: %{max_x: img_width, max_y: img_height, min_x: 0, min_y: 0}, pin: {0,0}, width: width, height: height-@top_padding}, id: :crop_image)
      |> button("save_image", width: @button_width, height: @top_padding-2, id: :save_button, translate: {0, height-@button_height})
      |> text_field("path to saved image", id: :path_field, translate: {@button_width + 10, height-@button_height})
      |> button("back", height: @top_padding-2, id: :back_button, translate: {width - @button_width, height-@button_height})
      #|> Image.add_to_graph(%{path: "/home/geostartico/Pictures/gyro.jpg", dim: {width, height}}, id: :zoom_image)

    scene =
      scene
      |> assign(:graph, graph)
      |> assign(:img, p)
      |> push_graph(graph)

    scene = Scenic.Scene.assign(scene, :dims, %{max_x: img_width, max_y: img_height, min_x: 0, min_y: 0})
    {:ok, scene}
  end

  @impl Scenic.Scene
  def handle_input(inp, _, scene)do
    IO.inspect(inp)
    {:cont,inp, scene}
  end

  @impl Scenic.Scene
  def handle_event({:value_changed, :path_field, text}, _, scene)do
    scene = Scenic.Scene.assign(scene, :path, text)
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_event({:crop_changed, dict}, _, scene)do
    scene = Scenic.Scene.assign(scene, :dims, dict)
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_event({:click, :save_button}, _, scene)do
    case Scenic.Scene.fetch(scene, :path) do
      {:ok, text} -> 
        {:ok, dict} = Scenic.Scene.fetch(scene, :dims)
        {:ok, img} = Scenic.Scene.fetch(scene, :img)
        IO.puts(img)
        [_ | p] = String.split(img, "/") 
        IO.inspect(p)
        p = Enum.take(p, length(p)-1) |> Enum.reduce("", fn x, acc -> acc<>"/"<>x end)
        IO.puts(p)
        p = p <> "/#{text}"
        IO.puts(p)
        :ok = saveimg(scene, Path.expand(p), dict)
      _ -> IO.puts("give a path")
    end
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_event({:click, :back_button}, _, scene)do
    {:ok, p} = fetch(scene, :img)
    Scenic.ViewPort.set_root(scene.viewport, GerbileImv.Scene.ImageZoom, %{path: p})
  end

  @impl Scenic.Scene
  def handle_event(inp, _, scene)do
    IO.inspect(inp)
    {:noreply, scene}
  end

  defp saveimg(scene, name, dim = %{min_x: min_x, max_x: max_x, min_y: min_y, max_y: max_y}) 
  when is_binary(name) do
    IO.inspect({dim,name})
    {:ok, path} = fetch(scene, :img)
    img  = Evision.imread(path)
    IO.inspect(img)
    img = Evision.Mat.roi(img, {trunc(min_x), trunc(min_y), trunc(max_x) - trunc(min_x),trunc(max_y) -trunc(min_y)})
    IO.inspect(img)
    case Evision.imwrite(name, img) do
      {:error, _} -> :error
      true -> :ok
      false -> :error
    end
  end


end
