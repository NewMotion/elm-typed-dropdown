module TypedDropdown
    exposing
        ( Event(..)
        , Msg
        , Settings
        , TypedDropdown
        , defaultSettings
        , init
        , initWithSettings
        , update
        , view
        )

{-| Creates a dropdown that handles items of any type `t`.
Items are not part of this component's internal model, meaning that there is a
single source of truth: your own `Model`.
It sets the selected item by value, rather than by index, which can be useful
when the set of items is dynamic. User selection is communicated by returning
an Event that contains the selected item.


# Types

@docs TypedDropdown, Event, Msg, Settings


# Functions

@docs defaultSettings, init, initWithSettings, update, view

-}

import Html exposing (Html, a, button, div, li, span, text, ul)
import Html.Attributes exposing (class)
import Html.Events exposing (onBlur, onClick, onWithOptions)
import Json.Decode


{-|

@docs Opaque type representing messages used to change internal state.

-}
type Msg t
    = Toggle State
    | Select t


{-|

@docs Events that are used to communicate changes in state relevant to
users of this component.

-}
type Event t
    = Unchanged
    | ItemSelected t


{-|

@docs The TypedDropdown (opaque) model.

-}
type TypedDropdown
    = TypedDropdown Model


{-|

@docs Customization settings.

-}
type alias Settings =
    { placeHolder : String
    , closedClass : String
    , openedClass : String
    , menuClass : String
    , buttonClass : String
    , arrowUpClass : String
    , arrowDownClass : String
    , itemClass : String
    , activeItemClass : String
    }


{-| Internal state.
-}
type State
    = Opened
    | Closed


{-| Internal model.
-}
type alias Model =
    { settings : Settings
    , state : State
    }


{-|

@docs Initialize a TypedDropdown with default settings.

-}
init : TypedDropdown
init =
    TypedDropdown
        { settings = defaultSettings
        , state = Closed
        }


{-|

@docs Initialize a TypedDropdown with custom settings.

-}
initWithSettings : Settings -> TypedDropdown
initWithSettings settings =
    TypedDropdown
        { settings = settings
        , state = Closed
        }


{-|

@docs Default look and feel settings.

-}
defaultSettings : Settings
defaultSettings =
    { placeHolder = "Select ..."
    , closedClass = "dropdown"
    , openedClass = "dropdown open"
    , menuClass = "dropdown-menu"
    , buttonClass = "button-as-dropdown dropdown-toggle form-control"
    , arrowUpClass = "arrow glyphicon glyphicon-triangle-top"
    , arrowDownClass = "arrow glyphicon glyphicon-triangle-bottom"
    , itemClass = ""
    , activeItemClass = "active"
    }


toggle : State -> State
toggle state =
    case state of
        Opened ->
            Closed

        Closed ->
            Opened


{-|

@docs Update a TypedDropdown. Returns the updated TypedDropdown and an Event
that communicates changes that are relevant to the outside world, if
any (e.g. item selection).

-}
update : Msg t -> TypedDropdown -> ( TypedDropdown, Event t )
update msg (TypedDropdown model) =
    case msg of
        Toggle state ->
            ( TypedDropdown { model | state = state }
            , Unchanged
            )

        Select item ->
            ( TypedDropdown { model | state = toggle model.state }
            , ItemSelected item
            )


{-|

@docs Render a TypedDropdown using provided items, optional selected item, and
function that returns a string representation of an item.

-}
view : List t -> Maybe t -> (t -> String) -> TypedDropdown -> Html (Msg t)
view items selectedItem descriptionOf (TypedDropdown { settings, state }) =
    let
        ( clazz, newState, arrow ) =
            case state of
                Closed ->
                    ( settings.closedClass, Opened, settings.arrowDownClass )

                Opened ->
                    ( settings.openedClass, Closed, settings.arrowUpClass )

        isActive item =
            case selectedItem of
                Just selection ->
                    selection == item

                _ ->
                    False

        menuItems =
            List.map
                (\item ->
                    viewItem
                        item
                        descriptionOf
                        (isActive item)
                        settings.itemClass
                        settings.activeItemClass
                )
                items
    in
    div
        [ class clazz ]
        [ button
            [ class settings.buttonClass
            , onClick (Toggle newState)
            , onBlur (Toggle Closed)
            ]
            [ text
                (selectedItem
                    |> Maybe.map descriptionOf
                    |> Maybe.withDefault settings.placeHolder
                )
            , span [ class arrow ] []
            ]
        , ul
            [ class settings.menuClass
            ]
            menuItems
        ]


onItem : String -> msg -> Html.Attribute msg
onItem ev =
    Json.Decode.succeed
        >> onWithOptions ev
            { preventDefault = False
            , stopPropagation = True
            }


viewItem : t -> (t -> String) -> Bool -> String -> String -> Html (Msg t)
viewItem item descriptionOf active itemClass activeItemClass =
    let
        attrs =
            if active then
                [ class activeItemClass ]
            else
                [ class itemClass ]
    in
    li
        attrs
        [ a
            [ onItem "mousedown" (Select item) ]
            [ text (descriptionOf item) ]
        ]