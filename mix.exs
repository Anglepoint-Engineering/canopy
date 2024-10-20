defmodule Canopy.MixProject do
  use Mix.Project

  def project do
    [
      app: :canopy,
      version: "0.2.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: [
        {:ex_doc, "~> 0.28", only: :dev, runtime: false}
      ],
      package: [
        description: "Elixir umbrella test coverage tool, with cross app stats.",
        maintainers: ["Thomas Silva"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/Anglepoint-Engineering/canopy"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :tools, :inets, :ssl]
    ]
  end
end
