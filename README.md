# Cloudinex
[![CircleCI](https://circleci.com/gh/veverkap/cloudinex/tree/master.svg?style=svg&circle-token=e6113d078cbf6f2a86aeb9b540f52d6fd9b2df04)](https://circleci.com/gh/veverkap/cloudinex/tree/master)
[![Build Status](https://travis-ci.org/veverkap/cloudinex.svg?branch=master)](https://travis-ci.org/veverkap/cloudinex)
[![Hex.pm](https://img.shields.io/hexpm/v/cloudinex.svg)](http://hex.pm/packages/cloudinex)
[ ![Codeship Status for veverkap/cloudinex](https://app.codeship.com/projects/92f66fd0-676b-0135-d1a2-52d2c2f6a252/status?branch=master)](https://app.codeship.com/projects/241057)
[![Coverage Status](https://coveralls.io/repos/github/veverkap/cloudinex/badge.svg?branch=master)](https://coveralls.io/github/veverkap/cloudinex?branch=master)
[![Inline docs](http://inch-ci.org/github/veverkap/cloudinex.svg)](http://inch-ci.org/github/veverkap/cloudinex)
[![Ebert](https://ebertapp.io/github/veverkap/cloudinex.svg)](https://ebertapp.io/github/veverkap/cloudinex)


## Description
Cloudinex is an Elixir wrapper around the [Cloudinary](http://cloudinary.com) [Image Upload API](http://cloudinary.com/documentation/image_upload_api_reference) and [Admin API](http://cloudinary.com/documentation/admin_api).  Most of the methods in the APIs have been implemented in this library.

## Uploading Images

### From URL
To upload an image url:

```elixir
iex> Cloudinex.Uploader.upload_url("http://example.com/example.jpg")
{:ok,
  %{"bytes" => 228821,
    "created_at" => "2017-09-03T20:43:45Z",
    "etag" => "96703c568b938567551bf0e408ab2f2a",
    "format" => "jpg",
    "height" => 2048,
    "original_filename" => "02qqN5T",
    "public_id" => "i5duxjofpqcdprjl0gag",
    "resource_type" => "image",
    "secure_url" => "https://res.cloudinary.com/demo/image/upload/v1504471425/i5duxjofpqcdprjl0gag.jpg",
    "signature" => "5f0475dfb785049d97f937071802ee88cc153ed0",
    "tags" => [],
    "type" => "upload",
    "url" => "http://res.cloudinary.com/demo/image/upload/v1504471425/i5duxjofpqcdprjl0gag.jpg",
    "version" => 1504471425,
    "width" => 2048}}
```
### From local file

```elixir
iex> Cloudinex.Uploader.upload_file("./path/to/file.jpg")
{:ok,
  %{"bytes" => 228821,
    "created_at" => "2017-09-03T20:43:45Z",
    "etag" => "96703c568b938567551bf0e408ab2f2a",
    "format" => "jpg",
    "height" => 2048,
    "original_filename" => "02qqN5T",
    "public_id" => "i5duxjofpqcdprjl0gag",
    "resource_type" => "image",
    "secure_url" => "https://res.cloudinary.com/demo/image/upload/v1504471425/i5duxjofpqcdprjl0gag.jpg",
    "signature" => "5f0475dfb785049d97f937071802ee88cc153ed0",
    "tags" => [],
    "type" => "upload",
    "url" => "http://res.cloudinary.com/demo/image/upload/v1504471425/i5duxjofpqcdprjl0gag.jpg",
    "version" => 1504471425,
    "width" => 2048}}
```
## Display Manipulated Images

* A url to the image at its original dimensions and no transformations

```elixir
iex> Cloudinex.Url.for("a_public_id")
"//res.cloudinary.com/my_cloud_name/image/upload/a_public_id"
```

* A url to the image adjusted to a specific width and height

```elixir
iex> Cloudinex.Url.for("a_public_id", %{width: 400, height: 300})
"//res.cloudinary.com/my_cloud_name/image/upload/h_300,w_400/a_public_id"
```

* A url to the image using multiple transformation options and a signature

```elixir
iex> Cloudinex.Url.for("a_public_id", %{crop: "fill", fetch_format: 'auto', flags: 'progressive', width: 300, height: 254, quality: "jpegmini", sign_url: true})
"//res.cloudinary.com/my_cloud_name/image/upload/s--jwB_Ds4w--/c_fill,f_auto,fl_progressive,h_254,q_jpegmini,w_300/a_public_id"
```

 * A url to a specific version of the image

```elixir
iex> Cloudinex.Url.for("a_public_id", %{version: 1471959066})
"//res.cloudinary.com/my_cloud_name/image/upload/v1471959066/a_public_id"
```

* A url to a specific version of the image adjusted to a specific width and height

```elixir
iex> Cloudinex.Url.for("a_public_id", %{width: 400, height: 300, version: 1471959066})
"//res.cloudinary.com/my_cloud_name/image/upload/h_300,w_400/v1471959066/a_public_id"
```

## Installation

The package can be installed
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
is handled via application variables (showing default values):

```elixir
config :cloudinex,
        debug: false,
        base_url: "https://api.cloudinary.com/v1_1/",
        base_image_url: "https://res.cloudinary.com/",
        api_key: "YOUR_API_KEY", #no default
        secret: "YOUR_API_SECRET", #no default
        cloud_name: "YOUR_CLOUD_NAME", #no default  
```
