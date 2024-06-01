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
        , p [] [ text "Web3Sign offers a fully decentralized platform for storing and signing documents, leveraging the InterPlanetary File System (IPFS) for document storage and blockchain technology for signature recording. This approach eliminates the need for centralized service providers, enhancing security and resilience against tampering and data loss. Users can designate signers, who are then notified to sign the document via decentralized notification systems. Once all parties have signed, notifications are sent out to confirm completion, ensuring transparency and integrity in the document signing process. This method is particularly valuable in scenarios where document security and verification are critical."]
        ]
    }
