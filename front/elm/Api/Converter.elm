module Api.Converter exposing (..)

import Animation
import Api.WebGeneratedClient as Back
import Api.RunnerGeneratedClient as Back
import Application.Type as Front exposing (..)
import Dict
import Tuple
import StringTemplate exposing(..)


-- * request Collection


convertRequestCollectionFromBackToFront : Back.RequestCollection -> Front.RequestCollection
convertRequestCollectionFromBackToFront backRequestCollection =
    let
        (Back.RequestCollection id backRequestNodes) =
            backRequestCollection
    in
    Front.RequestCollection id (convertRequestNodesFromBackToFront backRequestNodes)


convertRequestNodesFromBackToFront : List Back.RequestNode -> List Front.RequestNode
convertRequestNodesFromBackToFront backRequestNodes =
    let
        convertRequestNodeFromBackToFront : Back.RequestNode -> Front.RequestNode
        convertRequestNodeFromBackToFront backRequestNode =
            case backRequestNode of
                Back.RequestFolder folder ->
                    Front.RequestFolder
                        { id = folder.requestNodeId
                        , name = NotEdited folder.requestNodeName
                        , open = not <| List.isEmpty folder.requestNodeChildren
                        , children = convertRequestNodesFromBackToFront folder.requestNodeChildren
                        }

                Back.RequestFile file ->
                    Front.RequestFile
                        { id = file.requestNodeId
                        , name = NotEdited file.requestNodeName
                        , httpUrl = NotEdited file.requestNodeHttpUrl
                        , httpMethod = NotEdited (convertMethodFromBackToFront file.requestNodeHttpMethod)
                        , httpHeaders = NotEdited file.requestNodeHttpHeaders
                        , httpBody = NotEdited file.requestNodeHttpBody
                        , requestComputationResult = Nothing
                        , showResponseView = False
                        , whichResponseView = BodyResponseView
                        , runRequestIconAnimation = Animation.style []
                        }
    in
    List.map convertRequestNodeFromBackToFront backRequestNodes



-- * pg Collection


convertPgCollectionFromBackToFront : Back.PgCollection -> Front.PgCollection
convertPgCollectionFromBackToFront backPgCollection =
    let
        (Back.PgCollection id backPgNodes) =
            backPgCollection
    in
    Front.PgCollection id (convertPgNodesFromBackToFront backPgNodes)


convertPgNodesFromBackToFront : List Back.PgNode -> List Front.PgNode
convertPgNodesFromBackToFront backPgNodes =
    let
        convertPgNodeFromBackToFront : Back.PgNode -> Front.PgNode
        convertPgNodeFromBackToFront backPgNode =
            case backPgNode of
                Back.PgFolder folder ->
                    Front.PgFolder
                        { id = folder.pgNodeId
                        , name = NotEdited folder.pgNodeName
                        , open = not <| List.isEmpty folder.pgNodeChildren
                        , children = convertPgNodesFromBackToFront folder.pgNodeChildren
                        }

                Back.PgFile file ->
                    Front.PgFile
                        { id = file.pgNodeId
                        , name = NotEdited file.pgNodeName
                        , sql = NotEdited file.pgNodeSql
                        , pgComputation = Nothing
                        , showResponseView = False
                        }
    in
    List.map convertPgNodeFromBackToFront backPgNodes



-- * scenario collection


convertScenarioCollectionFromBackToFront : Back.ScenarioCollection -> Front.ScenarioCollection
convertScenarioCollectionFromBackToFront backScenarioCollection =
    let
        (Back.ScenarioCollection id backScenarioNodes) =
            backScenarioCollection
    in
    Front.ScenarioCollection id (convertScenarioNodesFromBackToFront backScenarioNodes)



-- ** scenarioNode


convertScenarioNodesFromBackToFront : List Back.ScenarioNode -> List Front.ScenarioNode
convertScenarioNodesFromBackToFront backScenarioNodes =
    let
        convertScenarioNodeFromBackToFront : Back.ScenarioNode -> Front.ScenarioNode
        convertScenarioNodeFromBackToFront backScenarioNode =
            case backScenarioNode of
                Back.ScenarioFolder folder ->
                    Front.ScenarioFolder
                        { id = folder.scenarioNodeId
                        , name = NotEdited folder.scenarioNodeName
                        , children = convertScenarioNodesFromBackToFront folder.scenarioNodeChildren
                        , open = not (List.isEmpty folder.scenarioNodeChildren)
                        }

                Back.ScenarioFile file ->
                    Front.ScenarioFile
                        { id = file.scenarioNodeId
                        , name = NotEdited file.scenarioNodeName
                        , scenes = List.map convertSceneFromBackToFront file.scenarioNodeScenes
                        , showDetailedSceneView = Nothing
                        , whichResponseView = BodyResponseView
                        , environmentId = NotEdited file.scenarioNodeEnvironmentId
                        }
    in
    List.map convertScenarioNodeFromBackToFront backScenarioNodes



