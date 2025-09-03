//// Large values
//// Small values
//// Negative values
//// Special values (Infinity, NaN)

import gbor as g
import gbor/decode as d
import gbor/encode as e
import gleam/bit_array
import gleam/bool
import gleam/dynamic/decode as gdd
import gleam/list
import gleam/result
import gleam/string
import gleam/time/timestamp
import gleeunit

pub fn main() {
  gleeunit.main()
}

pub fn decode_bool_test() {
  let cases = [#(g.CBBool(True), "F5"), #(g.CBBool(False), "F4")]
  run_cases(cases)
}

pub fn decode_float_test() {
  // TODO get these working!
  // Basic floating point values
  //let assert Ok(_) = round_trip(g.CBFloat(0.0), "f90000")
  //let assert Ok(_) = round_trip(g.CBFloat(-0.0), "f98000")
  //let assert Ok(_) = round_trip(g.CBFloat(1.0), "f93c00")
  let assert Ok(_) = round_trip(g.CBFloat(1.1), "fb3ff199999999999a")
  //let assert Ok(_) = round_trip(g.CBFloat(1.5), "f93e00")

  //let assert Ok(_) = round_trip(g.CBFloat(65_504.0), "f97bff")
  //let assert Ok(_) = round_trip(g.CBFloat(100_000.0), "fa47c35000")
  //let assert Ok(_) = round_trip(g.CBFloat(3.4028234663852886e38), "fa7f7fffff")
  //let assert Ok(_) = round_trip(g.CBFloat(1.0e300), "fb7e37e43c8800759c")

  //let assert Ok(_) = round_trip(g.CBFloat(5.960464477539063e-08), "f90001")
  //let assert Ok(_) = round_trip(g.CBFloat(6.103515625e-05), "f90400")

  //let assert Ok(_) = round_trip(g.CBFloat(-4.0), "f9c400")
  //let assert Ok(_) = round_trip(g.CBFloat(-4.1), "fbc010666666666666")

  //let assert Ok(_) = round_trip(g.CBFloat(Infinity), "f97c00")
  //let assert Ok(_) = round_trip(g.CBFloat(-Infinity), "f9fc00")
  //let assert Ok(_) = round_trip(g.CBFloat(NaN), "f97e00")
  let cases = [
    //#(g.CBFloat(0.0), "f90000"),
    //#(g.CBFloat(-0.0), "f98000"),
    //#(g.CBFloat(1.0), "f93c00"),
    #(g.CBFloat(1.1), "fb3ff199999999999a"),
    //#(g.CBFloat(1.5), "f93e00"),
    //#(g.CBFloat(65_504.0), "f97bff"),
    //#(g.CBFloat(100_000.0), "fa47c35000"),
    //#(g.CBFloat(3.4028234663852886e38), "fa7f7fffff"),
    #(g.CBFloat(1.0e300), "fb7e37e43c8800759c"),
    //#(g.CBFloat(5.960464477539063e-08), "f90001"),
    //#(g.CBFloat(6.103515625e-05), "f90400"),
    //#(g.CBFloat(-4.0), "f9c400"),
    #(g.CBFloat(-4.1), "fbc010666666666666"),
    // TODO support inf/nan cases
  //#(g.CBFloat(Infinity), "f97c00"),
  //#(g.CBFloat(-Infinity), "f9fc00"),
  //#(g.CBFloat(NaN), "f97e00"),
  ]
  run_cases(cases)
}

pub fn decode_uint_test() {
  let cases = [
    #(g.CBInt(0), "00"),
    #(g.CBInt(1), "01"),
    #(g.CBInt(10), "0a"),
    #(g.CBInt(23), "17"),
    #(g.CBInt(24), "1818"),
    #(g.CBInt(25), "1819"),
    #(g.CBInt(100), "1864"),
    #(g.CBInt(1000), "1903e8"),
    #(g.CBInt(1_000_000), "1a000f4240"),
    #(g.CBInt(1_000_000_000_000), "1b000000e8d4a51000"),
    #(g.CBInt(18_446_744_073_709_551_615), "1bffffffffffffffff"),
  ]
  run_cases(cases)
}

pub fn decode_int_test() {
  let cases = [
    #(g.CBInt(-18_446_744_073_709_551_616), "3bffffffffffffffff"),
    #(g.CBInt(-1), "20"),
    #(g.CBInt(-10), "29"),
    #(g.CBInt(-100), "3863"),
    #(g.CBInt(-1000), "3903e7"),
  ]
  run_cases(cases)
}

pub fn decode_string_test() {
  let cases = [
    #(g.CBString(""), "60"),
    #(g.CBString("a"), "6161"),
    #(g.CBString("IETF"), "6449455446"),
    #(g.CBString("\"\\"), "62225c"),
    #(g.CBString("ü"), "62c3bc"),
    #(g.CBString("水"), "63e6b0b4"),
    #(g.CBString("𐅑"), "64f0908591"),
  ]
  run_cases(cases)
}

pub fn decode_bytes_test() {
  let cases = [
    #(g.CBBinary(<<>>), "40"),
    #(g.CBBinary(<<0x01, 0x02, 0x03, 0x04>>), "4401020304"),
  ]
  run_cases(cases)
}

pub fn decode_array_test() {
  let cases = [
    #(g.CBArray([]), "80"),
    #(g.CBArray([g.CBInt(1), g.CBInt(2), g.CBInt(3)]), "83010203"),
    #(
      g.CBArray([
        g.CBInt(1),
        g.CBArray([g.CBInt(2), g.CBInt(3)]),
        g.CBArray([g.CBInt(4), g.CBInt(5)]),
      ]),
      "8301820203820405",
    ),
    #(
      g.CBArray(list.map(list.range(1, 25), fn(i) { g.CBInt(i) })),
      "98190102030405060708090a0b0c0d0e0f101112131415161718181819",
    ),
  ]

  run_cases(cases)
}

