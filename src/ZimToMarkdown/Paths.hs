module ZimToMarkdown.Paths
    ( relativePathFrom
    , toPosixPath
    ) where

import System.FilePath (joinPath, normalise, splitDirectories)

-- | Computes the path of a target relative to a base directory, including
-- @..@ segments when the paths diverge.
relativePathFrom :: FilePath -> FilePath -> FilePath
relativePathFrom from target =
    let (fromRest, targetRest) =
            dropCommon (pathParts from) (pathParts target)
        upwards = replicate (length fromRest) ".."
    in joinPath (upwards <> targetRest)

pathParts :: FilePath -> [FilePath]
pathParts path
    | path == "." || null path = []
    | otherwise = splitDirectories (normalise path)

dropCommon :: [FilePath] -> [FilePath] -> ([FilePath], [FilePath])
dropCommon (fromPart : fromRest) (targetPart : targetRest)
    | fromPart == targetPart = dropCommon fromRest targetRest
dropCommon fromRest targetRest = (fromRest, targetRest)

-- | Replaces Windows separators with the separators used in Markdown links.
toPosixPath :: FilePath -> FilePath
toPosixPath =
    map (\character -> if character == '\\' then '/' else character)
