module Page.Timeline exposing (Model, Msg, init, to_last_error, to_nav_key, update, view)

import Api.Datapoint exposing (Datapoint)
import ApiRoute
import Browser
import Browser.Navigation as Nav
import Error
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import LineChart
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Axis.Intersection as Intersection
import LineChart.Axis.Line as AxisLine
import LineChart.Axis.Range as Range
import LineChart.Axis.Tick as Tick
import LineChart.Axis.Ticks as Ticks
import LineChart.Axis.Title as Title
import LineChart.Colors as Colors
import LineChart.Container as Container
import LineChart.Dots as Dots
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Interpolation as Interpolation
import LineChart.Junk as Junk
import LineChart.Legends as Legends
import LineChart.Line as Line
import Page exposing (ViewInfo)
import Route
import Time
import Utility exposing (timestamp_to_dm, timestamp_to_hm, wrap_row_col, wrap_row_col_centered)


type alias Model =
    { nav_key : Nav.Key
    , datapoints : Maybe (List Datapoint)
    , last_error : Maybe Error.Error
    }


type Msg
    = RequestLastDay
    | RequestLastWeek
    | RequestLastMonth
    | GotDatapoints (Result Http.Error (List Datapoint))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDatapoints result ->
            case result of
                Ok data ->
                    ( { model | datapoints = Just data }, Cmd.none )

                Err e ->
                    ( { model | last_error = Just (Error.HttpRequest e) }, Nav.pushUrl (to_nav_key model) (Route.to_string Route.Error) )

        RequestLastDay ->
            ( model, request_last_day )

        RequestLastWeek ->
            ( model, request_last_week )

        RequestLastMonth ->
            ( model, request_last_month )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    let
        timespan_button : Msg -> Bool -> String -> Html Msg
        timespan_button msg is_active label_string =
            label [ class "btn btn-secondary" ]
                [ input [ type_ "radio", name "timespan", attribute "autocomplete" "off", onClick msg ] []
                , text label_string
                ]

        request_buttons =
            div [ class "btn-group btn-group-toggle", attribute "data-toggle" "buttons" ]
                [ timespan_button RequestLastDay True "{{ LABEL.LAST_DAY }}"
                , timespan_button RequestLastWeek False "{{ LABEL.LAST_WEEK }}"
                , timespan_button RequestLastMonth False "{{ LABEL.LAST_MONTH }}"
                ]

        chart =
            case model.datapoints of
                Just datapoints ->
                    let
                        high =
                            List.tail datapoints
                                |> Maybe.andThen List.head

                        low =
                            List.head datapoints

                        resolution =
                            case ( high, low ) of
                                ( Just hi, Just lo ) ->
                                    hi.slice - lo.slice

                                ( _, _ ) ->
                                    3600

                        chart_config =
                            { x = x_axis_config resolution
                            , y = Axis.default 400 "{{ LABEL.VALUE }}" .value
                            , container = Container.responsive "chart-1"
                            , interpolation = Interpolation.monotone
                            , intersection = Intersection.default
                            , legends = Legends.none
                            , events = Events.default
                            , junk = Junk.default
                            , grid = Grid.default
                            , area = Area.default
                            , line = Line.wider 3.0
                            , dots = Dots.default
                            }

                        prepared_datapoints =
                            List.map (\d -> { slice = d.slice, value = toFloat d.value / 100.0 }) datapoints
                    in
                    LineChart.viewCustom chart_config [ LineChart.line Colors.blueLight Dots.none "{{ LABEL.VALUE }}" prepared_datapoints ]

                Nothing ->
                    div [] []
    in
    { title = "{{ PAGE.TITLE }}"
    , caption = "{{ PAGE.TIMELINE.CAPTION }}"
    , content = div [] [ wrap_row_col chart, wrap_row_col_centered request_buttons ]
    }


x_axis_config : Int -> Axis.Config { slice : Int, value : Float } msg
x_axis_config resolution =
    Axis.custom
        { title = Title.default "{{ LABEL.TIME }}"
        , variable = \d -> Just (toFloat d.slice)
        , pixels = 600
        , range = Range.default
        , axisLine = AxisLine.full Colors.black
        , ticks = Ticks.intCustom 6 (custom_tick resolution)
        }


custom_tick : Int -> Int -> Tick.Config msg
custom_tick resolution n =
    let
        formatter : Int -> String
        formatter =
            case resolution < 24 * 3600 of
                True ->
                    \v -> timestamp_to_hm (v - modBy 3600 v)

                False ->
                    timestamp_to_dm
    in
    Tick.custom
        { position = toFloat n
        , color = Colors.black
        , width = 2
        , length = 2
        , grid = True
        , direction = Tick.negative
        , label = Just (Junk.label Colors.black (formatter n))
        }


to_nav_key : Model -> Nav.Key
to_nav_key model =
    model.nav_key


to_last_error : Model -> Maybe Error.Error
to_last_error model =
    model.last_error


request_datapoints : ApiRoute.TimelineQuery -> Cmd Msg
request_datapoints query =
    Http.get
        { url = ApiRoute.to_string (ApiRoute.Timeline query)
        , expect = Http.expectJson GotDatapoints Api.Datapoint.list_decoder
        }


request_last_day : Cmd Msg
request_last_day =
    request_datapoints { resolution = Just 3600, count = Just 24 }


request_last_week : Cmd Msg
request_last_week =
    request_datapoints { resolution = Just (24 * 3600), count = Just 7 }


request_last_month : Cmd Msg
request_last_month =
    request_datapoints { resolution = Just (2 * 24 * 3600), count = Just 14 }


init : Nav.Key -> ( Model, Cmd Msg )
init nav_key =
    ( { nav_key = nav_key
      , datapoints = Nothing
      , last_error = Nothing
      }
    , request_last_day
    )
