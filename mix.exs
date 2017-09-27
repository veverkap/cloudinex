defmodule Cloudinex.Mixfile do
  use Mix.Project

  @version "0.3.2"

  def project do
    [app: :cloudinex,
     version: @version,
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     name: "cloudinex",
     source_url: "https://github.com/veverkap/cloudinex",
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
     deps: deps(Mix.env),
     description: description(),
     package: package()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
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
      {:poison, ">= 1.0.0"},
      {:tesla, "~> 0.8"},

      {:bypass, "~> 0.8", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:excoveralls, "~> 0.7", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:ex_guard, "~> 1.3", only: :dev},
      {:plug, "~> 1.4", only: [:dev, :test]},
    ]
  end

  defp deps(_), do: deps()

  defp description do
    """
    Cloudinex is an Elixir library for the Cloudinary API
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :cloudinex,
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Patrick Veverka"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/veverkap/cloudinex"}
    ]
  end
end
