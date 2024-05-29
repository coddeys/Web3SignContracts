module Shared.Model exposing (Doc, Docs, Model, User, docsDecoder, isUplodedToIPFS)

{-| -}

import Data.EncryptionKey as EncryptionKey exposing (EncryptionKey)
import Data.Lighthouse as Lighthouse exposing (Lighthouse)
import Data.Sign as Sign exposing (Sign)
import Dict exposing (Dict)
import FileValue exposing (File)
import Json.Decode
import Json.Encode
import Maybe.Extra as Maybe


{-| Normally, this value would live in "Shared.elm"
but that would lead to a circular dependency import cycle.

For that reason, both `Shared.Model` and `Shared.Msg` are in their
own file, so they can be imported by `Effect.elm`

-}
type alias Model =
    { docs : Docs
    , user : Maybe User
    }


type alias User =
    { accounts : List String }


type alias Docs =
    Dict Int Doc


type alias Doc =
    { name : String
    , file : File
    , signed : Maybe Sign
    , encryptionKey : Maybe EncryptionKey
    , lighthouse : Maybe Lighthouse
    }


isUplodedToIPFS : Doc -> Bool
isUplodedToIPFS doc =
    Maybe.isJust doc.lighthouse


docsDecoder : Json.Decode.Decoder Docs
docsDecoder =
    docsDecoder_
        |> Json.Decode.maybe
        |> Json.Decode.list
        |> Json.Decode.field "docs"
        |> Json.Decode.map (List.filterMap identity)
        |> Json.Decode.map Dict.fromList


docsDecoder_ : Json.Decode.Decoder ( Int, Doc )
docsDecoder_ =
    Json.Decode.map2 Tuple.pair
        (Json.Decode.field "key" Json.Decode.int)
        (Json.Decode.field "doc" docDecoder)


docDecoder : Json.Decode.Decoder Doc
docDecoder =
    Json.Decode.map5 Doc
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "file" FileValue.decoder)
        (Json.Decode.maybe <| Json.Decode.field "signed" Sign.decoder)
        (Json.Decode.maybe <| Json.Decode.field "encryptionKey" EncryptionKey.decoder)
        (Json.Decode.maybe <| Json.Decode.field "lighthouse" Lighthouse.decoder)