pub fn decode_map_test() {
  let cases = [
    #(g.CBMap([]), "a0"),
    #(
      g.CBMap([#(g.CBInt(1), g.CBInt(2)), #(g.CBInt(3), g.CBInt(4))]),
      "a201020304",
    ),
    #(
      g.CBMap([
        #(g.CBString("a"), g.CBInt(1)),
        #(g.CBString("b"), g.CBArray([g.CBInt(2), g.CBInt(3)])),
      ]),
      "a26161016162820203",
    ),
    #(
      g.CBArray([
        g.CBString("a"),
        g.CBMap([#(g.CBString("b"), g.CBString("c"))]),
      ]),
      "826161a161626163",
    ),
    #(
      g.CBMap([
        #(g.CBString("a"), g.CBString("A")),
        #(g.CBString("b"), g.CBString("B")),
        #(g.CBString("c"), g.CBString("C")),
        #(g.CBString("d"), g.CBString("D")),
        #(g.CBString("e"), g.CBString("E")),
      ]),
      "a56161614161626142616361436164614461656145",
    ),
  ]

  run_cases(cases)
}

pub fn decode_simple_test() {
  let cases = [#(g.CBNull, "F6"), #(g.CBUndefined, "F7")]
  run_cases(cases)
  //round_trip(g.CBSimple(0), "F0")
  //round_trip(g.CBSimple(24), "F818")
  //round_trip(g.CBSimple(255), "F8FF")
}

pub fn decode_taggded_test() {
  let assert Ok(_) =
    round_trip(g.CBInt(18_446_744_073_709_551_616), "c249010000000000000000")

  let assert Ok(_) =
    round_trip(g.CBInt(-18_446_744_073_709_551_617), "c349010000000000000000")

  let assert Ok(timestamp) = timestamp.parse_rfc3339("2013-03-21T20:04:00Z")
  let assert Ok(_) =
    round_trip(
      g.CBTime(timestamp),
      "c074323031332d30332d32315432303a30343a30305a",
    )

  // CBTagged(1, CBInt(1363896240)) <=>
  // "c11a514b67b0" <=>
  // "2013-03-21T20:04:00Z"
  let assert Ok(_) = round_trip(g.CBTime(timestamp), "c11a514b67b0")

  // CBTagged(1, CBFloat(1363896240.5)) <=> "c1fb41d452d9ec200000"
  let assert Ok(timestamp) = timestamp.parse_rfc3339("2013-03-21T20:04:00.50Z")
  let assert Ok(_) = round_trip(g.CBTime(timestamp), "c1fb41d452d9ec200000")

  let assert Ok(_) =
    round_trip(
      g.CBTagged(23, g.CBBinary(<<0x01, 0x02, 0x03, 0x04>>)),
      "d74401020304",
    )

  let assert Ok(_) =
    round_trip(
      g.CBTagged(24, g.CBBinary(<<0x64, 0x49, 0x45, 0x54, 0x46>>)),
      "d818456449455446",
    )

  let assert Ok(_) =
    round_trip(
      g.CBTagged(32, g.CBString("http://www.example.com")),
      "d82076687474703a2f2f7777772e6578616d706c652e636f6d",
    )
}

pub fn indeterminate_length_test() {
  // TODO support indeterminate length arrays, maps, bytes and strings
  let cases = [
    // 5f42010243030405ff
  // 7f657374726561646d696e67ff
  // 9fff
  // 9f018202039f0405ffff
  // 9f01820203820405ff
  // 83018202039f0405ff
  // 83019f0203ff820405
  // 9f0102030405060708090a0b0c0d0e0f101112131415161718181819ff
  //bf61610161629f0203ffff
  // 826161bf61626163ff
  // bf6346756ef563416d7421ff
  ]
  run_cases(cases)
}

type Cat {
  Cat(name: String, dob: String)
}

pub fn decode_dynamic_test() {
  let assert Ok(bin) =
    bit_array.base16_decode(
      "A2646E616D6574323031332D30332D32315432303A30343A30305A63646F62C074323031332D30332D32315432303A30343A30305A",
    )

  let assert Ok(cbor_val) = d.from_bit_array(bin)
  let dyn_val = d.cbor_to_dynamic(cbor_val)

  let decoder = {
    use name <- gdd.field("name", gdd.string)
    use dob <- gdd.field("dob", d.tagged_decoder(0, gdd.string, "INVALID"))
    gdd.success(Cat(name, dob))
  }

  let assert Ok(v) = gdd.run(dyn_val, decoder)
  assert v == Cat("2013-03-21T20:04:00Z", "2013-03-21T20:04:00Z")

  let assert Ok(encoded) = e.to_bit_array(cbor_val)
  assert encoded == bin
}

fn round_trip(expected: g.CBOR, hex: String) -> Result(Nil, String) {
  let assert Ok(binary) = bit_array.base16_decode(hex)
  let assert Ok(v) = d.from_bit_array(binary)
  use <- bool.guard(
    v != expected,
    Error(
      "CBOR mismatch: decoded "
      <> string.inspect(v)
      <> " but expected "
      <> string.inspect(expected),
    ),
  )

  // Time is always encoded to tag 0, so skip when decoded from tag 1
  let assert Ok(encoded) = e.to_bit_array(v)
  case encoded == binary || string.starts_with(string.lowercase(hex), "c1") {
    True -> Ok(Nil)
    False -> {
      let encoded_hex = bit_array.base16_encode(encoded)
      Error("Binary mismatch, provided " <> hex <> " but got " <> encoded_hex)
    }
  }
}

fn run_cases(cases: List(#(g.CBOR, String))) {
  let results =
    list.map(cases, fn(c) {
      case round_trip(c.0, c.1) {
        Ok(_) -> Ok(Nil)
        Error(msg) -> {
          echo "Error: " <> msg <> " for hex " <> c.1
          Error(msg)
        }
      }
    })

  let assert Ok(_) = result.all(results)
}
