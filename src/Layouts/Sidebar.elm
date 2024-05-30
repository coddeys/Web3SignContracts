module Layouts.Sidebar exposing (Model, Msg, Settings, layout)

import Auth
import Dict exposing (Dict)
import Effect exposing (Effect)
import File
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
import Task
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
    { preview : Maybe String }


init : () -> ( Model, Effect Msg )
init _ =
    ( { preview = Nothing }
    , Effect.none
    )



-- UPDATE


type Msg
    = LogoutClicked
    | ConnectClicked
    | Incoming { data : Json.Encode.Value, tag : String }
    | UrlGen String
    | PreviewClosed


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


decryptedFileDecoder : Json.Decode.Decoder File.File
decryptedFileDecoder =
    Json.Decode.field "file" File.decoder


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

                "DECRYPTED_FILE_RECEIVED" ->
                    case Json.Decode.decodeValue decryptedFileDecoder data of
                        Ok file ->
                            ( model
                            , previewCmd file
                            )

                        Err err ->
                            ( model
                            , Effect.none
                            )

                _ ->
                    ( model
                    , Effect.none
                    )

        ConnectClicked ->
            ( model
            , Effect.connectClicked
            )

        LogoutClicked ->
            ( model
            , Effect.logout
            )

        UrlGen str ->
            ( { model | preview = Just str }
            , Effect.none
            )

        PreviewClosed ->
            ( { model | preview = Nothing }
            , Effect.none
            )


previewCmd : File.File -> Effect Msg
previewCmd file =
    file
        |> File.toUrl
        |> Task.perform UrlGen
        |> Effect.sendCmd


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
                [ -- li [] [ div [] [a [ href "", onClick (fromMsg LogoutClicked) ] [ text "Sign  out" ] ]]
                  li []
                    [ div []
                        [ Auth.account settings.user
                            |> Maybe.map viewAccount
                            |> Maybe.withDefault (viewConnect fromMsg)
                        ]
                    ]
                ]
            ]
        , case Auth.account settings.user of
            Just _ ->
                main_ [ class "container" ] content.body

            Nothing ->
                viewNotConnected
        , viewPreview fromMsg model
        ]
    }


viewAccount : String -> Html msg
viewAccount str =
    kbd [ title "Account" ]
        [ text <| String.left 5 str ++ "..." ++ String.right 4 str ]


viewConnect : (Msg -> mainMsg) -> Html mainMsg
viewConnect fromMsg =
    li [] [ div [ attribute "role" "button", onClick (fromMsg ConnectClicked) ] [ text "Connect" ] ]


viewNotConnected =
    div [ class "container" ]
        [ text "Please connect your wallet" ]


viewLink : String -> Path -> Html msg
viewLink label path =
    li []
        [ a
            [ Path.href path ]
            [ text label ]
        ]


viewPreview : (Msg -> msg) -> Model -> Html msg
viewPreview fromMsg model =
    case model.preview of
        Just preview ->
            div [ style "width" "100vw" ]
                [ node "dialog"
                    [ attribute "open" "" ]
                    [ article
                        [ style "max-width" "90%"
                        , style "width" "90%"
                        , style "max-height" "90%"
                        , style "height" "100%"
                        , style "overflow" "hidden"
                        ]
                        [ header []
                            [ span [ class "close", attribute "arith-label" "Close", onClick <| fromMsg PreviewClosed ] []
                            , text "Preview"
                            ]
                        , div
                            [ style "width" "100%"
                            , style "height" "100%"
                            ]
                            [ object
                                [ style "width" "100%"
                                , style "height" "100%"
                                , style "padding-bottom" "2rem"
                                , attribute "data" preview
                                ]
                                []
                            ]
                        ]
                    ]
                ]

        Nothing ->
            text ""
