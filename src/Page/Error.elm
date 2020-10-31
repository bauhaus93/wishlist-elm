module Page.Error exposing (..)

import Browser
import Browser.Navigation as Nav
import Error exposing (Error, view_error)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Page exposing (ViewInfo)


type alias Model =
    { nav_key : Nav.Key
    , error : Error
    }


type Msg
    = NoMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    { title = "{{ PAGE.ERROR.TITLE }}"
    , caption = "{{ PAGE.ERROR.CAPTION }}"
    , content = view_error model.error
    }


to_nav_key : Model -> Nav.Key
to_nav_key model =
    model.nav_key


to_last_error : Model -> Maybe Error
to_last_error model =
    Just model.error


init : Nav.Key -> Error -> ( Model, Cmd Msg )
init nav_key error =
    ( { nav_key = nav_key
      , error = error
      }
    , Cmd.none
    )
