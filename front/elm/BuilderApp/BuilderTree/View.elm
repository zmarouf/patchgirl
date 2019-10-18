module BuilderApp.BuilderTree.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

--import BuilderApp.BuilderTree.Model exposing (Model, RequestNode(..), BuilderTree)
import BuilderApp.Model exposing (..)
import BuilderApp.BuilderTree.Message exposing (Msg(..))
import BuilderApp.BuilderTree.FolderView exposing (..)
import BuilderApp.BuilderTree.FileView exposing (..)

import Util.View as Util

view : Model a -> Html Msg
view model =
  let
    treeView = Tuple.second (nodeView 0 model.displayedRequestNodeMenuIndex model.tree)
  in
    div [ class "columns" ]
      [ div [ class "column is-offset-1" ]
        treeView
      ]

nodeView : Int -> Maybe Int -> List RequestNode -> (Int, List (Html Msg))
nodeView idx mDisplayedRequestNodeMenuIndex tree =
  let
    showMenu = mDisplayedRequestNodeMenuIndex == Just idx
  in
    case tree of
      [] -> (idx, [])
      node :: tail ->
        case node of
          (RequestFolder { name, open, children, showRenameInput }) ->
            let
              (folderIdx, folderChildrenView) = nodeView (idx + 1) mDisplayedRequestNodeMenuIndex children
              (newIdx, tailView) = nodeView folderIdx mDisplayedRequestNodeMenuIndex tail
              currentFolderView = folderView name idx folderChildrenView open showMenu showRenameInput
            in
              (newIdx, currentFolderView :: tailView)

          (RequestFile { name, showRenameInput }) ->
            let
              (newIdx, tailView) = nodeView (idx + 1) mDisplayedRequestNodeMenuIndex tail
              currentFileView = fileView name idx showMenu showRenameInput
            in
              (newIdx, currentFileView :: tailView)
