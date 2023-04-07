--EXECUTE on server 2 
--Customer Support 31136: CH# on word and PDF export only - 29449 Steve Oliver with Powers Brown Architecture Holdings, Inc. - 29449

DECLARE @CustomerId INT=1663;

 CREATE  TABLE #tempProjectId1 (ProjectId INT,RowNo INT)
 ---insert customer projectId in #tempProjectId table
INSERT INTO #tempProjectId1 (ProjectId, RowNo)
	SELECT
		ProjectId
	   ,ROW_NUMBER() OVER (PARTITION BY CustomerId ORDER BY CustomerId) AS RowNo
	FROM project WITH (NOLOCK)
	WHERE CustomerId = @CustomerId
	AND ISNULL(IsPermanentDeleted, 0) = 0

DECLARE @ProjectRowCount INT=( SELECT
		COUNT(ProjectId)
	FROM #tempProjectId1)

WHILE (@ProjectRowCount >0)
BEGIN

DECLARE @ProjectId_1 INT = ( SELECT
		ProjectId
	FROM #tempProjectId1
	WHERE RowNo = @ProjectRowCount);

--insert into temp table from selectedChoiceOption 
SELECT
	* INTO #temp
FROM SelectedChoiceOption WITH (NOLOCK)
WHERE ProjectId IN (@ProjectId_1)
AND isdeleted = 1

--SELECT * from #temp

--select data from ProjectChoiceOption and ProjectSegmentChoice where isdeleted=0 and insert into #selectedchoicetemp
SELECT
	t.* INTO #selectedchoicetemp
FROM ProjectChoiceOption pco WITH (NOLOCK)
INNER JOIN #temp t
	ON t.ProjectId = pco.ProjectId
		AND t.CustomerId = pco.CustomerId
		AND t.SectionId = pco.SectionId
		AND t.ChoiceOptionCode = pco.ChoiceOptionCode
INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)
	ON pco.ProjectId = psc.ProjectId
		AND pco.CustomerId = psc.CustomerId
		AND pco.SectionId = psc.SectionId
		AND pco.SegmentChoiceId = psc.SegmentChoiceId
WHERE pco.IsDeleted = 0
AND psc.IsDeleted = 0
AND psc.ProjectId IN (@ProjectId_1)
AND psc.SegmentChoiceSource='U'
AND pco.ChoiceOptionSource='U'
ORDER BY t.ProjectId


DELETE A FROM(
SELECT * 
,ROW_NUMBER()OVER(PARTITION BY SegmentChoiceId	,SortOrder		
	,ProjectId	,SectionId	,CustomerId	,ChoiceOptionCode ORDER by ChoiceOptionId ASC) AS row_no
FROM ProjectChoiceOption  WHERE CustomerId=@CustomerId  and ProjectId=@ProjectId_1
)as A WHERE A.row_no>1

DELETE A FROM(
SELECT * 
,ROW_NUMBER()OVER(PARTITION BY  		
	 ProjectId	,SectionId	,CustomerId	,ChoiceOptionCode ORDER by SelectedChoiceOptionId ASC) AS row_no
FROM SelectedChoiceOption  WHERE CustomerId=@CustomerId  and ChoiceOptionSource='U' and ProjectId=@ProjectId_1
)as A WHERE A.row_no>1 


 INSERT INTO SelectedChoiceOption
 SELECT psc.SegmentChoiceCode,	slcmsco.ChoiceOptionCode,	pco.ChoiceOptionSource	,slcmsco.IsSelected	,psc.SectionId	,psc.ProjectId	,psc.CustomerId	,null as OptionJson,0 as	IsDeleted
 FROM ProjectSegmentChoice psc WITH(NOLOCK) INNER JOIN 
 ProjectChoiceOption pco WITH(NOLOCK) ON
 pco.ProjectId=psc.ProjectId AND pco.SectionId=psc.SectionId AND pco.CustomerId=psc.CustomerId 
 AND pco.SegmentChoiceId=psc.SegmentChoiceId
 INNER JOIN SLCMaster..SegmentChoice slcmsc WITH(NOLOCK) ON slcmsc.SegmentChoiceCode=psc.SegmentChoiceCode
 INNER JOIN SLCMaster..ChoiceOption slcmco WITH(NOLOCK) ON slcmco.SegmentChoiceId=slcmsc.SegmentChoiceId 
 AND pco.ChoiceOptionCode=slcmco.ChoiceOptionCode
 LEFT OUTER JOIN SelectedChoiceOption sco WITH(NOLOCK) ON sco.ProjectId=pco.ProjectId AND pco.SectionId=sco.SectionId
 AND pco.CustomerId=sco.CustomerId AND pco.ChoiceOptionCode=sco.ChoiceOptionCode
 AND sco.SegmentChoiceCode=psc.SegmentChoiceCode  AND sco.ChoiceOptionSource='U'
 INNER JOIN SLCMaster..SelectedChoiceOption slcmsco WITH(NOLOCK) ON slcmsco.ChoiceOptionCode=slcmco.ChoiceOptionCode AND slcmsco.SegmentChoiceCode=slcmsc.SegmentChoiceCode
 WHERE sco.ChoiceOptionCode IS NULL AND sco.SegmentChoiceCode IS NULL
 AND psc.CustomerId=@CustomerId and pco.ProjectId=@ProjectId_1

