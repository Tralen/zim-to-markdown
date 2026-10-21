module ZimToMarkdown.Version
    ( Version (..)
    , appVersion
    , renderVersion
    , versionText
    ) where

import Data.Text (Text)
import qualified Data.Text as Text

-- | A four-component application version following the Package Version Policy.
data Version = Version
    { versionMajor :: Int
    , versionMinor :: Int
    , versionPatch :: Int
    , versionRevision :: Int
    }
    deriving (Eq, Ord, Show)

-- | The current application version. Keep it in sync with the Cabal file.
appVersion :: Version
appVersion =
    Version
        { versionMajor = 0
        , versionMinor = 3
        , versionPatch = 0
        , versionRevision = 1
        }

-- | Renders a version as @major.minor.patch.revision@.
renderVersion :: Version -> Text
renderVersion version =
    Text.intercalate
        "."
        (map (Text.pack . show) components)
  where
    components =
        [ versionMajor version
        , versionMinor version
        , versionPatch version
        , versionRevision version
        ]

-- | The current version rendered for humans and command line output.
versionText :: Text
versionText = renderVersion appVersion