-- ** scene


convertSceneFromBackToFront : Back.Scene -> Front.Scene
convertSceneFromBackToFront { sceneId, sceneRequestFileNodeId, scenePrescript, scenePostscript } =
    { id = sceneId
    , requestFileNodeId = sceneRequestFileNodeId
    , sceneComputation = Nothing
    , prescriptStr = NotEdited scenePrescript
    , prescriptAst = Ok []
    , postscriptStr = NotEdited scenePostscript
    , postscriptAst = Ok []
    }



-- * environment


convertEnvironmentFromBackToFront : Back.Environment -> Front.Environment
convertEnvironmentFromBackToFront { environmentId, environmentName, environmentKeyValues } =
    { id = environmentId
    , name = NotEdited environmentName
    , showRenameInput = False
    , keyValues = List.map convertEnvironmentKeyValueFromBackToFront environmentKeyValues
    }


-- * environment key values


convertEnvironmentKeyValueFromBackToFront : Back.KeyValue -> Front.Storable Front.NewKeyValue Front.KeyValue
convertEnvironmentKeyValueFromBackToFront { keyValueId, keyValueKey, keyValueValue } =
    Saved
        { id = keyValueId
        , key = keyValueKey
        , value = stringToTemplate keyValueValue
        }


convertEnvironmentKeyValueFromFrontToBack : Front.Storable Front.NewKeyValue Front.KeyValue -> Back.NewKeyValue
convertEnvironmentKeyValueFromFrontToBack storable =
    let
        templatedStringsToString : StringTemplate -> String
        templatedStringsToString templatedStrings =
            templatedStrings
                |> List.map templateAsString
                |> String.join ""
    in
    case storable of
        New { key, value } ->
            { newKeyValueKey = key
            , newKeyValueValue = templatedStringsToString value
            }

        Saved { key, value } ->
            { newKeyValueKey = key
            , newKeyValueValue = templatedStringsToString value
            }

        Edited2 _ { key, value } ->
            { newKeyValueKey = key
            , newKeyValueValue = templatedStringsToString value
            }




-- * account


convertSessionFromBackToFront : Back.Session -> Front.Session
convertSessionFromBackToFront backSession =
    case backSession of
        Back.VisitorSession { sessionAccountId, sessionCsrfToken } ->
            Front.Visitor
                { id = sessionAccountId
                , csrfToken = sessionCsrfToken
                , signInEmail = ""
                , signInPassword = ""
                , signInErrors = []
                , signUpEmail = ""
                , signUpError = Nothing
                , signUpMessage = Nothing
                }

        Back.SignedUserSession { sessionAccountId, sessionCsrfToken, sessionGithubEmail, sessionGithubAvatarUrl } ->
            Front.SignedUser
                { id = sessionAccountId
                , csrfToken = sessionCsrfToken
                , email = sessionGithubEmail
                , avatarUrl = sessionGithubAvatarUrl
                }



-- * request computation


convertRequestComputationResultFromBackToFront : Back.RequestComputationResult -> Front.RequestComputationResult
convertRequestComputationResultFromBackToFront backRequestComputationResult =
    case backRequestComputationResult of
        Ok requestComputationOutput ->
            Ok (convertRequestComputationOutputFromBackToFront requestComputationOutput)

        Err httpException ->
            Err (convertHttpExceptionFromBackToFront httpException)


-- ** request computation output


convertRequestComputationOutputFromBackToFront : Back.RequestComputationOutput -> Front.RequestComputationOutput
convertRequestComputationOutputFromBackToFront backRequestComputationOutput =
    { statusCode = backRequestComputationOutput.requestComputationOutputStatusCode
    , statusText = ""
    , headers = Dict.fromList <| List.map (Tuple.mapFirst String.toLower) backRequestComputationOutput.requestComputationOutputHeaders
    , body = backRequestComputationOutput.requestComputationOutputBody
    }

-- ** http exception


