module Layouts.Default exposing (Model, Msg, Settings, layout)

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
import View exposing (View)


type alias Settings =
    { title : String }


layout : Settings -> Shared.Model -> Route () -> Layout Model Msg mainMsg
layout settings shared route =
    Layout.new
        { init = init
        , update = update
        , view = view shared
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
    = LoginClicked
    | LogoutClicked
    | Incoming { data : Json.Encode.Value, tag : String }


metaMaskAccountDecoder : Json.Decode.Decoder (List String)
metaMaskAccountDecoder =
    Json.Decode.field "accounts" (Json.Decode.list Json.Decode.string)


docsDecoder : Json.Decode.Decoder (List File)
docsDecoder =
    Json.Decode.field "docs" (Json.Decode.list FileValue.decoder)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        Incoming { data, tag } ->
            case tag of
                "GOT_ACCOUNT" ->
                    case Json.Decode.decodeValue metaMaskAccountDecoder data of
                        Ok accounts ->
                            ( model
                            , Effect.signIn { accounts = accounts }
                            )

                        Err err ->
                            ( model
                            , Effect.none
                            )

                "GOT_DOCS" ->
                    case Debug.log "result" <| Json.Decode.decodeValue docsDecoder data of
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

        LoginClicked ->
            ( model
            , Effect.login
            )

        LogoutClicked ->
            ( model
            , Effect.signOut
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Effect.incoming Incoming



-- VIEW


view : Shared.Model -> { fromMsg : Msg -> mainMsg, content : View mainMsg, model : Model } -> View mainMsg
view shared { fromMsg, model, content } =
    { title = content.title
    , body =
        [ nav [ class "container-fluid" ]
            [ ul []
                [ li [] [ viewLink "Web3Sign" Path.Home_ ] ]
            , ul []
                (if List.isEmpty shared.accounts then
                    [ li [] [ div [ attribute "role" "button", onClick (fromMsg LoginClicked) ] [ text "Sign in" ] ] ]

                 else
                    [ viewLink "Docs" Path.Docs
                    , li [] [ div [ attribute "role" "button", onClick (fromMsg LogoutClicked) ] [ text "Sign out" ] ]
                    ]
                )
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
