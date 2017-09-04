defmodule Cloudinex.UrlTest do
  @moduledoc false
  use ExUnit.Case

  setup do
    bypass = Bypass.open

    Application.put_env(
      :cloudinex,
      :base_image_url, "//res.cloudinary.com/")

    Application.put_env(
      :cloudinex,
      :secret, "secret")

    Application.put_env(
      :cloudinex,
      :cloud_name, "demo")

    {:ok, %{bypass: bypass}}
  end

  describe "tests" do
    test "default" do
      expected = "//res.cloudinary.com/demo/image/upload/public_id"
      assert expected == Cloudinex.Url.for("public_id")
    end

    test "include signature" do
      expected = "//res.cloudinary.com/demo/image/upload/s--kVUvyZyp--/public_id"
      assert expected == Cloudinex.Url.for("public_id", %{sign_url: true})
    end

    test "include width and height" do
      expected = "//res.cloudinary.com/demo/image/upload/h_300,w_400/public_id"
      assert expected == Cloudinex.Url.for("public_id", %{width: 400, height: 300})
    end

    test "handles multiple options" do
      expected = "//res.cloudinary.com/demo/image/upload/s--cvhISy3m--/c_fill,f_auto,fl_progressive,h_254,q_jpegmini,w_300/public_id"
      assert expected == Cloudinex.Url.for("public_id", %{crop: "fill", fetch_format: 'auto', flags: 'progressive', width: 300, height: 254, quality: "jpegmini", sign_url: true})
    end

    test "handles version" do
      expected = "//res.cloudinary.com/demo/image/upload/v1471959066/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{version: 1471959066})
    end

    test "handles resource type" do
      expected = "//res.cloudinary.com/demo/video/upload/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{resource_type: "video"})
    end

    test "handles file extension" do
      expected = "//res.cloudinary.com/demo/image/upload/a_public_id.png"
      assert expected == Cloudinex.Url.for("a_public_id", %{format: "png"})
    end

    test "handles options as a list" do
      expected = "//res.cloudinary.com/demo/image/upload/bo_5px_solid_rgb:c22c33,c_fill,h_246,q_80,r_5,w_470/c_scale,g_south_east,l_my_overlay,w_128,x_5,y_15/a_public_id"

      result = Cloudinex.Url.for("a_public_id", [
         %{border: "5px_solid_rgb:c22c33", radius: 5, crop: "fill", height: 246, width: 470, quality: 80},
         %{overlay: "my_overlay", crop: "scale", gravity: "south_east", width: 128 ,x: 5, y: 15}
      ])
      assert expected == result
    end
  end

  describe "individual options" do
    test "aspect_ratio" do
      expected = "//res.cloudinary.com/demo/image/upload/ar_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{aspect_ratio: "100"})
    end
    test "border" do
      expected = "//res.cloudinary.com/demo/image/upload/bo_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{border: "100"})
    end
    test "color" do
      expected = "//res.cloudinary.com/demo/image/upload/c_ccccccc/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{color: "ccccccc"})
    end
    test "coulor" do
      expected = "//res.cloudinary.com/demo/image/upload/c_cccccc/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{coulor: "cccccc"})
    end
    test "crop" do
      expected = "//res.cloudinary.com/demo/image/upload/c_100x43/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{crop: "100x43"})
    end
    test "default_image" do
      expected = "//res.cloudinary.com/demo/image/upload/d_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{default_image: "100"})
    end
    test "delay" do
      expected = "//res.cloudinary.com/demo/image/upload/dl_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{delay: "100"})
    end
    test "density" do
      expected = "//res.cloudinary.com/demo/image/upload/dn_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{density: "100"})
    end
    test "dpr" do
      expected = "//res.cloudinary.com/demo/image/upload/dpr_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{dpr: "100"})
    end
    test "effect" do
      expected = "//res.cloudinary.com/demo/image/upload/e_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{effect: "100"})
    end
    test "face" do
      expected = "//res.cloudinary.com/demo/image/upload/g_face/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{face: true})
    end
    test "fetch_format" do
      expected = "//res.cloudinary.com/demo/image/upload/f_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{fetch_format: "100"})
    end
    test "flags" do
      expected = "//res.cloudinary.com/demo/image/upload/fl_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{flags: "100"})
    end
    test "gravity" do
      expected = "//res.cloudinary.com/demo/image/upload/g_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{gravity: "100"})
    end
    test "height" do
      expected = "//res.cloudinary.com/demo/image/upload/h_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{height: "100"})
    end
    test "opacity" do
      expected = "//res.cloudinary.com/demo/image/upload/o_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{opacity: "100"})
    end
    test "overlay" do
      expected = "//res.cloudinary.com/demo/image/upload/l_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{overlay: "100"})
    end
    test "quality" do
      expected = "//res.cloudinary.com/demo/image/upload/q_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{quality: "100"})
    end
    test "radius" do
      expected = "//res.cloudinary.com/demo/image/upload/r_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{radius: "100"})
    end
    test "transformation" do
      expected = "//res.cloudinary.com/demo/image/upload/t_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{transformation: "100"})
    end
    test "underlay" do
      expected = "//res.cloudinary.com/demo/image/upload/u_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{underlay: "100"})
    end
    test "width" do
      expected = "//res.cloudinary.com/demo/image/upload/w_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{width: "100"})
    end
    test "x" do
      expected = "//res.cloudinary.com/demo/image/upload/x_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{x: "100"})
    end
    test "y" do
      expected = "//res.cloudinary.com/demo/image/upload/y_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{y: "100"})
    end
    test "zoom" do
      expected = "//res.cloudinary.com/demo/image/upload/z_100/a_public_id"
      assert expected == Cloudinex.Url.for("a_public_id", %{zoom: "100"})
    end
  end
end
