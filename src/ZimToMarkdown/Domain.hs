-- | Core immutable types used by the converter.
module ZimToMarkdown.Domain
    ( ConversionDirection (..)
    , MarkdownDocument (..)
    , RelativePath (..)
    , ZimPage (..)
    ) where

import Data.Text (Text)
import System.FilePath (FilePath)

-- | The direction in which a document is converted.
data ConversionDirection
    = ZimToMarkdown
    | MarkdownToZim
    deriving (Eq, Show)

-- | A page read from a Zim wiki notebook, still containing Zim markup.
newtype ZimPage = ZimPage
    { unZimPage :: Text
    }
    deriving (Eq, Show)

-- | A document rendered as Markdown.
newtype MarkdownDocument = MarkdownDocument
    { unMarkdownDocument :: Text
    }
    deriving (Eq, Show)

-- | A path relative to the root of a notebook.
newtype RelativePath = RelativePath
    { unRelativePath :: FilePath
    }
    deriving (Eq, Ord, Show)
