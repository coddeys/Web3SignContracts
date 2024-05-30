module Layouts exposing (..)

import Layouts.Default
import Layouts.Sidebar


type Layout
    = Default { default : Layouts.Default.Settings }
    | Sidebar { sidebar : Layouts.Sidebar.Settings }
