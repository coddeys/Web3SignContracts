module Data.EncryptionKey exposing (EncryptionKey, decoder, toString)

import Json.Decode
import Json.Encode


type EncryptionKey
    = EncryptionKey String


decoder : Json.Decode.Decoder EncryptionKey
decoder =
    Json.Decode.map EncryptionKey Json.Decode.string


toString : EncryptionKey -> String
toString (EncryptionKey str) =
    str
