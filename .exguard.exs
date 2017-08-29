use ExGuard.Config

guard("unit-test")
|> command("mix test --color")
|> watch(~r{\.(erl|ex|exs|eex|xrl|yrl)\z}i)
|> notification(:auto)

guard("coveralls")
|> command("mix coveralls.html")
|> watch(~r{\.(erl|ex|exs|eex|xrl|yrl)\z}i)
|> notification(:auto)

guard("credo")
|> command("mix credo --strict")
|> watch(~r{\.(erl|ex|exs|eex|xrl|yrl)\z}i)
|> notification(:auto)

guard("docs")
|> command("mix docs")
|> watch(~r{\.(erl|ex|exs|eex|xrl|yrl)\z}i)
|> notification(:auto)
