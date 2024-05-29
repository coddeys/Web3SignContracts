module Auth exposing (User, account, onPageLoad)

import Auth.Action
import Dict
import Route exposing (Route)
import Route.Path
import Shared
import Shared.Model


type alias User =
    Maybe Shared.Model.User


account : User -> Maybe String
account user =
    Maybe.map .accounts user
        |> Maybe.andThen List.head


{-| Called before an auth-only page is loaded.
-}
onPageLoad : Shared.Model -> Route () -> Auth.Action.Action User
onPageLoad shared route =
    Auth.Action.loadPageWithUser shared.user
