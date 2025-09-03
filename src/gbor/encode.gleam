//// Module where we can find the functions used for getting the CBOR binary representation of a value

import gleam/bit_array
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp

import ieee_float as i

import gbor as g

pub type EncodeError {
  EncodeError(String)
}

/// Encode a CBOR value to a bit array
pub fn to_bit_array(value: g.CBOR) -> Result(BitArray, EncodeError) {
  case value {
    g.CBInt(v) if v >= 0 -> uint_encode(v)
    g.CBInt(v) if v < 0 -> int_encode(v)
    g.CBInt(v) -> uint_encode(v)
    g.CBFloat(v) -> Ok(float_encode(v))
    g.CBBinary(v) -> binary_encode(BinaryEncoding(v))
    g.CBString(v) -> binary_encode(StringEncoding(v))
    g.CBArray(v) -> array_encode(v)
    g.CBMap(v) -> map_encode(v)
    g.CBBool(v) -> Ok(bool_encode(v))
    g.CBTagged(t, v) -> tagged_encode(t, v)
    g.CBNull -> Ok(null_encode())
    g.CBUndefined -> Ok(undefined_encode())
    g.CBTime(v) ->
      to_bit_array(g.CBTagged(
        0,
        g.CBString(timestamp.to_rfc3339(v, duration.hours(0))),
      ))
  }
}

fn uint_encode(value: Int) -> Result(BitArray, EncodeError) {
  case value {
    v if v < 24 -> Ok(<<0:3, v:5>>)
    // TODO verify limits
    v if v < 0x100 -> Ok(<<0:3, 24:5, v:8>>)
    v if v < 0x10000 -> Ok(<<0:3, 25:5, v:16>>)
    v if v < 0x100000000 -> Ok(<<0:3, 26:5, v:32>>)
    v if v < 0x10000000000000000 -> Ok(<<0:3, 27:5, v:64>>)
    v -> {
      let l = string.length(int.to_base16(v))
      let l = l - { l / 2 }
      case l < 0b100000 {
        True -> Ok(<<6:3, 2:5, 2:3, l:5, v:size(l)-unit(8)>>)
        False ->
          Error(EncodeError("Int value too large: " <> string.inspect(v)))
      }
    }
  }
}

fn int_encode(value: Int) -> Result(BitArray, EncodeError) {
  let value = { value * -1 } - 1
  case value {
    v if v < 24 -> Ok(<<1:3, v:5>>)
    // TODO verify limits
    v if v < 0x100 -> Ok(<<1:3, 24:5, v:8>>)
    v if v < 0x10000 -> Ok(<<1:3, 25:5, v:16>>)
    v if v < 0x100000000 -> Ok(<<1:3, 26:5, v:32>>)
    v if v < 0x10000000000000000 -> Ok(<<1:3, 27:5, v:64>>)
    v -> {
      let l = string.length(int.to_base16(v))
      let l = l - { l / 2 }
      case l < 0b100000 {
        True -> Ok(<<6:3, 3:5, 2:3, l:5, v:size(l)-unit(8)>>)
        False ->
          Error(EncodeError(
            "Absolute Int value too large: " <> string.inspect(v),
          ))
      }
    }
  }
}

fn float_encode(value: Float) -> BitArray {
  let bytes =
    value
    |> i.finite
    |> i.to_bytes_64_be

  <<7:3, 27:5, bytes:bits>>
}

type BinaryEncoding {
  BinaryEncoding(BitArray)
  StringEncoding(String)
}

fn binary_encode(value: BinaryEncoding) -> Result(BitArray, EncodeError) {
  let #(value, major) = case value {
    BinaryEncoding(v) -> {
      #(bit_array.pad_to_bytes(v), 2)
    }
    StringEncoding(v) -> #(bit_array.from_string(v), 3)
  }

  let length = bit_array.byte_size(value)

  case length {
    v if v < 24 -> Ok(<<major:3, v:5, value:bits>>)
    v if v < 0x100 -> Ok(<<major:3, 24:5, v:8, value:bits>>)
    v if v < 0x10000 -> Ok(<<major:3, 25:5, v:16, value:bits>>)
    v if v < 0x100000000 -> Ok(<<major:3, 26:5, v:32, value:bits>>)
    v if v < 0x10000000000000000 -> Ok(<<major:3, 27:5, v:64, value:bits>>)
    _ -> Error(EncodeError("Binary length too large"))
  }
}

fn array_encode(value: List(g.CBOR)) -> Result(BitArray, EncodeError) {
  let length = list.length(value)

  use data <- result.try(list.try_map(value, to_bit_array))
  let data = bit_array.concat(data)

  case length {
    v if v < 24 -> Ok(<<4:3, v:5, data:bits>>)
    v if v < 0x100 -> Ok(<<4:3, 24:5, v:8, data:bits>>)
    v if v < 0x10000 -> Ok(<<4:3, 25:5, v:16, data:bits>>)
    v if v < 0x100000000 -> Ok(<<4:3, 26:5, v:32, data:bits>>)
    v if v < 0x10000000000000000 -> Ok(<<4:3, 27:5, v:64, data:bits>>)
    _ -> Error(EncodeError("Array length too large"))
  }
}

fn bool_encode(value: Bool) -> BitArray {
  case value {
    False -> <<0xf4>>
    True -> <<0xf5>>
  }
}

fn null_encode() -> BitArray {
  <<0xf6>>
}

fn undefined_encode() -> BitArray {
  <<0xf7>>
}

fn map_encode(value: List(#(g.CBOR, g.CBOR))) -> Result(BitArray, EncodeError) {
  let n_pairs = list.length(value)

  use data <- result.try(
    list.try_fold(value, <<>>, fn(acc, a) {
      use k_data <- result.try(to_bit_array(a.0))
      use v_data <- result.try(to_bit_array(a.1))
      Ok(bit_array.concat([acc, k_data, v_data]))
    }),
  )

  case n_pairs {
    v if v < 24 -> Ok(<<5:3, v:5, data:bits>>)
    v if v < 0x100 -> Ok(<<5:3, 25:5, v:8, data:bits>>)
    v if v < 0x10000 -> Ok(<<5:3, 26:5, v:16, data:bits>>)
    v if v < 0x100000000 -> Ok(<<5:3, 27:5, v:32, data:bits>>)
    v if v < 0x10000000000000000 -> Ok(<<5:3, 28:5, v:64, data:bits>>)
    _ -> Error(EncodeError("N pairs size too large"))
  }
}

fn tagged_encode(t: Int, v: g.CBOR) -> Result(BitArray, EncodeError) {
  use bin_tag <- result.try(case t {
    t if t < 24 -> Ok(<<6:3, t:5>>)
    t if t < 0x100 -> Ok(<<6:3, 24:5, t:8>>)
    t if t < 0x10000 -> Ok(<<6:3, 25:5, t:16>>)
    t if t < 0x100000000 -> Ok(<<6:3, 26:5, t:32>>)
    t if t < 0x10000000000000000 -> Ok(<<6:3, 27:5, t:64>>)
    _ -> Error(EncodeError("Tagged tag too large"))
  })

  use bin_value <- result.try(to_bit_array(v))

  Ok(bit_array.concat([bin_tag, bin_value]))
}
