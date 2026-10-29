module Main (
    main,
) where

import Control.Exception (Exception, IOException, displayException, try)
import Data.ByteString qualified as ByteString
import Data.List (sort)
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.Encoding qualified as TextEncoding
import Data.Text.IO qualified as TextIO
import System.Directory (
    copyFile,
    createDirectoryIfMissing,
    doesDirectoryExist,
    doesFileExist,
    getHomeDirectory,
    listDirectory,
    makeAbsolute,
    pathIsSymbolicLink,
 )
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.FilePath (
    isAbsolute,
    normalise,
    splitDirectories,
    takeBaseName,
    takeDirectory,
    takeExtension,
    takeFileName,
    (</>),
 )
import System.IO (stderr)

import ZimToMarkdown.Converter (
    convertMarkdownDocument,
    convertZimPageWithAssets,
 )
import ZimToMarkdown.Domain (
    ConversionDirection (..),
    MarkdownDocument (..),
    RelativePath (..),
    ZimPage (..),
 )
import ZimToMarkdown.Links (LinkContext (..))
import ZimToMarkdown.Notebook (
    NotebookItem (..),
    classifyNotebookItems,
    outputRelativePath,
    pageRelativePaths,
 )
import ZimToMarkdown.Options (
    ConversionRequest (..),
    InputPath (..),
    Options (..),
    OutputPath (..),
    helpText,
    parseOptions,
    renderOptionsError,
 )
import ZimToMarkdown.Paths (relativePathFrom)
import ZimToMarkdown.Version (versionText)
import ZimToMarkdown.Zim (zimImagePaths)

main :: IO ()
main = do
    arguments <- getArgs
    case parseOptions arguments of
        Left optionsError -> failWith (renderOptionsError optionsError)
        Right ShowHelp -> TextIO.putStr helpText
        Right ShowVersion -> TextIO.putStrLn versionText
        Right (Convert request) -> runConversion request

runConversion :: ConversionRequest -> IO ()
runConversion request = do
    let inputPath = unInputPath (conversionInput request)
    inputIsDirectory <- doesDirectoryExist inputPath
    inputIsFile <- doesFileExist inputPath
    if inputIsDirectory
        then runNotebookRoot request inputPath
        else
            if inputIsFile
                then
                    if isNotebookDefinition inputPath
                        then runNotebookRoot request (takeDirectory inputPath)
                        else runSingleFile request inputPath
                else
                    failWith
                        ("Input path does not exist: " <> Text.pack inputPath)

isNotebookDefinition :: FilePath -> Bool
isNotebookDefinition path = takeFileName path == "notebook.zim"

runSingleFile :: ConversionRequest -> FilePath -> IO ()
runSingleFile request inputPath = do
    readResult <- readUtf8File inputPath
    case readResult of
        Left message -> failWith message
        Right content -> do
            let sourcePath = RelativePath (takeFileName inputPath)
                context = LinkContext sourcePath (Set.singleton sourcePath)
                rendered =
                    convertContent
                        (conversionDirection request)
                        context
                        Map.empty
                        content
            case conversionOutput request of
                Nothing -> TextIO.putStr rendered
                Just outputPath -> do
                    outputIsDirectory <-
                        doesDirectoryExist (unOutputPath outputPath)
                    if outputIsDirectory
                        then
                            failWith
                                "For a single page, --output must be a file path."
                        else
                            writeUtf8File (unOutputPath outputPath) rendered
                                >>= either failWith pure

runNotebookRoot :: ConversionRequest -> FilePath -> IO ()
runNotebookRoot request inputRoot =
    case conversionOutput request of
        Nothing ->
            failWith
                "An output directory is required when converting a notebook."
        Just outputPath -> do
            let outputRoot = unOutputPath outputPath
            inputAbsolute <- makeAbsolute inputRoot
            outputAbsolute <- makeAbsolute outputRoot
            if isStrictlyInside inputAbsolute outputAbsolute
                then
                    failWith
                        "The output directory must not be inside the input directory."
                else do
                    discovered <- discoverFiles inputRoot
                    case discovered of
                        Left message -> failWith message
                        Right relativePaths -> do
                            home <- getHomeDirectory
                            let items =
                                    classifyNotebookItems
                                        (conversionDirection request)
                                        relativePaths
                                knownPages = pageRelativePaths items
                            convertNotebookItems
                                request
                                home
                                inputRoot
                                outputRoot
                                knownPages
                                items
                                >>= either failWith pure

