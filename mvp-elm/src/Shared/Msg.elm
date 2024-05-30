module Shared.Msg exposing (Msg(..))

{-| -}

import Dict exposing (Dict)
import FileValue exposing (File)
import Shared.Model


{-| Normally, this value would live in "Shared.elm"
but that would lead to a circular dependency import cycle.

For that reason, both `Shared.Model` and `Shared.Msg` are in their
own file, so they can be imported by `Effect.elm`

-}
type Msg
    = Login { accounts : List String }
    | Logout
    | SyncIn { docs : Shared.Model.Docs }
    | DecryptedFileReceived { fileValue : String }
