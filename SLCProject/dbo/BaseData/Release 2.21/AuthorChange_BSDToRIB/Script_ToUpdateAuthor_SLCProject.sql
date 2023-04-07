--USER STORY 70734 --Change BSD to RIB in author field- Changes to the Archive server

USE [SLCProject]
GO

UPDATE S SET S.Author = 'RIBXX' FROM SLCProject..ProjectSection S WITH (NOLOCK) WHERE mSectionId IS NOT NULL AND Author = 'BSDXX' AND IsLastLevel = 1
UPDATE S SET S.Author = 'RIB2' FROM SLCProject..ProjectSection S WITH (NOLOCK) WHERE mSectionId IS NOT NULL AND Author = 'BSD2' AND IsLastLevel = 1
UPDATE S SET S.Author = 'RIB' FROM SLCProject..ProjectSection S WITH (NOLOCK) WHERE mSectionId IS NOT NULL AND Author = 'BSD' AND IsLastLevel = 1


