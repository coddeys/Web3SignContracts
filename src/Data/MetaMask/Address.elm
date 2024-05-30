module Data.MetaMask.Address exposing (Address, decoder, encode, fromString, string)

import Json.Decode
import Json.Encode


type Address
    = Address String


string : Address -> String
string (Address str) =
    str


fromString : String -> Address
fromString str =
    Address str


decoder : Json.Decode.Decoder Address
decoder =
    Json.Decode.map Address <|
        Json.Decode.string


encode : Address -> Json.Encode.Value
encode (Address str) =
    Json.Encode.string str
