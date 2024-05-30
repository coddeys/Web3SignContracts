module Shared.Model exposing (Docs, Model, User, docsDecoder, docsKey)

{-| -}

import Data.Doc as Doc exposing (Doc)
import Data.EncryptionKey as EncryptionKey exposing (EncryptionKey)
import Data.Lighthouse as Lighthouse exposing (Lighthouse)
import Data.Sign as Sign exposing (Sign)
import Dict exposing (Dict)
import FileValue exposing (File)
import Json.Decode
import Json.Encode
import Set


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
    Dict String Doc


{-| Hacky way to generate the new Doc key
-}
docsKey : Docs -> String
docsKey docs =
    docs
        |> Dict.keys
        |> List.filterMap String.toInt
        |> List.maximum
        |> Maybe.withDefault 0
        |> (+) 1
        |> String.fromInt


docsDecoder : Json.Decode.Decoder Docs
docsDecoder =
    -- let
    --     fn fieldName =
    --         docsDecoder_
    --             |> Json.Decode.maybe
    --             |> Json.Decode.list
    --             |> Json.Decode.field fieldName
    --             |> Json.Decode.map (List.filterMap identity)
    -- in
    -- -- TODO: refactor this logic, it's confusing
    -- Json.Decode.map2 concat (fn "ipfs") (fn "docs")
    --     |> Json.Decode.map Dict.fromList
    Json.Decode.field "docs" (Json.Decode.list docDecoder)
        |> Json.Decode.map Dict.fromList



-- concat : List ( String, Doc ) -> List ( String, Doc ) -> List ( String, Doc )
-- concat xs ys =
--     let
--         isDup ( k, v ) =
--             xs
--                 |> List.map Tuple.second
--                 |> List.filterMap Doc.cid
--                 |> Set.fromList
--                 |> Set.member k
--     in
--     xs ++ List.filter (not << isDup) ys


docDecoder : Json.Decode.Decoder ( String, Doc )
docDecoder =
    Json.Decode.map2 Tuple.pair
        keyDecoder
        (Json.Decode.field "doc" Doc.decoder)


keyDecoder : Json.Decode.Decoder String
keyDecoder =
    [ Json.Decode.field "key" Json.Decode.int
        |> Json.Decode.map String.fromInt
    , Json.Decode.field "key" Json.Decode.string
    ]
        |> Json.Decode.oneOf
