module Gen.Msg exposing (Msg(..))

import Gen.Params.Docs
import Gen.Params.Home_
import Gen.Params.NotFound
import Pages.Docs
import Pages.Home_
import Pages.NotFound


type Msg
    = Docs Pages.Docs.Msg
    | Home_ Pages.Home_.Msg

