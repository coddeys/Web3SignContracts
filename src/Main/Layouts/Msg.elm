module Main.Layouts.Msg exposing (..)

import Layouts.Default
import Layouts.Sidebar


type Msg
    = Default Layouts.Default.Msg
    | Sidebar Layouts.Sidebar.Msg
