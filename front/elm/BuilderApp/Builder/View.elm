module BuilderApp.Builder.View exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Events as Events
import Element.Input as Input

import Icon exposing (..)
import Color exposing (..)

import Html as Html
import Html.Attributes as Html
import Html.Events as Html

import BuilderApp.Builder.Message exposing (..)
import BuilderApp.Builder.Model exposing (..)
import Util.View as Util
import BuilderApp.Builder.Method exposing (..)
import Api.Client as Client
import Http
import Application.Type exposing (..)
import Dict as Dict
import Json.Print as Json

view : Model a -> Element Msg
view model =
    let
        builderView =
            column [ width fill, spacing 10 ]
                [ column [ width fill ]
                      [ row [ width fill, spacing 10 ]
                            [ urlView model
                            , mainActionButtonsView
                            ]
                      ]
                , methodView model
                , headerView model
                , bodyView model
                ]
    in
        case model.showResponseView of
            False ->
                el [ width fill ] builderView

            True ->
                row [ width fill, spacing 20 ]
                    [ el [ width (fillPortion 5), alignTop ] builderView
                    , el [ width (fillPortion 5) ] (responseView model)
                    ]

responseView : Model a -> Element Msg
responseView model =
    let
        bodyResponseText : String -> Dict.Dict String String -> String
        bodyResponseText body responseHeaders =
            case Dict.get "content-type" responseHeaders of
                Just contentType ->
                    case String.contains "application/json" contentType of
                        True -> Result.withDefault body (Json.prettyString { indent = 4, columns = 4 } body)
                        False -> body
                _ -> body

        bodyResponseView : Response -> Element Msg
        bodyResponseView response =
            case response of
                Response status metadata body ->
                    Input.multiline []
                        { onChange = SetHttpBody
                        , text = bodyResponseText body metadata.headers
                        , placeholder = Nothing
                        , label = Input.labelHidden ""
                        , spellcheck = False
                        }
    in
        column []
            [ el [] (text "coucou")
            , case model.response of
                  Just (_ as response) ->
                      bodyResponseView response
                  Nothing ->
                      none
            ]


urlView : Model a -> Element Msg
urlView model =
    el [ alignLeft, width fill ] <|
        Input.text [ htmlAttribute <| Util.onEnter AskRun ]
            { onChange = UpdateUrl
            , text = editedOrNotEditedValue model.httpUrl
            , placeholder = Just <| Input.placeholder [] (text "myApi.com/path?arg=someArg")
            , label = labelView "Url: "
            }

mainActionButtonsView : Element Msg
mainActionButtonsView =
    let
        rowParam =
            [ centerY
            , height fill
            , spacing 10
            , alignRight
            , Font.color primaryColor
            ]

        inputParam =
            [ Border.solid
            , Border.color secondaryColor
            , Border.width 1
            , Border.rounded 5
            , Background.color secondaryColor
            , height fill
            , paddingXY 10 0
            ]
    in
        row rowParam
            [ Input.button inputParam
                { onPress = Just <| AskRun
                , label = el [ centerY] <| iconWithTextAndColor "send" "Send" primaryColor
                }
            , Input.button inputParam
                { onPress = Just <| AskSave
                , label = el [ centerY] <| iconWithTextAndColor "save" "Save" primaryColor
                }
            ]

methodView : Model a -> Element Msg
methodView model =
    Input.radioRow [ padding 10, spacing 20 ]
        { onChange = SetHttpMethod
        , selected = Just model.httpMethod
        , label = labelView "Method: "
        , options =
              [ Input.option Client.Get (text "Get")
              , Input.option Client.Post (text "Post")
              , Input.option Client.Put (text "Put")
              , Input.option Client.Delete (text "Delete")
              , Input.option Client.Patch (text "Patch")
              , Input.option Client.Head (text "Head")
              , Input.option Client.Options (text "Options")
              ]
        }

headerView : Model a -> Element Msg
headerView model =
    let
        untuple : (String, String) -> String
        untuple (key, value) =
            case String.isEmpty key of
                True -> ""
                False -> key ++ ":" ++ value

        headersToText : Editable (List (String, String)) -> String
        headersToText eHeaders =
            editedOrNotEditedValue model.httpHeaders
                |> List.map untuple
                |> String.join "\n"
    in
        Input.multiline []
            { onChange = UpdateHeaders
            , text = headersToText model.httpHeaders
            , placeholder = Just <| Input.placeholder [] (text "Header: SomeHeader\nHeader2: SomeHeader2")
            , label = labelView "Headers: "
            , spellcheck = False
            }

bodyView : Model a -> Element Msg
bodyView model =
    Input.multiline []
        { onChange = SetHttpBody
        , text = editedOrNotEditedValue model.httpBody
        , placeholder = Just <| Input.placeholder [] (text "{}")
        , label = labelView "Body: "
        , spellcheck = False
        }

labelView : String -> Input.Label Msg
labelView labelText =
    let
        size =
            width (fill
                  |> maximum 100
                  |> minimum 100
                  )
    in
        Input.labelLeft [ centerY, size ] <| text labelText
