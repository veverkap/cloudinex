use ExGuard.Config

"unit-test"
|> guard()
|> command("mix test --color")
|> watch(~r{\.(erl|ex|exs|eex|xrl|yrl)\z}i)
|> notification(:auto)

"coveralls"
|> guard()
|> command("mix coveralls.html")
|> watch(~r{\.(erl|ex|exs|eex|xrl|yrl)\z}i)
|> notification(:auto)

"credo"
|> guard()
|> command("mix credo --strict")
|> watch(~r{\.(erl|ex|exs|eex|xrl|yrl)\z}i)
|> notification(:auto)

"docs"
|> guard()
|> command("mix docs")
|> watch(~r{\.(erl|ex|exs|eex|xrl|yrl)\z}i)
|> notification(:auto)
