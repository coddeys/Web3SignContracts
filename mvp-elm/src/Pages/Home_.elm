module Pages.Home_ exposing (Model, Msg, page)

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
        , p [] [ text "Web3Sign enables you to store and sign documents in a completely decentralized manner. Documents are stored using IPFS storage, and signatures are recorded on the blockchain. This system operates without a centralized service provider. You can designate signers for your document, who will receive notifications prompting them to sign. You will be alerted as soon as all signers have completed their signatures." ]
        ]
    }