convertHttpExceptionFromBackToFront : Back.HttpException -> Front.HttpException
convertHttpExceptionFromBackToFront backHttpException =
    case backHttpException of
        Back.InvalidUrlException a b ->
            Front.InvalidUrlException a b

        Back.TooManyRedirects ->
            Front.TooManyRedirects

        Back.OverlongHeaders ->
            Front.OverlongHeaders

        Back.ResponseTimeout ->
            Front.ResponseTimeout

        Back.ConnectionTimeout ->
            Front.ConnectionTimeout

        Back.ConnectionFailure a ->
            Front.ConnectionFailure a

        Back.InvalidStatusLine ->
            Front.InvalidStatusLine

        Back.InvalidHeader ->
            Front.InvalidHeader

        Back.InvalidRequestHeader ->
            Front.InvalidRequestHeader

        Back.InternalException str ->
            Front.InternalException str

        Back.ProxyConnectException ->
            Front.ProxyConnectException

        Back.NoResponseDataReceived ->
            Front.NoResponseDataReceived

        Back.WrongRequestBodyStreamSize ->
            Front.WrongRequestBodyStreamSize

        Back.ResponseBodyTooShort ->
            Front.ResponseBodyTooShort

        Back.InvalidChunkHeaders ->
            Front.InvalidChunkHeaders

        Back.IncompleteHeaders ->
            Front.IncompleteHeaders

        Back.InvalidDestinationHost ->
            Front.InvalidDestinationHost

        Back.HttpZlibException ->
            Front.HttpZlibException

        Back.InvalidProxyEnvironmentVariable ->
            Front.InvalidProxyEnvironmentVariable

        Back.ConnectionClosed ->
            Front.ConnectionClosed

        Back.InvalidProxySettings ->
            Front.InvalidProxySettings

        Back.UnknownException ->
            Front.UnknownException


-- ** request computation input


convertRequestComputationInputFromFrontToBack : Front.RequestComputationInput -> Back.TemplatedRequestComputationInput
convertRequestComputationInputFromFrontToBack frontRequestInput =
    let
        convertHeader : (a -> b) -> (a, a) -> (b, b)
        convertHeader f (s1, s2) =
            (f s1, f s2)
    in
    { templatedRequestComputationInputMethod = convertMethodFromFrontToBack frontRequestInput.method
    , templatedRequestComputationInputHeaders = List.map (convertHeader convertStringTemplateFromFrontToBack) frontRequestInput.headers
    , templatedRequestComputationInputUrl = convertStringTemplateFromFrontToBack frontRequestInput.url
    , templatedRequestComputationInputBody = convertStringTemplateFromFrontToBack frontRequestInput.body
    }


-- ** http method


convertMethodFromBackToFront : Back.Method -> Front.HttpMethod
convertMethodFromBackToFront method =
    case method of
        Back.Get ->
            Front.HttpGet

        Back.Post ->
            Front.HttpPost

        Back.Put ->
            Front.HttpPut

        Back.Delete ->
            Front.HttpDelete

        Back.Patch ->
            Front.HttpPatch

        Back.Head ->
            Front.HttpHead

        Back.Options ->
            Front.HttpOptions


convertMethodFromFrontToBack : Front.HttpMethod -> Back.Method
convertMethodFromFrontToBack method =
    case method of
        Front.HttpGet ->
            Back.Get

        Front.HttpPost ->
            Back.Post

        Front.HttpPut ->
            Back.Put

        Front.HttpDelete ->
            Back.Delete

        Front.HttpPatch ->
            Back.Patch

        Front.HttpHead ->
            Back.Head

        Front.HttpOptions ->
            Back.Options


-- ** http scheme


convertSchemeFromFrontToBack : Front.Scheme -> Back.Scheme
convertSchemeFromFrontToBack scheme =
    case scheme of
        Front.Http ->
            Back.Http

        Front.Https ->
            Back.Https


-- * pg computation


convertPgComputationFromBackToFront : Back.PgComputation -> Front.PgComputation
convertPgComputationFromBackToFront backPgComputation =
    case backPgComputation of
        Back.PgError string ->
            Front.PgError string

        Back.PgCommandOK ->
            Front.PgCommandOK

        Back.PgTuplesOk columns ->
            Front.PgTuplesOk (List.map convertPgTableFromBackToFront columns)


-- ** column


convertPgTableFromBackToFront : Back.Column -> Front.Col
convertPgTableFromBackToFront backColumn =
    let
        (Back.Column columnName pgValues) = backColumn
    in
    Front.Col columnName (List.map convertPgValueFromBackToFront pgValues)


convertPgValueFromBackToFront : Back.PgValue -> Front.PgValue
convertPgValueFromBackToFront backPgValue =
    case backPgValue of
        Back.PgString str ->
            Front.PgString str

        Back.PgInt int ->
            Front.PgInt int

        Back.PgBool bool ->
            Front.PgBool bool

        Back.PgNull ->
            Front.PgNull


-- * string template


