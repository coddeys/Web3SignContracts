module Data.Sign exposing (Sign, decoder, toString)

import Json.Decode
import Json.Encode


type Sign
    = Sign String


decoder : Json.Decode.Decoder Sign
decoder =
    Json.Decode.map Sign Json.Decode.string


toString : Sign -> String
toString (Sign str) =
    str
