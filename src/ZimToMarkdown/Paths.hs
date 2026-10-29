-- | Relative path calculations shared by link resolution and the executable.
module ZimToMarkdown.Paths (
    relativePathFrom,
    relativePathTo,
    toPosixPath,
) where

import System.FilePath (isAbsolute, joinPath, normalise, splitDirectories, takeDrive)

{- | Computes the path of a target relative to a base directory, including
@..@ segments when the paths diverge.
-}
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

{- | Computes a relative target that may leave the base directory, returning
Nothing when the two paths share no relative root, such as different volumes.
-}
relativePathTo :: FilePath -> FilePath -> Maybe FilePath
relativePathTo from target
    | differentDrive = Nothing
    | isAbsolute relative = Nothing
    | otherwise = Just (toPosixPath relative)
  where
    normalFrom = normalise from
    normalTarget = normalise target
    fromDrive = takeDrive normalFrom
    targetDrive = takeDrive normalTarget
    differentDrive =
        not (null fromDrive) && fromDrive /= targetDrive
    relative = normalise (relativePathFrom normalFrom normalTarget)
