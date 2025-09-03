//// Module where we can find the base types used for the CBOR values

/// The base types used for representing CBOR values with Gleam types, used
/// as a primary output from the decoding process, as well as input for the
/// encoding process.
///
/// > **Note**: This type may become opaque in future major types as we evaluate
/// > the API needs for this package.
///
import gleam/time/timestamp.{type Timestamp}

pub type CBOR {
  CBInt(Int)
  CBString(String)
  CBFloat(Float)
  CBMap(List(#(CBOR, CBOR)))
  CBArray(List(CBOR))
  CBBool(Bool)
  CBNull
  CBUndefined
  CBBinary(BitArray)
  CBTagged(Int, CBOR)
  CBTime(Timestamp)
}

// Placeholder for LSP
pub const a = Nil
