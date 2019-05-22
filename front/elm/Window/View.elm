module Window.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import BuilderTree.View as BuilderTree
import BuilderTree.Util as BuilderTree
import Postman.View as Postman
import Env.View as Env
import EnvNav.View as EnvNav
import EnvSelection.View as EnvSelection
import MainNavBar.View as MainNavBar
import MainNavBar.Model as MainNavBar
import Builder.View as Builder

import Builders.View as Builders

import Util.List as List

import BuilderTree.Model as BuilderTree

import Window.Model exposing(..)
import Window.Message exposing(..)

view : Model -> Html Msg
view model =
    let
        contentView : Html Msg
        contentView =
            div [ id "content" ] <|
                case model.mainNavBarModel of
                    MainNavBar.EnvTab -> [ Html.map EnvNavMsg (EnvNav.view model.envNavModel) ]
                    MainNavBar.ReqTab -> [ builderView model ]
    in
        div []
            [ Html.map MainNavBarMsg (MainNavBar.view model.mainNavBarModel)
            , contentView
            ]

builderView : Model -> Html Msg
builderView model =
  let
    treeView : Html Msg
    treeView =
      Html.map BuilderTreeMsg (BuilderTree.view model.treeModel)
    envSelectionView : Html Msg
    envSelectionView =
      Html.map EnvSelectionMsg (EnvSelection.view model.selectedEnvModel)
  in
    div [ id "builderApp" ]
      [ div [ id "treeView" ] [ treeView ]
      , div [ id "builderView" ] [ (Html.map BuildersMsg (Builders.view model.treeModel)) ]
      , div [ class "" ] [ envSelectionView ]
      ]

postmanView : Html Msg
postmanView =
  Html.map PostmanMsg Postman.view
