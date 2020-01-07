defmodule Zappa.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :zappa,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      source_url: "https://github.com/fireproofsocks/zappa",
      docs: [
        source_ref: "v#{@version}",
        main: "getting_started",
        logo: "logo.png",
        #        extra_section: "GUIDES",
        #        assets: "guides/assets",
        #        formatters: ["html", "epub"],
        #        groups_for_modules: groups_for_modules(),
        extras: extras()
        #        groups_for_extras: groups_for_extras()
      ],
      package: package()
    ]
  end

  def extras do
    [
      "docs/overview.md",
      "docs/getting_started.md",
      "docs/helpers.md",
      "docs/block-helpers.md",
      "docs/registering_helpers.md"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:html_entities, "~> 0.5.0", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21.2", only: :dev, runtime: false},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      lint: ["format --check-formatted", "credo --strict"]
    ]
  end

  defp package do
    [
      description: "Handlebars templates for Elixir",
      files: [
        "lib",
        "priv",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        ".formatter.exs"
      ],
      maintainers: [
        "Everett Griffiths",
        "Utility Muffin Research Kitchen"
      ],
      licenses: ["MIT"],
      links: %{
        Website: "https://github.com/fireproofsocks/zappa",
        Changelog: "https://github.com/fireproofsocks/zappa/blob/master/CHANGELOG.md",
        GitHub: "https://github.com/fireproofsocks/zappa"
      }
    ]
  end
end
