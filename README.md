# Cloudinex
[![CircleCI](https://circleci.com/gh/veverkap/cloudinex/tree/master.svg?style=svg&circle-token=e6113d078cbf6f2a86aeb9b540f52d6fd9b2df04)](https://circleci.com/gh/veverkap/cloudinex/tree/master)
[![Build Status](https://travis-ci.org/veverkap/cloudinex.svg?branch=master)](https://travis-ci.org/veverkap/cloudinex)
[![Hex.pm](https://img.shields.io/hexpm/v/cloudinex.svg)](http://hex.pm/packages/cloudinex)
[ ![Codeship Status for veverkap/cloudinex](https://app.codeship.com/projects/92f66fd0-676b-0135-d1a2-52d2c2f6a252/status?branch=master)](https://app.codeship.com/projects/241057)
[![Coverage Status](https://coveralls.io/repos/github/veverkap/cloudinex/badge.svg?branch=master)](https://coveralls.io/github/veverkap/cloudinex?branch=master)
[![Inline docs](http://inch-ci.org/github/veverkap/cloudinex.svg)](http://inch-ci.org/github/veverkap/cloudinex)
[![Ebert](https://ebertapp.io/github/veverkap/cloudinex.svg)](https://ebertapp.io/github/veverkap/cloudinex)


## Description
Cloudinex is an Elixir wrapper around the Cloudinary API.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cloudinex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:cloudinex, "~> 0.2.1"}]
end
```

## Configuration

Authentication is done using Basic Authentication over secure HTTP. Your
Cloudinary API Key and API Secret are used for the authentication and can be
found [here](https://cloudinary.com/console).  Configuration
is handled via application variables:

```elixir
config :cloudinex,
      debug: false, #optional
      base_url: "https://api.cloudinary.com/v1_1/",
      api_key: "YOUR_API_KEY",
      secret: "YOUR_API_SECRET",
      cloud_name: "YOUR_CLOUD_NAME"
```
