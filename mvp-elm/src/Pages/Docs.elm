module Pages.Docs exposing (Model, Msg, page)

import Effect exposing (Effect)
import File
import File.Select as Select
import FileValue exposing (File, hiddenInputSingle)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode
import Json.Encode
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Shared
import Task
import Time
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view shared.docs
        }
        |> Page.withLayout layout


layout : Model -> Layouts.Layout
layout model =
    Layouts.Default
        { default = { title = "title" } }



-- INIT


type alias Model =
    { preview : Maybe String
    }


init : () -> ( Model, Effect Msg )
init () =
    ( { preview = Nothing
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = SyncClicked
    | PdfLoaded File
    | UrlGen String
    | PreviewClicked File
    | PreviewClosed


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SyncClicked ->
            ( model
            , Effect.syncOut
            )

        PdfLoaded pdf ->
            ( model
            , Effect.upload pdf
            )

        UrlGen str ->
            ( { model | preview = Just str }
            , Effect.none
            )

        PreviewClicked file ->
            ( model
            , file.value
                |> Json.Decode.decodeValue File.decoder
                |> Result.map
                    (\x ->
                        x
                            |> File.toUrl
                            |> Task.perform UrlGen
                            |> Effect.sendCmd
                    )
                |> Result.withDefault Effect.none
            )

        PreviewClosed ->
            ( { model | preview = Nothing }
            , Effect.none
            )



-- requestPdf : Cmd Msg
-- requestPdf =
--     Select.file [ "application/zip" ] PdfLoaded
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : List File -> Model -> View Msg
view docs model =
    { title = "Pages.Docs"
    , body =
        [ h1 [] [ Html.text "All Docs" ]
        , viewDocs model docs
        ]
    }


viewDocs : Model -> List File -> Html Msg
viewDocs model docs =
    div []
        [ div [ class "grid" ]
            [ article []
                [ hiddenInputSingle "upload" [ "text/pdf" ] PdfLoaded
                , label [ for "upload", attribute "role" "button" ] [ text "+ Upload" ]
                ]
            , article [] [ button [ onClick SyncClicked ] [ text "Sync" ] ]
            , article [] [ text "" ]
            , article [] [ text "" ]
            ]
        , div []
            [ table []
                [ thead []
                    [ tr []
                        [ th [ attribute "scope" "col" ] [ text "Name" ]
                        , th [ attribute "scope" "col" ] [ text "Signed" ]
                        , th [ attribute "scope" "col" ] [ text "Size" ]
                        , th [ attribute "scope" "col" ] [ text "Modified" ]
                        ]
                    ]
                , tbody [] (List.map viewRow docs)
                ]
            ]
        , viewPreview model
        ]


viewPreview : Model -> Html Msg
viewPreview model =
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
                            [ a [ class "close", attribute "arith-label" "Close", onClick PreviewClosed ] []
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


viewRow : File -> Html Msg
viewRow doc =
    tr [ attribute "scope" "col" ]
        [ td [ onClick (PreviewClicked doc) ] [ a [ href "" ] [ text doc.name ] ]
        , td [] [ text "no" ]
        , td [] [ text <| String.fromInt doc.size ++ "B" ]
        , td [] [ text <| toUtcString doc.lastModified ]
        ]


toUtcString : Time.Posix -> String
toUtcString time =
    String.fromInt (Time.toHour Time.utc time)
        ++ ":"
        ++ String.fromInt (Time.toMinute Time.utc time)
        ++ ":"
        ++ String.fromInt (Time.toSecond Time.utc time)
        ++ " (UTC)"
