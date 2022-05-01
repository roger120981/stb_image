defmodule StbImageTest do
  use ExUnit.Case, async: true

  doctest StbImage

  test "decode png from file" do
    {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.png"))
    assert img.type == :u8
    assert img.shape == {2, 3, 4}

    assert img.data ==
             <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>>

    assert StbImage.new(img.data, img.shape) == img
    assert img |> StbImage.to_nx() |> tap(fn %Nx.Tensor{} -> :ok end) |> StbImage.from_nx() == img
  end

  test "decode jpg from file" do
    {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.jpg"))
    assert img.type == :u8
    assert img.shape == {2, 3, 3}

    assert img.data ==
             <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
               124>>

    assert StbImage.new(img.data, img.shape) == img
    assert img |> StbImage.to_nx() |> tap(fn %Nx.Tensor{} -> :ok end) |> StbImage.from_nx() == img
  end

  test "decode hdr from file" do
    {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.hdr"))
    assert img.type == :f32
    assert img.shape == {384, 768, 3}
    assert is_binary(img.data)
    assert StbImage.new(img.data, img.shape, type: :f32) == img
    assert img |> StbImage.to_nx() |> tap(fn %Nx.Tensor{} -> :ok end) |> StbImage.from_nx() == img
  end

  test "decode png from memory" do
    {:ok, binary} = File.read(Path.join(__DIR__, "test.png"))
    {:ok, img} = StbImage.from_binary(binary)
    assert img.type == :u8
    assert img.shape == {2, 3, 4}

    assert img.data ==
             <<241, 145, 126, 255, 136, 190, 78, 255, 68, 122, 183, 255, 244, 196, 187, 255, 190,
               205, 145, 255, 144, 184, 200, 255>>

    assert StbImage.new(img.data, img.shape) == img
    assert img |> StbImage.to_nx() |> tap(fn %Nx.Tensor{} -> :ok end) |> StbImage.from_nx() == img
  end

  test "decode jpg from memory" do
    {:ok, binary} = File.read(Path.join(__DIR__, "test.jpg"))
    {:ok, img} = StbImage.from_binary(binary)
    assert img.type == :u8
    assert img.shape == {2, 3, 3}

    assert img.data ==
             <<180, 128, 70, 148, 128, 78, 89, 134, 101, 222, 170, 112, 182, 162, 112, 112, 157,
               124>>

    assert StbImage.new(img.data, img.shape) == img
    assert img |> StbImage.to_nx() |> tap(fn %Nx.Tensor{} -> :ok end) |> StbImage.from_nx() == img
  end

  test "decode hdr from memory" do
    {:ok, binary} = File.read(Path.join(__DIR__, "test.hdr"))
    {:ok, img} = StbImage.from_binary(binary)
    assert img.type == :f32
    assert img.shape == {384, 768, 3}
    assert is_binary(img.data)
    assert StbImage.new(img.data, img.shape, type: :f32) == img
    assert img |> StbImage.to_nx() |> tap(fn %Nx.Tensor{} -> :ok end) |> StbImage.from_nx() == img
  end

  test "decode gif" do
    {:ok, frames, delays} = StbImage.gif_from_file(Path.join(__DIR__, "test.gif"))
    frame = Enum.at(frames, 0)
    assert frame.shape == {2, 3, 3}
    assert 2 == Enum.count(frames)
    assert delays == [200, 200]

    assert [Enum.at(frames, 0).data, Enum.at(frames, 1).data] ==
             [<<180, 128, 70, 255, 171, 119>>, <<61, 255, 65, 143, 117, 255>>]
  end

  for ext <- ~w(bmp png tga jpg hdr)a do
    @ext ext

    test "decode #{@ext} from file matches decode from binary" do
      {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.#{@ext}"))
      assert StbImage.from_binary(File.read!(Path.join(__DIR__, "test.#{@ext}"))) == {:ok, img}
    end

    test "decode #{@ext} from file and save to file" do
      {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.#{@ext}"))
      save_at = "tmp/save_test.#{@ext}"

      try do
        File.mkdir_p!("tmp")
        :ok = StbImage.to_file(img, save_at)
        assert StbImage.from_file(save_at) == {:ok, img}
      after
        File.rm!(save_at)
      end
    end

    test "decode #{@ext} from file and encode to binary" do
      {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.#{@ext}"))

      {:ok, encoded} = StbImage.to_binary(img, @ext)
      assert StbImage.from_binary(encoded) == {:ok, img}
    end
  end

  test "resize png" do
    {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.png"))
    {:ok, resized_img} = StbImage.resize(img, 4, 6)
    assert resized_img.shape == {4, 6, 4}
    assert resized_img.type == img.type
  end

  test "resize jpg" do
    {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.jpg"))
    {:ok, resized_img} = StbImage.resize(img, 4, 6)
    assert resized_img.shape == {4, 6, 3}
    assert resized_img.type == img.type
  end

  test "resize hdr" do
    {:ok, img} = StbImage.from_file(Path.join(__DIR__, "test.hdr"))
    {:ok, resized_img} = StbImage.resize(img, 192, 384)
    assert resized_img.shape == {192, 384, 3}
    assert resized_img.type == img.type
  end
end
