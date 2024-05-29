module Layouts.Sidebar exposing (Model, Msg, Settings, layout)

import Auth
import Dict exposing (Dict)
import Effect exposing (Effect)
import FileValue exposing (File)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode
import Json.Encode
import Layout exposing (Layout)
import Route exposing (Route)
import Route.Path as Path exposing (Path)
import Shared
import Shared.Model
import View exposing (View)


type alias Settings =
    { title : String
    , user : Auth.User
    }


layout : Settings -> Shared.Model -> Route () -> Layout Model Msg mainMsg
layout settings shared route =
    Layout.new
        { init = init
        , update = update
        , view = view settings route
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init _ =
    ( {}
    , Effect.none
    )



-- UPDATE


type Msg
    = LogoutClicked
    | Incoming { data : Json.Encode.Value, tag : String }


metaMaskAccountDecoder : Json.Decode.Decoder (List String)
metaMaskAccountDecoder =
    Json.Decode.field "accounts" (Json.Decode.list Json.Decode.string)


docsDecoder : Json.Decode.Decoder (Dict Int File)
docsDecoder =
    Json.Decode.list docsDecoder_
        |> Json.Decode.field "docs"
        |> Json.Decode.map Dict.fromList


docsDecoder_ : Json.Decode.Decoder ( Int, File )
docsDecoder_ =
    Json.Decode.map2 Tuple.pair
        (Json.Decode.field "key" Json.Decode.int)
        (Json.Decode.field "file" FileValue.decoder)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        Incoming { data, tag } ->
            case tag of
                "GOT_ACCOUNT" ->
                    case Json.Decode.decodeValue metaMaskAccountDecoder data of
                        Ok accounts ->
                            ( model
                            , Effect.login { accounts = accounts }
                            )

                        Err err ->
                            ( model
                            , Effect.none
                            )

                "GOT_DOCS" ->
                    case Json.Decode.decodeValue Shared.Model.docsDecoder data of
                        Ok docs ->
                            ( model
                            , Effect.syncIn { docs = docs }
                            )

                        Err err ->
                            ( model
                            , Effect.none
                            )

                _ ->
                    ( model
                    , Effect.none
                    )

        LogoutClicked ->
            ( model
            , Effect.logout
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Effect.incoming Incoming



-- VIEW


view :
    Settings
    -> Route ()
    ->
        { fromMsg : Msg -> mainMsg
        , content : View mainMsg
        , model : Model
        }
    -> View mainMsg
view settings route { fromMsg, model, content } =
    { title = content.title ++ " | Web3Sign"
    , body =
        [ nav [ class "container-fluid" ]
            [ ul []
                [ li [] [ viewLink "Web3Sign" Path.Home_ ] ]
            , ul []
                [ li [] [ div [ onClick (fromMsg LogoutClicked) ] [ text "Sign out" ] ]
                ]
            ]
        , main_ [ class "container" ] content.body
        ]
    }


viewLink : String -> Path -> Html msg
viewLink label path =
    li []
        [ a
            [ Path.href path ]
            [ text label ]
        ]
