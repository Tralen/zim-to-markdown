module ZimToMarkdown.Converter
    ( convertPage
    ) where

import ZimToMarkdown.Domain (MarkdownDocument (..), ZimPage (..))

-- | Converts a Zim page into Markdown.
--
-- The scaffold currently preserves the page content unchanged; markup rules
-- will replace this pass-through implementation incrementally.
convertPage :: ZimPage -> MarkdownDocument
convertPage (ZimPage content) = MarkdownDocument content
