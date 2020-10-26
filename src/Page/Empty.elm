module Page.Empty exposing (view)

import Html exposing (..)


view : { title : String, content : Html msg }
view =
    { title = ""
    , content = text ""
    }