--(62 rows should affected) 
UPDATE B
SET IsDeleted = 0
FROM (SELECT
		SCO.*
	FROM SelectedChoiceOption SCO WITH (NOLOCK)
	INNER JOIN #selectedchoicetemp SCT
		ON SCT.SelectedChoiceOptionId = SCO.SelectedChoiceOptionId and SCO.ChoiceOptionSource='U'
	WHERE SCT.ProjectId IN (@ProjectId_1)) B

DROP TABLE IF EXISTS #temp
DROP TABLE IF EXISTS #selectedchoicetemp

SET @ProjectRowCount = @ProjectRowCount - 1;

END

DROP TABLE IF EXISTS #tempProjectId



	INSERT INTO ProjectSegmentChoice	
  SELECT   		
  5952943 as SectionId	,243744944 as SegmentStatusId	,39713384 as SegmentId	,ChoiceTypeId	,4941 as ProjectId	, 1663 as CustomerId	,'U' as SegmentChoiceSource	
  ,10012561 as SegmentChoiceCode	,12489 as CreatedBy	,CreateDate	,12489 as ModifiedBy	,ModifiedDate	,null as SLE_DocID	,null as SLE_SegmentID	
  ,null as SLE_StatusID	,null as SLE_ChoiceNo	,null as SLE_ChoiceTypeID	,null as A_SegmentChoiceId	,0 as IsDeleted
  from SLCMaster_SqlSlcOp002..SegmentChoice 
  WHERE SegmentChoiceCode=45338

  DECLARE @SegmentChoiceId int=(select SegmentChoiceId from ProjectSegmentChoice WHERE
 SectionId= 5952943  	and SegmentStatusId =243744944 and    SegmentId=39713384 AND	   ProjectId=4941 and	 CustomerId= 1663  and 
 SegmentChoiceCode=10012561	
   )

   INSERT ProjectChoiceOption
  SELECT 
  @SegmentChoiceId as SegmentChoiceId	,
  SortOrder	,
  'U'as ChoiceOptionSource	, OptionJson	,4941 as ProjectId	,5952943 as SectionId,1663 as	CustomerId	,
  ChoiceOptionCode	, 12489 as CreatedBy	,CreateDate	,12489 as ModifiedBy	,ModifiedDate	, null as A_ChoiceOptionId	,0 as IsDeleted 
  from SLCMaster..ChoiceOption   
   WHERE SegmentChoiceId =45338

   INSERT INTO SelectedChoiceOption
   SELECT 10012561 as  SegmentChoiceCode	,ChoiceOptionCode	,'U' as ChoiceOptionSource	,IsSelected	,5952943 as SectionId	,4941 as ProjectId	,
	 1663 as	CustomerId	,null as OptionJson	,0 as IsDeleted FROM SLCMaster..SelectedChoiceOption
	  WHERE  SegmentChoiceCode=45338
     
	 
 