convertStringTemplateFromFrontToBack : Front.StringTemplate -> List Back.Template
convertStringTemplateFromFrontToBack stringTemplate =
    let
        convertTemplateFromFrontToBack : Front.Template -> Back.Template
        convertTemplateFromFrontToBack template =
            case template of
                Front.Sentence str ->
                    Back.Sentence str

                Front.Key str ->
                    Back.Key str
    in
    List.map convertTemplateFromFrontToBack stringTemplate


-- * scenario output


convertScenarioOutputFromBackToFront : Back.ScenarioOutput -> Front.ScenarioOutput
convertScenarioOutputFromBackToFront scenesOutput =
    let
        convertSceneOutputFromBackToFront : Back.SceneOutput -> Front.SceneOutput
        convertSceneOutputFromBackToFront backSceneOutput =
            { sceneId = backSceneOutput.outputSceneId
            , requestFileNodeId = backSceneOutput.outputSceneRequestFileNodeId
            , sceneComputation =
                 convertSceneComputationFromBackToFront backSceneOutput.outputSceneComputation
            }

        convertSceneComputationFromBackToFront : Back.SceneComputation -> Front.SceneComputation
        convertSceneComputationFromBackToFront backSceneComputation =
            case backSceneComputation of
               Back.SceneNotRun ->
                   Front.SceneNotRun

               Back.PrescriptFailed scriptException ->
                   Front.PrescriptFailed (convertScriptExceptionFromBackToFront scriptException)

               Back.RequestFailed httpException ->
                   Front.RequestFailed (convertHttpExceptionFromBackToFront httpException)

               Back.PostscriptFailed scriptException ->
                   Front.PostscriptFailed (convertScriptExceptionFromBackToFront scriptException)

               Back.SceneSucceeded requestComputationOutput ->
                   Front.SceneSucceeded (convertRequestComputationOutputFromBackToFront requestComputationOutput)

    in
    List.map convertSceneOutputFromBackToFront scenesOutput


-- * script exception


convertScriptExceptionFromBackToFront : Back.ScriptException -> Front.ScriptException
convertScriptExceptionFromBackToFront backScriptException =
    case backScriptException of
        Back.UnknownVariable expr ->
            Front.UnknownVariable (convertExpressionFromBackToFront expr)

        Back.AssertEqualFailed expr1 expr2 ->
            Front.AssertEqualFailed (convertExpressionFromBackToFront expr1) (convertExpressionFromBackToFront expr2)


-- * tangoscript


convertTangoscriptFromFrontToBack : Front.TangoAst -> Back.TangoAst
convertTangoscriptFromFrontToBack frontTangoAst =
    List.map convertProcFromFrontToBack frontTangoAst


-- ** proc


convertProcFromFrontToBack : Front.Proc -> Back.Proc
convertProcFromFrontToBack frontProc =
    case frontProc of
        Front.AssertEqual expr1 expr2 -> Back.AssertEqual (convertExpressionFromFrontToBack expr1) (convertExpressionFromFrontToBack expr2)
        Front.Let str expr -> Back.Let str (convertExpressionFromFrontToBack expr)
        Front.Set str expr -> Back.Set str (convertExpressionFromFrontToBack expr)


-- ** ex


convertExpressionFromBackToFront : Back.Expr -> Front.Expr
convertExpressionFromBackToFront backEx =
    case backEx of
        Back.LBool x -> Front.LBool x
        Back.LInt x -> Front.LInt x
        Back.LString x -> Front.LString x
        Back.Var x -> Front.Var x
        Back.Fetch x -> Front.Fetch x
        Back.Eq a b -> Front.Eq (convertExpressionFromBackToFront a) (convertExpressionFromBackToFront b)
        Back.Add a b -> Front.Add (convertExpressionFromBackToFront a) (convertExpressionFromBackToFront b)
        Back.HttpResponseBodyAsString -> Front.HttpResponseBodyAsString
        Back.HttpResponseStatus -> Front.HttpResponseStatus

convertExpressionFromFrontToBack : Front.Expr -> Back.Expr
convertExpressionFromFrontToBack frontExpr =
    case frontExpr of
        Front.LBool x -> Back.LBool x
        Front.LInt x -> Back.LInt x
        Front.LString x -> Back.LString x
        Front.Var x -> Back.Var x
        Front.Fetch x -> Back.Fetch x
        Front.Eq a b -> Back.Eq (convertExpressionFromFrontToBack a) (convertExpressionFromFrontToBack b)
        Front.HttpResponseBodyAsString -> Back.HttpResponseBodyAsString
        Front.Add a b -> Back.Add (convertExpressionFromFrontToBack a) (convertExpressionFromFrontToBack b)
        Front.HttpResponseStatus -> Back.HttpResponseStatus
