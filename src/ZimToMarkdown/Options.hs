module ZimToMarkdown.Options
    ( ConversionRequest (..)
    , InputPath (..)
    , Options (..)
    , OptionsError (..)
    , OutputPath (..)
    , helpText
    , parseOptions
    , renderOptionsError
    ) where

import Data.Text (Text)
import qualified Data.Text as Text
import System.FilePath (FilePath)

-- | Path of the Zim page to read.
newtype InputPath = InputPath
    { unInputPath :: FilePath
    }
    deriving (Eq, Show)

-- | Path where the Markdown document is written.
newtype OutputPath = OutputPath
    { unOutputPath :: FilePath
    }
    deriving (Eq, Show)

-- | A conversion requested from the command line.
data ConversionRequest = ConversionRequest
    { conversionInput :: InputPath
    , conversionOutput :: Maybe OutputPath
    }
    deriving (Eq, Show)

-- | A command line action.
data Options
    = ShowHelp
    | ShowVersion
    | Convert ConversionRequest
    deriving (Eq, Show)

-- | A failure produced while interpreting the command line.
data OptionsError
    = MissingInput
    | UnknownOption Text
    | MissingOptionValue Text
    | UnexpectedArgument Text
    deriving (Eq, Show)

-- | Parses command line arguments without performing any input or output.
parseOptions :: [String] -> Either OptionsError Options
parseOptions arguments
    | any (`elem` ["-h", "--help"]) arguments = Right ShowHelp
    | any (`elem` ["-V", "--version"]) arguments = Right ShowVersion
    | otherwise = Convert <$> parseConversion arguments

parseConversion :: [String] -> Either OptionsError ConversionRequest
parseConversion = go Nothing Nothing
  where
    go input output [] =
        case input of
            Nothing -> Left MissingInput
            Just path ->
                Right
                    ConversionRequest
                        { conversionInput = InputPath path
                        , conversionOutput = OutputPath <$> output
                        }
    go _ _ ["--output"] = Left (MissingOptionValue "--output")
    go _ _ ["-o"] = Left (MissingOptionValue "-o")
    go input output ("--output" : value : rest) = go input (Just value) rest
    go input output ("-o" : value : rest) = go input (Just value) rest
    go input output (argument : rest)
        | isOption argument = Left (UnknownOption (Text.pack argument))
        | otherwise =
            case input of
                Nothing -> go (Just argument) output rest
                Just _ -> Left (UnexpectedArgument (Text.pack argument))

    isOption ('-' : _) = True
    isOption _ = False

-- | Renders an option parsing failure as a user facing message.
renderOptionsError :: OptionsError -> Text
renderOptionsError optionsError =
    case optionsError of
        MissingInput -> "Missing input file."
        UnknownOption option -> "Unknown option: " <> option
        MissingOptionValue option -> "Missing value for option: " <> option
        UnexpectedArgument argument -> "Unexpected argument: " <> argument

-- | Command line usage description.
helpText :: Text
helpText =
    Text.unlines
        [ "zim-to-markdown - converts Zim wiki pages to Markdown."
        , ""
        , "Usage:"
        , "  zim-to-markdown [--output FILE] INPUT"
        , "  zim-to-markdown --help"
        , "  zim-to-markdown --version"
        , ""
        , "Options:"
        , "  -o, --output FILE  Write the result to FILE; defaults to stdout."
        , "  -h, --help         Show this help."
        , "  -V, --version      Show the application version."
        ]
