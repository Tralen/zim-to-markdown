-- | Command line parsing and usage messages.
module ZimToMarkdown.Options (
    ConversionRequest (..),
    InputPath (..),
    Options (..),
    OptionsError (..),
    OutputPath (..),
    helpText,
    parseOptions,
    renderOptionsError,
) where

import Data.Text (Text)
import Data.Text qualified as Text
import System.FilePath (FilePath)

import ZimToMarkdown.Domain (ConversionDirection (..))

-- | Path of the Zim page or notebook to read.
newtype InputPath = InputPath
    { unInputPath :: FilePath
    }
    deriving (Eq, Show)

-- | Path where the Markdown document or notebook is written.
newtype OutputPath = OutputPath
    { unOutputPath :: FilePath
    }
    deriving (Eq, Show)

-- | A conversion requested from the command line.
data ConversionRequest = ConversionRequest
    { conversionInput :: InputPath
    , conversionOutput :: Maybe OutputPath
    , conversionDirection :: ConversionDirection
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
    | InvalidDirection Text
    deriving (Eq, Show)

-- | Parses command line arguments without performing any input or output.
parseOptions :: [String] -> Either OptionsError Options
parseOptions arguments
    | any (`elem` ["-h", "--help"]) arguments = Right ShowHelp
    | any (`elem` ["-V", "--version"]) arguments = Right ShowVersion
    | otherwise = Convert <$> parseConversion arguments

data PartialOptions = PartialOptions
    { partialInput :: Maybe FilePath
    , partialOutput :: Maybe FilePath
    , partialDirection :: ConversionDirection
    }

emptyOptions :: PartialOptions
emptyOptions =
    PartialOptions
        { partialInput = Nothing
        , partialOutput = Nothing
        , partialDirection = ZimToMarkdown
        }

parseConversion :: [String] -> Either OptionsError ConversionRequest
parseConversion = go emptyOptions
  where
    go options [] =
        case partialInput options of
            Nothing -> Left MissingInput
            Just path ->
                Right
                    ConversionRequest
                        { conversionInput = InputPath path
                        , conversionOutput = OutputPath <$> partialOutput options
                        , conversionDirection = partialDirection options
                        }
    go _ ["--output"] = Left (MissingOptionValue "--output")
    go _ ["-o"] = Left (MissingOptionValue "-o")
    go _ ["--direction"] = Left (MissingOptionValue "--direction")
    go _ ["-d"] = Left (MissingOptionValue "-d")
    go options ("--output" : value : rest) =
        go options{partialOutput = Just value} rest
    go options ("-o" : value : rest) =
        go options{partialOutput = Just value} rest
    go options ("--direction" : value : rest) =
        setDirection options value rest
    go options ("-d" : value : rest) =
        setDirection options value rest
    go options (argument : rest)
        | isOption argument = Left (UnknownOption (Text.pack argument))
        | otherwise =
            case partialInput options of
                Nothing ->
                    go options{partialInput = Just argument} rest
                Just _ -> Left (UnexpectedArgument (Text.pack argument))

    setDirection options value rest =
        case parseDirection value of
            Nothing -> Left (InvalidDirection (Text.pack value))
            Just direction ->
                go options{partialDirection = direction} rest

    isOption ('-' : _) = True
    isOption _ = False

parseDirection :: String -> Maybe ConversionDirection
parseDirection value =
    case value of
        "zim-to-markdown" -> Just ZimToMarkdown
        "markdown-to-zim" -> Just MarkdownToZim
        _ -> Nothing

-- | Renders an option parsing failure as a user facing message.
renderOptionsError :: OptionsError -> Text
renderOptionsError optionsError =
    case optionsError of
        MissingInput -> "Missing input file or directory."
        UnknownOption option -> "Unknown option: " <> option
        MissingOptionValue option -> "Missing value for option: " <> option
        UnexpectedArgument argument -> "Unexpected argument: " <> argument
        InvalidDirection direction ->
            "Invalid direction: "
                <> direction
                <> ". Use zim-to-markdown or markdown-to-zim."

-- | Command line usage description.
helpText :: Text
helpText =
    Text.unlines
        [ "zim-to-markdown - converts between Zim wiki and Markdown."
        , ""
        , "Usage:"
        , "  zim-to-markdown [--direction DIRECTION] [--output PATH] INPUT"
        , "  zim-to-markdown --help"
        , "  zim-to-markdown --version"
        , ""
        , "Options:"
        , "  -d, --direction DIRECTION  zim-to-markdown (default) or markdown-to-zim."
        , "  -o, --output PATH          Output file for a page; output directory for a notebook."
        , "  -h, --help                 Show this help."
        , "  -V, --version              Show the application version."
        , ""
        , "A notebook is a directory, or a path to its notebook.zim file. Its"
        , "page files are converted and its other files are copied, preserving"
        , "the folder structure. Hidden files and symbolic links are skipped."
        ]
