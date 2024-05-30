module Data.Lighthouse exposing (Lighthouse, cid, decoder, encode, fileName, fileSize)

import Json.Decode
import Json.Encode


type alias Lighthouse =
    { cid : String
    , createdAt : Int
    , fileName : String
    , fileSizeInBytes : String
    , id : String
    , publicKey : String
    }


decoder : Json.Decode.Decoder Lighthouse
decoder =
    Json.Decode.map6 Lighthouse
        (Json.Decode.field "cid" Json.Decode.string)
        (Json.Decode.field "createdAt" Json.Decode.int)
        (Json.Decode.field "fileName" Json.Decode.string)
        (Json.Decode.field "fileSizeInBytes" Json.Decode.string)
        (Json.Decode.field "id" Json.Decode.string)
        (Json.Decode.field "publicKey" Json.Decode.string)


encode : Lighthouse -> Json.Encode.Value
encode lighthouse =
    Json.Encode.object
        [ ( "cid", Json.Encode.string lighthouse.cid )
        , ( "createdAt", Json.Encode.int lighthouse.createdAt )
        , ( "fileName", Json.Encode.string lighthouse.fileName )
        , ( "fileSizeInBytes", Json.Encode.string lighthouse.fileSizeInBytes )
        , ( "id", Json.Encode.string lighthouse.id )
        , ( "publicKey", Json.Encode.string lighthouse.publicKey )
        ]


fileSize : Lighthouse -> Int
fileSize lighthouse =
    lighthouse.fileSizeInBytes
        |> String.toInt
        |> Maybe.withDefault 0


cid : Lighthouse -> String
cid lighthouse =
    lighthouse.cid


fileName : Lighthouse -> String
fileName lighthouse =
    case lighthouse.fileName of
        "blob" ->
            "unknown"

        name ->
            name
