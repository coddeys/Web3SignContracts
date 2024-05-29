port module Effect exposing
    ( Effect
    , none, batch
    , sendCmd, sendMsg
    , pushRoute, replaceRoute, loadExternalUrl
    , map, toCmd
    , connectClicked, del, encrypt, incoming, login, logout, sign, syncIn, syncOut, upload, uploadToIPFS
    )

{-|

@docs Effect
@docs none, batch
@docs sendCmd, sendMsg
@docs pushRoute, replaceRoute, loadExternalUrl

@docs map, toCmd

-}

import Browser.Navigation
import Dict exposing (Dict)
import FileValue exposing (File)
import Json.Decode
import Json.Encode
import Route exposing (Route)
import Route.Path
import Route.Query
import Shared.Model exposing (Docs)
import Shared.Msg
import Task
import Url exposing (Url)


type Effect msg
    = -- BASICS
      None
    | Batch (List (Effect msg))
    | SendCmd (Cmd msg)
      -- ROUTING
    | PushUrl String
    | ReplaceUrl String
    | LoadExternalUrl String
      -- SHARED
    | SendSharedMsg Shared.Msg.Msg
      -- CUSTOM
    | SendMessageToJavaScript
        { tag : String
        , data : Json.Encode.Value
        }


port outgoing : { tag : String, data : Json.Encode.Value } -> Cmd msg


port incoming : ({ tag : String, data : Json.Encode.Value } -> msg) -> Sub msg


connectClicked : Effect msg
connectClicked =
    SendMessageToJavaScript
        { tag = "CONNECT"
        , data = Json.Encode.null
        }


upload : File -> Effect msg
upload file =
    SendMessageToJavaScript
        { tag = "UPLOAD"
        , data = FileValue.encode file
        }


uploadToIPFS : Int -> Effect msg
uploadToIPFS key =
    SendMessageToJavaScript
        { tag = "UPLOAD_TO_IPFS"
        , data = Json.Encode.object [ ( "key", Json.Encode.int key ) ]
        }


syncOut : Effect msg
syncOut =
    SendMessageToJavaScript
        { tag = "SYNC"
        , data = Json.Encode.null
        }


del : Int -> Effect msg
del key =
    SendMessageToJavaScript
        { tag = "DEL"
        , data = Json.Encode.object [ ( "key", Json.Encode.int key ) ]
        }


sign : Int -> Effect msg
sign key =
    SendMessageToJavaScript
        { tag = "SIGN"
        , data = Json.Encode.object [ ( "key", Json.Encode.int key ) ]
        }


encrypt : Int -> Effect msg
encrypt key =
    SendMessageToJavaScript
        { tag = "ENCRYPT"
        , data = Json.Encode.object [ ( "key", Json.Encode.int key ) ]
        }



-- SHARED


login : { accounts : List String } -> Effect msg
login options =
    SendSharedMsg (Shared.Msg.Login options)


logout : Effect msg
logout =
    SendSharedMsg Shared.Msg.Logout


syncIn : { docs : Docs } -> Effect msg
syncIn options =
    SendSharedMsg (Shared.Msg.SyncIn options)



-- BASICS


{-| Don't send any effect.
-}
none : Effect msg
none =
    None


{-| Send multiple effects at once.
-}
batch : List (Effect msg) -> Effect msg
batch =
    Batch


{-| Send a normal `Cmd msg` as an effect, something like `Http.get` or `Random.generate`.
-}
sendCmd : Cmd msg -> Effect msg
sendCmd =
    SendCmd


{-| Send a message as an effect. Useful when emitting events from UI components.
-}
sendMsg : msg -> Effect msg
sendMsg msg =
    Task.succeed msg
        |> Task.perform identity
        |> SendCmd



-- ROUTING


{-| Set the new route, and make the back button go back to the current route.
-}
pushRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
pushRoute route =
    PushUrl (Route.toString route)


{-| Set the new route, but replace the previous one, so clicking the back
button **won't** go back to the previous route.
-}
replaceRoute :
    { path : Route.Path.Path
    , query : Dict String String
    , hash : Maybe String
    }
    -> Effect msg
replaceRoute route =
    ReplaceUrl (Route.toString route)


{-| Redirect users to a new URL, somewhere external your web application.
-}
loadExternalUrl : String -> Effect msg
loadExternalUrl =
    LoadExternalUrl



-- INTERNALS


{-| Elm Land depends on this function to connect pages and layouts
together into the overall app.
-}
map : (msg1 -> msg2) -> Effect msg1 -> Effect msg2
map fn effect =
    case effect of
        None ->
            None

        Batch list ->
            Batch (List.map (map fn) list)

        SendCmd cmd ->
            SendCmd (Cmd.map fn cmd)

        PushUrl url ->
            PushUrl url

        ReplaceUrl url ->
            ReplaceUrl url

        LoadExternalUrl url ->
            LoadExternalUrl url

        SendSharedMsg sharedMsg ->
            SendSharedMsg sharedMsg

        SendMessageToJavaScript message ->
            SendMessageToJavaScript message


{-| Elm Land depends on this function to perform your effects.
-}
toCmd :
    { key : Browser.Navigation.Key
    , url : Url
    , shared : Shared.Model.Model
    , fromSharedMsg : Shared.Msg.Msg -> msg
    , fromCmd : Cmd msg -> msg
    , toCmd : msg -> Cmd msg
    }
    -> Effect msg
    -> Cmd msg
toCmd options effect =
    case effect of
        None ->
            Cmd.none

        Batch list ->
            Cmd.batch (List.map (toCmd options) list)

        SendCmd cmd ->
            cmd

        PushUrl url ->
            Browser.Navigation.pushUrl options.key url

        ReplaceUrl url ->
            Browser.Navigation.replaceUrl options.key url

        LoadExternalUrl url ->
            Browser.Navigation.load url

        SendSharedMsg sharedMsg ->
            Task.succeed sharedMsg
                |> Task.perform options.fromSharedMsg

        SendMessageToJavaScript message ->
            outgoing message
