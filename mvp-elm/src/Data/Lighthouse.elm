module Data.Lighthouse exposing (Lighthouse, decoder)

import Json.Decode
import Json.Encode


type alias Lighthouse =
    { name : String
    , hash : String
    , size : String
    }


decoder : Json.Decode.Decoder Lighthouse
decoder =
    Json.Decode.map3 Lighthouse
        (Json.Decode.field "Name" Json.Decode.string)
        (Json.Decode.field "Hash" Json.Decode.string)
        (Json.Decode.field "Size" Json.Decode.string)
