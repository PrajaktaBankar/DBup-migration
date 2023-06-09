CREATE PROCEDURE [dbo].[usp_GetSectionReferencesCount]
@ProjectId INT NULL=NULL,  
@CustomerId INT NULL, 
@SectionId INT NULL
 
AS    
BEGIN
  
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PIsSupplementalDocAttached BIT;

SELECT
	SegmentChoiceId
   ,ChoiceOptionId
   ,SectionId
   --,JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.OptionTypeName') AS OptionTypeName  
   --,JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.Id') AS ReferSectionId  
   --,JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.Value') AS SectionName INTO #Temp  
   ,CASE WHEN ISJSON(OptionJson) !=0 AND OptionJson<>'[]' then JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.OptionTypeName') end  AS OptionTypeName  
   ,CASE WHEN ISJSON(OptionJson) !=0 AND OptionJson<>'[]' then JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.Id') end AS ReferSectionId  
   ,CASE WHEN ISJSON(OptionJson) !=0 AND OptionJson<>'[]' then JSON_VALUE(REPLACE(REPLACE(OptionJson, '[', ''), ']', ''), '$.Value') end AS SectionName INTO #Temp  
FROM ProjectChoiceOption WITH (NOLOCK)
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId

IF EXISTS(SELECT DocMappingId
                  FROM DocLibraryMapping WITH (NOLOCK)
                  WHERE CustomerId = @PCustomerId and ProjectId = @PProjectId and SectionId = @PSectionId and ISNULL(IsDeleted, 0) = 0)
BEGIN
	SET @PIsSupplementalDocAttached = 1
END
ELSE
BEGIN
    SET @PIsSupplementalDocAttached = 0
END

SELECT
	COUNT(1) AS SectionCount,
	@PIsSupplementalDocAttached AS IsSupplementalDocAttached
FROM (SELECT DISTINCT
		T.SectionId
	FROM #Temp T
	JOIN ProjectSegmentChoice PSC WITH (NOLOCK)
		ON T.SegmentChoiceId = PSC.SegmentChoiceId
	INNER JOIN ProjectSection ps WITH (NOLOCK)
		ON T.SectionId = ps.SectionID
	INNER JOIN SLCMaster..Section MS WITH (NOLOCK)
		ON ps.mSectionId = MS.SectionID
	WHERE PSC.IsDeleted = 0
	AND T.OptionTypeName LIKE '%SectionId%'
	AND T.ReferSectionId = @PSectionId
	AND T.ReferSectionId != PSC.SectionId
	AND MS.Isdeleted = 0) AS dt;

END


GO
