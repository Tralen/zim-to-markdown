module ZimToMarkdown.Notebook
    ( NotebookItem (..)
    , classifyNotebookItems
    , outputRelativePath
    , pageRelativePaths
    , sourcePageExtensions
    ) where

import Data.Char (toLower)
import qualified Data.Set as Set
import System.FilePath (replaceExtension, takeExtension)

import ZimToMarkdown.Domain (ConversionDirection (..), RelativePath (..))

-- | A file discovered inside a notebook.
data NotebookItem
    = PageItem RelativePath
    | AssetItem RelativePath
    deriving (Eq, Show)

-- | Splits discovered notebook files into pages and assets.
classifyNotebookItems :: ConversionDirection -> [RelativePath] -> [NotebookItem]
classifyNotebookItems direction =
    map
        (\path ->
            if isPagePath direction path
                then PageItem path
                else AssetItem path
        )

-- | Lists the source extensions that represent pages in a direction.
sourcePageExtensions :: ConversionDirection -> [String]
sourcePageExtensions ZimToMarkdown = [".txt"]
sourcePageExtensions MarkdownToZim = [".md", ".markdown"]

-- | Computes the destination path of a page while preserving its namespace.
outputRelativePath :: ConversionDirection -> RelativePath -> RelativePath
outputRelativePath direction (RelativePath path) =
    RelativePath (replaceExtension path (outputExtension direction))

-- | Collects every page path so links can be resolved across the notebook.
pageRelativePaths :: [NotebookItem] -> Set.Set RelativePath
pageRelativePaths items =
    Set.fromList [path | PageItem path <- items]

isPagePath :: ConversionDirection -> RelativePath -> Bool
isPagePath direction (RelativePath path) =
    map toLower (takeExtension path) `elem` sourcePageExtensions direction

outputExtension :: ConversionDirection -> String
outputExtension ZimToMarkdown = ".md"
outputExtension MarkdownToZim = ".txt"
