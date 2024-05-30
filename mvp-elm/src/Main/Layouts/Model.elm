module Main.Layouts.Model exposing (..)

import Layouts.Default
import Layouts.Sidebar


type Model
    = Default { default : Layouts.Default.Model }
    | Sidebar { sidebar : Layouts.Sidebar.Model }
