defmodule Cloudinex.Mixfile do
  use Mix.Project

  def project do
    [app: :cloudinex,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:hackney, "~> 1.9", override: true},
      {:httpoison, "~> 0.11.0"},
      {:poison, ">= 1.0.0"},
      {:tesla, github: "veverkap/tesla"},

      {:bypass, "~> 0.8", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:ex_guard, "~> 1.2", only: :dev},
      {:plug, "~> 1.4", only: [:dev, :test]}
    ]
  end
end
