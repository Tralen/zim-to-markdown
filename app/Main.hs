module Main
    ( main
    ) where

import Control.Exception (Exception, IOException, displayException, try)
import qualified Data.ByteString as ByteString
import Data.Text (Text)
import qualified Data.Text as Text
import qualified Data.Text.Encoding as TextEncoding
import qualified Data.Text.IO as TextIO
import System.Environment (getArgs)
import System.Exit (exitFailure)
import System.IO (stderr)

import ZimToMarkdown.Converter (convertPage)
import ZimToMarkdown.Domain (MarkdownDocument (..), ZimPage (..))
import ZimToMarkdown.Options
    ( ConversionRequest (..)
    , InputPath (..)
    , Options (..)
    , OutputPath (..)
    , helpText
    , parseOptions
    , renderOptionsError
    )
import ZimToMarkdown.Version (versionText)

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
    readResult <- readZimPage (conversionInput request)
    case readResult of
        Left message -> failWith message
        Right page -> do
            let document = convertPage page
            case conversionOutput request of
                Nothing -> TextIO.putStr (unMarkdownDocument document)
                Just outputPath ->
                    writeMarkdown outputPath document >>= either failWith pure

readZimPage :: InputPath -> IO (Either Text ZimPage)
readZimPage (InputPath path) = do
    readResult <- try (ByteString.readFile path) :: IO (Either IOException ByteString.ByteString)
    pure $
        case readResult of
            Left exception -> Left (renderFileError path exception)
            Right bytes ->
                case TextEncoding.decodeUtf8' bytes of
                    Left exception -> Left (renderFileError path exception)
                    Right content -> Right (ZimPage content)

writeMarkdown :: OutputPath -> MarkdownDocument -> IO (Either Text ())
writeMarkdown (OutputPath path) (MarkdownDocument content) = do
    writeResult <-
        try (ByteString.writeFile path (TextEncoding.encodeUtf8 content))
            :: IO (Either IOException ())
    pure (either (Left . renderFileError path) Right writeResult)

renderFileError :: Exception exception => FilePath -> exception -> Text
renderFileError path exception =
    Text.pack path <> ": " <> Text.pack (displayException exception)

failWith :: Text -> IO value
failWith message = do
    TextIO.hPutStrLn stderr message
    exitFailure
