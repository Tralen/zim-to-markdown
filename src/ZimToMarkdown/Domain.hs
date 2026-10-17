module ZimToMarkdown.Domain
    ( ZimPage (..)
    , MarkdownDocument (..)
    ) where

import Data.Text (Text)

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