convertNotebookItems ::
    ConversionRequest ->
    FilePath ->
    FilePath ->
    FilePath ->
    Set.Set RelativePath ->
    [NotebookItem] ->
    IO (Either Text ())
convertNotebookItems request home inputRoot outputRoot knownPages items = go Map.empty items
  where
    notebookAssets =
        Set.fromList [relative | AssetItem relative <- items]

    go _ [] = pure (Right ())
    go assetMap (item : rest) = do
        result <- processItem assetMap item
        case result of
            Left message -> pure (Left message)
            Right nextMap -> go nextMap rest

    processItem assetMap (PageItem sourceRelative) =
        convertPageItem assetMap sourceRelative
    processItem assetMap (AssetItem relative) = do
        copied <- copyAssetItem relative
        pure (assetMap <$ copied)

    convertPageItem assetMap sourceRelative = do
        let sourcePath = inputRoot </> unRelativePath sourceRelative
            destinationRelative =
                outputRelativePath
                    (conversionDirection request)
                    sourceRelative
            destinationPath =
                outputRoot </> unRelativePath destinationRelative
        readResult <- readUtf8File sourcePath
        case readResult of
            Left message -> pure (Left message)
            Right content -> do
                let externalImages =
                        case conversionDirection request of
                            ZimToMarkdown -> zimImagePaths (ZimPage content)
                            MarkdownToZim -> []
                copied <- copyExternalImages home outputRoot notebookAssets assetMap externalImages
                case copied of
                    Left message -> pure (Left message)
                    Right assetMap' -> do
                        let context =
                                LinkContext
                                    { linkCurrentPage = sourceRelative
                                    , linkKnownPages = knownPages
                                    }
                            rendered =
                                convertContent
                                    (conversionDirection request)
                                    context
                                    assetMap'
                                    content
                        written <- writeUtf8File destinationPath rendered
                        pure (assetMap' <$ written)

    copyAssetItem relative = do
        let sourcePath = inputRoot </> unRelativePath relative
            destinationPath = outputRoot </> unRelativePath relative
        copyAsset sourcePath destinationPath

{- | Copies images referenced outside the notebook, such as @~/pics/a.png@,
into the output @assets@ directory and records the rewritten target.
-}
copyExternalImages ::
    FilePath ->
    FilePath ->
    Set.Set RelativePath ->
    Map.Map Text RelativePath ->
    [Text] ->
    IO (Either Text (Map.Map Text RelativePath))
copyExternalImages home outputRoot reserved initialPaths = go (Right initialPaths)
  where
    go result [] = pure result
    go (Left message) (_ : _) = pure (Left message)
    go (Right assetMap) (path : rest)
        | Map.member path assetMap = go (Right assetMap) rest
        | otherwise =
            case resolveExternalImage home path of
                Nothing -> go (Right assetMap) rest
                Just source -> do
                    exists <- doesFileExist source
                    if exists
                        then do
                            let used =
                                    reserved
                                        <> Set.fromList (Map.elems assetMap)
                                destination =
                                    chooseAssetPath used (takeFileName source)
                                destinationPath =
                                    outputRoot </> unRelativePath destination
                            copied <- copyAsset source destinationPath
                            case copied of
                                Left message -> pure (Left message)
                                Right () ->
                                    go
                                        (Right (Map.insert path destination assetMap))
                                        rest
                        else go (Right assetMap) rest

resolveExternalImage :: FilePath -> Text -> Maybe FilePath
resolveExternalImage home path
    | Just rest <- Text.stripPrefix "~/" path =
        Just (home </> Text.unpack rest)
    | Text.isPrefixOf "~" path = Nothing
    | isAbsolute (Text.unpack path) = Just (Text.unpack path)
    | otherwise = Nothing

chooseAssetPath :: Set.Set RelativePath -> FilePath -> RelativePath
chooseAssetPath used = go 2
  where
    go attempt candidate =
        let relative = RelativePath ("assets" </> candidate)
         in if Set.member relative used
                then go (attempt + 1) (numbered attempt candidate)
                else relative
    numbered attempt candidate =
        takeBaseName candidate
            <> "-"
            <> show attempt
            <> takeExtension candidate

convertContent ::
    ConversionDirection ->
    LinkContext ->
    Map.Map Text RelativePath ->
    Text ->
    Text
convertContent direction context assets content =
    case direction of
        ZimToMarkdown ->
            unMarkdownDocument
                (convertZimPageWithAssets context assets (ZimPage content))
        MarkdownToZim ->
            unZimPage
                (convertMarkdownDocument (MarkdownDocument content))

discoverFiles :: FilePath -> IO (Either Text [RelativePath])
discoverFiles root = go ""
  where
    go relativeDirectory = do
        let directory =
                if null relativeDirectory
                    then root
                    else root </> relativeDirectory
        listed <-
            try (listDirectory directory) ::
                IO (Either IOException [FilePath])
        case listed of
            Left exception ->
                pure (Left (renderFileError directory exception))
            Right names -> do
                results <- mapM (visit relativeDirectory) (sort names)
                pure (fmap concat (sequence results))

    visit relativeDirectory name
        | isHidden name = pure (Right [])
        | otherwise = do
            let relativePath =
                    normalise
                        ( if null relativeDirectory
                            then name
                            else relativeDirectory </> name
                        )
                fullPath = root </> relativePath
            if relativePath == "notebook.zim"
                then pure (Right [])
                else do
                    symbolicResult <-
                        try (pathIsSymbolicLink fullPath) ::
                            IO (Either IOException Bool)
                    case symbolicResult of
                        Left exception ->
                            pure (Left (renderFileError fullPath exception))
                        Right True -> pure (Right [])
                        Right False -> do
                            isDirectory <- doesDirectoryExist fullPath
                            isFile <- doesFileExist fullPath
                            if isDirectory
                                then go relativePath
                                else
                                    if isFile
                                        then
                                            pure
                                                ( Right
                                                    [RelativePath relativePath]
                                                )
                                        else pure (Right [])

    isHidden ('.' : _) = True
    isHidden _ = False

isStrictlyInside :: FilePath -> FilePath -> Bool
isStrictlyInside parent child =
    let relative =
            normalise
                (relativePathFrom (normalise parent) (normalise child))
     in relative /= "."
            && relative /= ""
            && case splitDirectories relative of
                (".." : _) -> False
                _ -> True

readUtf8File :: FilePath -> IO (Either Text Text)
readUtf8File path = do
    readResult <-
        try (ByteString.readFile path) ::
            IO (Either IOException ByteString.ByteString)
    pure $
        case readResult of
            Left exception -> Left (renderFileError path exception)
            Right bytes ->
                case TextEncoding.decodeUtf8' bytes of
                    Left exception ->
                        Left (renderFileError path exception)
                    Right content -> Right content

writeUtf8File :: FilePath -> Text -> IO (Either Text ())
writeUtf8File path content = do
    let directory = takeDirectory path
    created <-
        try (createDirectoryIfMissing True directory) ::
            IO (Either IOException ())
    case created of
        Left exception ->
            pure (Left (renderFileError directory exception))
        Right () -> do
            written <-
                try
                    ( ByteString.writeFile
                        path
                        (TextEncoding.encodeUtf8 content)
                    ) ::
                    IO (Either IOException ())
            pure (either (Left . renderFileError path) Right written)

copyAsset :: FilePath -> FilePath -> IO (Either Text ())
copyAsset source destination = do
    let directory = takeDirectory destination
    created <-
        try (createDirectoryIfMissing True directory) ::
            IO (Either IOException ())
    case created of
        Left exception ->
            pure (Left (renderFileError directory exception))
        Right () -> do
            copied <-
                try (copyFile source destination) ::
                    IO (Either IOException ())
            pure (either (Left . renderFileError destination) Right copied)

renderFileError :: (Exception exception) => FilePath -> exception -> Text
renderFileError path exception =
    Text.pack path <> ": " <> Text.pack (displayException exception)

{- | The single process boundary for expected failures: reports the message on
stderr and exits with a nonzero status.
-}
failWith :: Text -> IO value
failWith message = do
    TextIO.hPutStrLn stderr message
    exitFailure
