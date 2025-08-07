# gbor

[![Package Version](https://img.shields.io/hexpm/v/gbor)](https://hex.pm/packages/gbor)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gbor/)

A CBOR encoding/decoding library for Gleam.

# Specification Support

This library aims to support the majority of the CBOR specification (RFC 8949). The following table details the level of support for each major feature:

| Feature | Supported | Notes |
| :--- | :---: | :--- |
| Integers | ✅ | Covers both positive (major type 0) and negative (major type 1) integers. |
| Byte Strings | ✅ | Definite-length only (major type 2). |
| Text Strings | ✅ | Definite-length only (major type 3). |
| Arrays | ✅ | Definite-length only (major type 4). |
| Maps | ✅ | Definite-length only (major type 5). |
| Tags | ✅ | (major type 6). |
| Simple Values & Floats | ✅ | Covers simple values, booleans, null, undefined, and floating-point numbers (major type 7). |
| Indefinite-length Items | ❌ | Not supported for strings, byte strings, arrays, or maps. |

# Installation
```sh
gleam add gbor@1
```

# Usage
Please check out the encode/decode tests.

## Encode
```gleam
import gbor as g
import gbor/encode

import gleam/list

type Cat {
  Cat(name: String, lives: Int, nicknames: List(String))
}

fn cat_encoder(cat: Cat) -> Result(BitArray, encode.EncodeError) {
  g.CBMap([
    #(g.CBString("name"), g.CBString(cat.name)),
    #(g.CBString("lives"), g.CBInt(cat.lives)),
    #(g.CBString("nicknames"), g.CBArray(list.map(cat.nicknames, g.CBString))),
  ])
  |> encode.to_bit_array
}

pub fn main() {
  let assert Ok(bin) =
    Cat("Fluffy", 9, ["Fluff", "Fluffers"])
    |> cat_encoder
}
```

## Decode
```gleam
import gbor/decode as gbor_decode
import gleam/bit_array
import gleam/dynamic/decode as gdd

pub type Cat {
  Cat(name: String, lives: Int, nicknames: List(String))
}

fn decode_cat(data: BitArray) -> Result(Cat, List(gdd.DecodeError)) {
  let cat_decoder = {
    use name <- gdd.field("name", gdd.string)
    use lives <- gdd.field("lives", gdd.int)
    use nicknames <- gdd.field("nicknames", gdd.list(gdd.string))
    gdd.success(Cat(name:, lives:, nicknames:))
  }

  let assert Ok(cbor) = gbor_decode.from_bit_array(data)

  gdd.run(gbor_decode.cbor_to_dynamic(cbor), cat_decoder)
}

pub fn main() {
  let assert Ok(bin_cat) =
    bit_array.base64_decode(
      "o2RuYW1lZEx1Y3llbGl2ZXMIaW5pY2tuYW1lc4JqTHVja3kgTHVjeWNMdWM=",
    )
  assert Ok(Cat("Lucy", 8, ["Lucky Lucy", "Luc"])) == decode_cat(bin_cat)
}
```

## Development

```sh
gleam test  # Run the tests
```
