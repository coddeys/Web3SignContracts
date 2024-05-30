module Main.Pages.Msg exposing (Msg(..))

import Pages.Home_
import Pages.Docs
import Pages.NotFound_


type Msg
    = Home_ Pages.Home_.Msg
    | Docs Pages.Docs.Msg
    | NotFound_
