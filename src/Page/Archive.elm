module Page.Archive exposing (Model, Msg, init, to_last_error, to_nav_key, update, view)

import Api.Product exposing (Product)
import ApiRoute
import Browser
import Browser.Navigation as Nav
import Error
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Page exposing (ViewInfo)
import Pagination
import ProductTable exposing (view_product_table)
import Route
import Task
import Time
import Utility exposing (timestamp_to_dmy, wrap_row_col)


type alias Model =
    { nav_key : Nav.Key
    , time : Maybe Int
    , pagination : Pagination.Model Product
    , last_error : Maybe Error.Error
    }


type Msg
    = GotPaginationMsg (Pagination.Msg Product)
    | GotTime Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTime time ->
            let
                pagination_update =
                    Pagination.update (Pagination.ExactPage 1) model.pagination

                pagination_cmd =
                    Tuple.second pagination_update

                pagination_mod =
                    Tuple.first pagination_update
            in
            ( { model | time = Just (Time.posixToMillis time // 1000), pagination = pagination_mod }, Cmd.map GotPaginationMsg pagination_cmd )

        GotPaginationMsg sub_msg ->
            let
                pagination_update =
                    Pagination.update sub_msg model.pagination

                pagination_model =
                    Tuple.first pagination_update

                pagination_msg =
                    Tuple.second pagination_update
            in
            ( { model | pagination = pagination_model }, Cmd.map GotPaginationMsg pagination_msg )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    let
        pagination =
            Pagination.view model.pagination
                |> Html.map GotPaginationMsg

        product_table =
            view_product_table model.time (Pagination.to_items model.pagination)
    in
    { title = "Neuheiten"
    , caption = "Neuheiten"
    , content = div [] [ wrap_row_col product_table, wrap_row_col pagination ]
    }


update_with : (sub_model -> Model) -> (sub_msg -> Msg) -> Model -> ( sub_model, Cmd sub_msg ) -> ( Model, Cmd Msg )
update_with to_model to_msg model ( sub_model, sub_cmd ) =
    ( to_model sub_model
    , Cmd.map to_msg sub_cmd
    )


to_nav_key : Model -> Nav.Key
to_nav_key model =
    model.nav_key


to_last_error : Model -> Maybe Error.Error
to_last_error model =
    model.last_error


init : Nav.Key -> ( Model, Cmd Msg )
init nav_key =
    ( { nav_key = nav_key
      , time = Nothing
      , pagination = Pagination.init (\p -> ApiRoute.ProductArchive (Just p)) Nothing Api.Product.decoder
      , last_error = Nothing
      }
    , Task.perform GotTime Time.now
    )
