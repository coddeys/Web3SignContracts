module Data.Lighthouse.Upload exposing (Upload, cid, decoder, name, size)

import Json.Decode


type alias Upload =
    { cid : String
    , name : String
    , size : String
    }


decoder : Json.Decode.Decoder Upload
decoder =
    Json.Decode.map3 Upload
        (Json.Decode.field "Hash" Json.Decode.string)
        (Json.Decode.field "Name" Json.Decode.string)
        (Json.Decode.field "Size" Json.Decode.string)


size : Upload -> Int
size upload =
    upload.size
        |> String.toInt
        |> Maybe.withDefault 0


cid : Upload -> String
cid upload =
    upload.cid


name : Upload -> String
name upload =
    upload.name
