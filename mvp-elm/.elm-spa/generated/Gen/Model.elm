module Gen.Model exposing (Model(..))

import Gen.Params.Docs
import Gen.Params.Home_
import Gen.Params.NotFound
import Pages.Docs
import Pages.Home_
import Pages.NotFound


type Model
    = Redirecting_
    | Docs Gen.Params.Docs.Params Pages.Docs.Model
    | Home_ Gen.Params.Home_.Params Pages.Home_.Model
    | NotFound Gen.Params.NotFound.Params

