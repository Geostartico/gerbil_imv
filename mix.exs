defmodule GerbileImv.MixProject do
  use Mix.Project

  def project do
    [
      app: :scenic_app,
      version: "0.1.0",
      elixir: "~> 1.9",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {GerbileImv, []},
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, git: "https://github.com/ScenicFramework/scenic.git", override: true},
      {:scenic_driver_local, git: "https://github.com/ScenicFramework/scenic_driver_local.git", override: true},
      {:scenic_clock, git: "https://github.com/ScenicFramework/scenic_clock.git", override: true},
      {:evision, git: "https://github.com/cocoa-xu/evision.git", override: true}
    ]
  end
end
