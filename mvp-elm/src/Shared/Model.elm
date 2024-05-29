module Shared.Model exposing (Docs, Model, User, docsDecoder)

{-| -}

import Data.Doc as Doc exposing (Doc)
import Data.EncryptionKey as EncryptionKey exposing (EncryptionKey)
import Data.Lighthouse as Lighthouse exposing (Lighthouse)
import Data.Sign as Sign exposing (Sign)
import Dict exposing (Dict)
import FileValue exposing (File)
import Json.Decode
import Json.Encode


{-| Normally, this value would live in "Shared.elm"
but that would lead to a circular dependency import cycle.

For that reason, both `Shared.Model` and `Shared.Msg` are in their
own file, so they can be imported by `Effect.elm`

-}
type alias Model =
    { docs : Docs
    , user : Maybe User
    , lighthouseApiKey : String
    }


type alias User =
    { accounts : List String }


type alias Docs =
    Dict Int Doc


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
        (Json.Decode.field "doc" Doc.decoder)
