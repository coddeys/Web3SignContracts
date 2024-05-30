module Shared exposing
    ( Flags, decoder
    , Model, Msg
    , init, update, subscriptions
    )

{-|

@docs Flags, decoder
@docs Model, Msg
@docs init, update, subscriptions

-}

import Dict
import Effect exposing (Effect)
import FileValue exposing (File)
import Json.Decode
import Route exposing (Route)
import Route.Path
import Shared.Model
import Shared.Msg



-- FLAGS


type alias Flags =
    { lighthouseApiKey : String
    }


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.map Flags
        (Json.Decode.field "lighthouseApiKey" Json.Decode.string)



-- INIT


type alias Model =
    Shared.Model.Model


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult route =
    case flagsResult of
        Ok { lighthouseApiKey } ->
            ( { docs = Dict.empty
              , user = Nothing
              , lighthouseApiKey = lighthouseApiKey
              }
            , Effect.syncOut
            )

        Err _ ->
            ( { docs = Dict.empty
              , user = Nothing
              , lighthouseApiKey = ""
              }
            , Effect.syncOut
            )



-- UPDATE


type alias Msg =
    Shared.Msg.Msg


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update route msg model =
    case msg of
        Shared.Msg.Login { accounts } ->
            ( { model | user = Just { accounts = accounts } }
            , Effect.pushRoute
                { path = Route.Path.Docs
                , query = Dict.empty
                , hash = Nothing
                }
            )

        Shared.Msg.Logout ->
            ( { model | user = Nothing }
            , Effect.pushRoute
                { path = Route.Path.Home_
                , query = Dict.empty
                , hash = Nothing
                }
            )

        Shared.Msg.SyncIn { docs } ->
            ( { model | docs = docs }
            , Effect.none
            )

        Shared.Msg.DecryptedFileReceived { fileValue } ->
            ( model
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions route model =
    Sub.none
