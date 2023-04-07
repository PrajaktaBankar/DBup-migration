use SLCProject;
--Execute on server 3
--Customer Support 34430: Links Did Not Save Properly and are Missing - Duplicate Link Error Message


  DECLARE @CustomerId int=105
  DECLARE @Count1 int=0
  DECLARE @Count2 int=0
  DECLARE @Count3 int=0

  DROP table if exists #duplicateProjectSegmentChoice
  DROP TABLE IF EXISTS #DeleteRecordCount

  CREATE Table #DeleteRecordCount(
  ProjectId int,
  CustomerId int,
  Count1 nvarchar(10),
  Count2 nvarchar(10),
  Count3 nvarchar(10),
  DeleteJson nvarchar(500),
  SectionId int
  )
  
  SELECT SegmentChoiceId	
  ,SectionId	,SegmentStatusId	
  ,SegmentId	 	,ProjectId	
  ,CustomerId	,SegmentChoiceSource	,
  SegmentChoiceCode  into #duplicateProjectSegmentChoice FROM(
  SELECT * ,
  ROW_NUMBER()OVER (PARTITION BY SectionId,SegmentId,ProjectId,CustomerId,SegmentChoiceCode ORDER BY SegmentChoiceCode ,isnull(isdeleted,0) Asc)as row_no
  FROM ProjectSegmentChoice with(nolock) WHERE SegmentChoiceSource='U'  and CustomerId=@CustomerId
  )A WHERE A.row_no>1
   
  --Filter duplicate data in ProjectChoiceOption
  DROP table if exists #duplicateProjectChoiceOption
  
  select PCO.* into #duplicateProjectChoiceOption from ProjectChoiceOption PCO with(nolock) inner join
  #duplicateProjectSegmentChoice DPSC  on
  DPSC.ProjectId=PCO.ProjectId and DPSC.SectionId=PCO.SectionId
  and DPSC.CustomerId =PCO.CustomerId
  where PCO.SegmentChoiceId=DPSC.SegmentChoiceId
  and PCO.ChoiceOptionSource=DPSC.SegmentChoiceSource

  ---Filter duplicate data in SelectedChoiceOption
   DROP TABLE IF EXISTS #duplicateSelectedChoiceOption
   SELECT  * INTO #duplicateSelectedChoiceOption  FROM (
   SELECT DISTINCT SCO.*,
   ROW_NUMBER()OVER(PARTITION by SCO.ChoiceOptionCode,SCO.ProjectId,SCO.SectionId,SCO.CustomerId 
   ,SCO.SegmentChoiceCode,DPSC.SegmentStatusId,DPSC.SegmentId order By SCO.SelectedChoiceOptionId)as RowNo
   FROM   #duplicateProjectSegmentChoice DPSC   
   INNER JOIN #duplicateProjectChoiceOption DPCO ON
    DPSC.ProjectId=DPCO.ProjectId AND DPSC.SectionId=DPCO.SectionId AND
    DPCO.SegmentChoiceId=DPSC.SegmentChoiceId
   AND DPCO.ChoiceOptionSource=DPSC.SegmentChoiceSource
   AND DPSC.CustomerId =DPCO.CustomerId    INNER JOIN
    SelectedChoiceOption SCO WITH(NOLOCK) on
    SCO.ChoiceOptionCode=DPCO.ChoiceOptionCode AND
   SCO.ProjectId=DPCO.ProjectId AND SCO.SectionId=DPCO.SectionId AND
   SCO.CustomerId=DPCO.CustomerId AND SCO.ChoiceOptionSource=DPCO.ChoiceOptionSource
   AND SCO.SegmentChoiceCode=DPSC.SegmentChoiceCode
   )as A WHERE A.RowNo>1	

 -- delete dupluicate data from SelectedChoiceOption

  DELETE SCO from SelectedChoiceOption SCO inner join
  #duplicateSelectedChoiceOption DSCO on
  SCO.ChoiceOptionCode=DSCO.ChoiceOptionCode and SCO.SelectedChoiceOptionId=DSCO.SelectedChoiceOptionId 
  and SCO.ProjectId=DSCO.ProjectId and SCO.SectionId=DSCO.SectionId and SCO.CustomerId=DSCO.CustomerId
  and SCO.SegmentChoiceCode=DSCO.SegmentChoiceCode
  where SCO.ChoiceOptionSource='U'
   AND SCO.CustomerId=@CustomerId
-- delete dupluicate data from ProjectChoiceOption
 

   DELETE PCO from ProjectChoiceOption PCO inner join #duplicateProjectChoiceOption DPCO
   on PCO.ChoiceOptionId=DPCO.ChoiceOptionId and PCO.SegmentChoiceId=DPCO.SegmentChoiceId
   and PCO.ChoiceOptionCode=DPCO.ChoiceOptionCode and PCO.ProjectId=DPCO.ProjectId AND
   PCO.SectionId=DPCO.SectionId AND PCO.CustomerId=DPCO.CustomerId
   where PCO.ChoiceOptionSource='U'
   AND PCO.CustomerId=@CustomerId
   
----delete duplicate data from ProjectSegmentChoice
 
   DELETE PSC from ProjectSegmentChoice PSC inner join
   #duplicateProjectSegmentChoice DPSC on
   PSC.SegmentChoiceId=DPSC.SegmentChoiceId and PSC.SectionId=DPSC.SectionId and
   ISNULL(PSC.SegmentStatusId,0)=ISNULL(DPSC.SegmentStatusId,0) and PSC.SegmentId=DPSC.SegmentId
   and PSC.SegmentChoiceCode=DPSC.SegmentChoiceCode and PSC.ProjectId=DPSC.ProjectId
   and PSC.CustomerId=DPSC.CustomerId
   where PSC.SegmentChoiceSource='U'
   AND PSC.CustomerId=@CustomerId;
    