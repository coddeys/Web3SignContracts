module Pages.Docs exposing (Model, Msg, page)

import Effect exposing (Effect)
import File.Select as Select
import FileValue exposing (File, hiddenInputSingle)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout layout


layout : Model -> Layouts.Layout
layout model =
    Layouts.Default
        { default = { title = "title" } }



-- INIT


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init () =
    ( {}
    , Effect.none
    )



-- UPDATE


type Msg
    = SyncClicked
    | PdfLoaded File


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SyncClicked ->
            ( model
            , Effect.sync
            )

        PdfLoaded pdf ->
            ( model
            , Effect.upload pdf
            )



-- requestPdf : Cmd Msg
-- requestPdf =
--     Select.file [ "application/zip" ] PdfLoaded
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Pages.Docs"
    , body =
        [ h1 [] [ Html.text "All Docs" ]
        , viewDocs
        ]
    }


viewDocs : Html Msg
viewDocs =
    div [ class "grid" ]
        [ article []
            [ hiddenInputSingle "upload" [ "text/pdf" ] PdfLoaded
            , label [ for "upload", attribute "role" "button" ] [ text "+ Upload" ]
            ]
        , article [] [ button [ onClick SyncClicked ] [ text "Sync" ] ]
        , article [] [ text "" ]
        , article [] [ text "" ]
        ]
