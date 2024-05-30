module Pages.Home_ exposing (Model, Msg, page)

import Auth
import Effect exposing (Effect)
import Html exposing (..)
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
    = ExampleMsgReplaceMe


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ExampleMsgReplaceMe ->
            ( model
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Pages.Home_"
    , body =
        [ h1 [] [ text "Sign and Store" ]
        , p [] [ text "Web3Sign lets you store and sign documents in a totally decentralized way. Documents are stored on IPFS storage. Signatures are stored on the blockchain. There is no centralized service provider. You can specify signers of your document, and they will be notified about the need to sign. You will be notified as soon as the document gets signed by everyone." ]
        ]
    }
