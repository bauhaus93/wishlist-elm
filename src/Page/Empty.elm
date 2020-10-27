module Page.Empty exposing (view)

import Html exposing (..)


view : { title : String, caption : String, content : Html msg }
view =
    { title = ""
    , caption = ""
    , content = text ""
    }
