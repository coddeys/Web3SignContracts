module Main.Pages.Model exposing (Model(..))

import Pages.Home_
import Pages.Docs
import Pages.NotFound_
import View exposing (View)


type Model
    = Home_ Pages.Home_.Model
    | Docs Pages.Docs.Model
    | NotFound_
    | Redirecting_
    | Loading_ (View Never)
