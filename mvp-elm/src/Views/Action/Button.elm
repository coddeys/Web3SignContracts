module Views.Action.Button exposing (ActionButton, inactive, init, initCustom, toHtml)

import Data.Doc exposing (Doc)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Set exposing (Set)
import Shared.Model exposing (Docs)


type alias ActionButton msg =
    { label : String
    , toMsg : Set Int -> Docs -> Maybe msg
    , isDisabled : Set Int -> Docs -> Bool
    }


init :
    { label : String
    , toMsg : Set Int -> msg
    , isDisabled : Set Int -> Docs -> Bool
    }
    -> ActionButton msg
init { label, toMsg, isDisabled } =
    { label = label
    , toMsg = \keys docs -> Just <| toMsg keys
    , isDisabled = isDisabled
    }


initCustom :
    { label : String
    , toMsg : Set Int -> Docs -> Maybe msg
    , isDisabled : Set Int -> Docs -> Bool
    }
    -> ActionButton msg
initCustom { label, toMsg, isDisabled } =
    { label = label
    , toMsg = toMsg
    , isDisabled = isDisabled
    }


inactive : String -> ActionButton msg
inactive label =
    { label = label
    , toMsg = \_ _ -> Nothing
    , isDisabled = \_ _ -> True
    }


toHtml : ActionButton msg -> Set Int -> Docs -> Html msg
toHtml { label, toMsg, isDisabled } keys docs =
    button
        [ class "outline"
        , disabled (isDisabled keys docs)
        , case toMsg keys docs of
            Just msg ->
                onClick msg

            Nothing ->
                style "" ""
        ]
        [ text label ]
