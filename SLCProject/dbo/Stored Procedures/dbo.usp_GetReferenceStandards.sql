CREATE PROCEDURE [dbo].[usp_GetReferenceStandards]                 
(                          
  @ProjectId INT= NULL,                   
  @CustomerId INT =NULL,               
  @MasterDataTypeId INT =NULL              
)                      
AS                         
BEGIN              
DECLARE @PProjectId INT = @ProjectId;              
--DECLARE @PSectionId INT = @SectionId;              
DECLARE @PCustomerId INT = @CustomerId;              
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;              
              
--Set Nocount On                
SET NOCOUNT ON;              
--SET STATISTICS TIME ON;              
                
IF(@PMasterDataTypeId = 2 OR @PMasterDataTypeId=3)              
BEGIN              
SET @PMasterDataTypeId = 1              
END              
              
--FIND USED REF STD AND THEIR EDITIONS                  
SELECT              
 RefStandardId              
   ,RefStdEditionId              
   ,RefStdCode INTO #MappedRefStds              
FROM [dbo].ProjectReferenceStandard WITH(NOLOCK)              
WHERE ProjectId = @PProjectid              
AND CustomerId = @PCustomerId              
AND ISNULL(IsDeleted,0) = 0  
AND RefStdSource <> 'U'     -- CSI ID : 66638   
AND SectionId NOT IN (SELECT SectionId FROM ProjectSection WITH(NOLOCK) WHERE CustomerId = @PCustomerId AND ProjectId = @PProjectId AND ISNULL(IsDeleted, 0) = 1)  -- CSI 65719
              
--CREATE TABLE OF REF STD'S OF MASTER ONLY                  
              
SELECT MAX(RSE.RefStdEditionId) as RefStdEditionId,RSE.RefStdId              
INTo #RefStdTbl FROM [SLCMaster].dbo.ReferenceStandardEdition RSE WITH(NOLOCK) GROUP BY RSE.RefStdId              
              
SELECT MAX(RSE.RefStdEditionId) as RefStdEditionId,RSE.RefStdId              
INTo #RefStdProj FROM [dbo].ReferenceStandardEdition RSE WITH(NOLOCK) GROUP BY RSE.RefStdId              
              
--SELECT              
-- RS.RefStdId              
--   ,RefEdition.RefStdEditionId INTO #RefStdTbl              
--FROM [SLCMaster].dbo.ReferenceStandard RS (NOLOCK)              
--CROSS APPLY (SELECT TOP 1              
--  RSE.RefStdEditionId              
-- FROM [SLCMaster].dbo.ReferenceStandardEdition RSE (NOLOCK)              
-- WHERE RSE.RefStdId = RS.RefStdCode              
-- ORDER BY RSE.RefStdEditionId DESC) RefEdition              
              
----UPDATE EDITION ID ACCORDING TO APPLY UPDATE FUNCTIONALITY                  
UPDATE RefStd              
SET RefStd.RefStdEditionId = MREF.RefStdEditionId              
FROM #RefStdTbl RefStd WITH(NOLOCK)              
INNER JOIN #MappedRefStds MREF WITH(NOLOCK)              
 ON RefStd.RefStdId = MREF.RefStandardId              
INNER JOIN [SLCMaster].dbo.ReferenceStandard RS WITH(NOLOCK)              
    ON  MREF.RefStdCode=RS.RefStdCode                
              
              
DECLARE @MasterReferenceStandard TABLE              
(RefStdId int              
--,MasterDataTypeId int              
,RefStdName varchar(MAX)             
,ReplaceRefStdId int              
,IsObsolete bit              
,RefStdCode int              
--,CreateDate datetime2              
--,ModifiedDate datetime2              
--,PublicationDate datetime2              
,RefStdEditionId INT              
)              
              
DECLARE @MasterReferenceStandardEdition TABLE              
(RefStdEditionId int              
,RefStdId int              
,RefEdition varchar(150)              
,RefStdTitle varchar(1024)             
,LinkTarget varchar(1024)              
--,CreateDate datetime2              
--,ModifiedDate datetime2              
--,PublicationDate datetime2              
--,MasterDataTypeId int              
)              
              
DECLARE @ReferenceStandard TABLE              
(RefStdId int              
,RefStdName varchar(MAX)              
,RefStdSource char(1)              
,ReplaceRefStdId int              
,ReplaceRefStdSource char(1)              
,mReplaceRefStdId int              
,IsObsolete bit              
,RefStdCode int              
,CreateDate datetime2              
,CreatedBy int              
,ModifiedDate datetime2              
,ModifiedBy int              
,CustomerId int              
,IsDeleted bit              
,IsLocked bit              
,IsLockedByFullName nvarchar(255)              
,IsLockedById int              
,A_RefStdId int              
,RefStdEditionId INT              
)              
              
DECLARE @ReferenceStandardEdition TABLE              
(RefStdEditionId int              
,RefEdition varchar(255)              
,RefStdTitle varchar(1024)              
,LinkTarget varchar(1024)             
--,CreateDate datetime2              
--,CreatedBy int              
--,RefStdId int              
--,CustomerId int              
--,ModifiedDate datetime2              
--,ModifiedBy int              
--,A_RefStdEditionId int              
)              
              
insert into @MasterReferenceStandard              
select RS.RefStdId,RS.RefStdName,RS.ReplaceRefStdId,RS.IsObsolete,RS.RefStdCode              
,RefStd.RefStdEditionId from [SLCMaster].dbo.ReferenceStandard RS WITH (NOLOCK)              
INNER JOIN #RefStdTbl RefStd WITH(NOLOCK)              
ON RS.RefStdId = RefStd.RefStdId              
AND RS.MasterDataTypeId = @PMasterDataTypeId              
              
insert into @MasterReferenceStandardEdition              
select RSE.RefStdEditionId, RSE.RefStdId , RSE.RefEdition , RSE.RefStdTitle, RSE.LinkTarget               
from [SLCMaster].dbo.ReferenceStandardEdition RSE WITH(NOLOCK)              
INNER JOIN #RefStdTbl RefStd WITH(NOLOCK)              
ON RSE.RefStdId = RefStd.RefStdId              
AND RSE.MasterDataTypeId = @PMasterDataTypeId              
              
insert into @ReferenceStandard              
select PRS.RefStdId    
,PRS.RefStdName    
,PRS.RefStdSource    
,PRS.ReplaceRefStdId    
,PRS.ReplaceRefStdSource    
,PRS.mReplaceRefStdId    
,PRS.IsObsolete    
,PRS.RefStdCode    
,PRS.CreateDate    
,PRS.CreatedBy    
,PRS.ModifiedDate    
,PRS.ModifiedBy    
,PRS.CustomerId    
,PRS.IsDeleted    
,PRS.IsLocked    
,PRS.IsLockedByFullName    
,PRS.IsLockedById    
,PRS.A_RefStdId, RSP.RefStdEditionId from [dbo].ReferenceStandard PRS WITH (NOLOCK)              
inner join #RefStdProj RSP  WITH (NOLOCK)              
on PRS.RefStdId = RSP.RefStdId               
WHERE ISNULL(PRS.IsDeleted,0) = 0              
              
insert into @ReferenceStandardEdition              
select PRSE.RefStdEditionId, PRSE.RefEdition,PRSE.RefStdTitle,PRSE.LinkTarget              
from [dbo].ReferenceStandardEdition PRSE WITH (NOLOCK)              
WHERE PRSE.CustomerId= @PCustomerId              
              
--DROP TABLE IF EXISTS #ProjectReferenceStandard              
DECLARE @table_RefStandardWithEditionId TABLE (              
    RefStdId int,              
 RefStdEditionId int              
);              
SELECT RefStandardId,RefStdEditionId,CustomerId,RefStdSource INTO #ProjectReferenceStandard             
FROM ProjectReferenceStandard  PRT  WITH(NOLOCK) where PRT.ProjectId=@PProjectId    and PRT.CustomerId=@PCustomerId and PRT.RefStdSource='U' AND ISNULL(PRT.IsDeleted,0) = 0           
              
INSERT INTO  @table_RefStandardWithEditionId               
--RS list with edition which is not yet used              
SELECT RT.RefStdId AS RefStdId              
   ,MAX(RSE.RefStdEditionId) AS RefStdEditionId              
  FROM ReferenceStandard RT  WITH(NOLOCK) left outer join #ProjectReferenceStandard  PRT               
on RT.RefStdId=PRT.RefStandardId and RT.CustomerId=PRT.CustomerId and RT.RefStdSource=PRT.RefStdSource              
INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on RT.RefStdId=RSE.RefStdId              
where RT.CustomerId=@PCustomerId and RT.RefStdSource='U' AND   ISNULL(RT.IsDeleted,0) = 0  AND            
PRT.RefStandardId is null              
GROUP BY RT.RefStdId UNION             
--RS list with edition which is in used              
SELECT RT.RefStdId AS RefStdId              
   ,MAX(PRT.RefStdEditionId) AS RefStdEditionId              
FROM ReferenceStandard RT   WITH(NOLOCK)INNER JOIN #ProjectReferenceStandard  PRT              
on RT.RefStdId=PRT.RefStandardId and RT.CustomerId=PRT.CustomerId and RT.RefStdSource=PRT.RefStdSource             
--INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on PRT.RefStandardId =RSE.RefStdId             
where RT.CustomerId=@PCustomerId and RT.RefStdSource='U'  AND   ISNULL(RT.IsDeleted,0) = 0 GROUP BY RT.RefStdId               
SELECT              
 RS.RefStdId              
   ,RS.RefStdName              
   ,ISNULL(RS.ReplaceRefStdId, 0) AS ReplaceRefStdId              
   ,'M' AS RefStdSource              
   ,RS.IsObsolete              
   ,RS.RefStdCode              
   ,CAST(0 AS BIT) AS IsLocked              
   ,NULL AS IsLockedByFullName              
   ,NULL AS IsLockedById              
   ,CAST(0 AS BIT) AS IsDeleted              
   ,RSE.RefStdEditionId              
   ,RSE.RefEdition              
   ,RSE.RefStdTitle              
   ,RSE.LinkTarget              
FROM @MasterReferenceStandard RS               
--INNER JOIN #RefStdTbl RefStd WITH(NOLOCK)              
-- ON RS.RefStdId = RefStd.RefStdId              
--  AND RS.MasterDataTypeId = @PMasterDataTypeId              
INNER JOIN @MasterReferenceStandardEdition RSE              
 ON RS.RefStdId = RSE.RefStdId              
  AND RS.RefStdEditionId = RSE.RefStdEditionId              
  --AND RSE.MasterDataTypeId = @PMasterDataTypeId              
UNION              
SELECT              
 PRS.RefStdId              
   ,PRS.RefStdName              
   ,PRS.ReplaceRefStdId              
   ,PRS.RefStdSource              
   ,PRS.IsObsolete              
   ,COALESCE(PRS.RefStdCode, 0) AS RefStdCode              
   ,CAST(0 AS BIT) AS IsLocked              
   ,PRS.IsLockedByFullName              
   ,PRS.IsLockedById              
   ,PRS.IsDeleted              
   ,PRSE.RefStdEditionId              
   ,PRSE.RefEdition              
   ,PRSE.RefStdTitle              
   ,PRSE.LinkTarget               
FROM ReferenceStandard PRS WITH(NOLOCK)              
inner join ReferenceStandardEdition PRSE  WITH(NOLOCK)              
on PRSE.RefStdId = PRS.RefStdId              
INNER JOIN @table_RefStandardWithEditionId tvn              
on tvn.RefStdId=prs.RefStdId and tvn.RefStdEditionId=prse.RefStdEditionId              
where PRS.CustomerId=@PCustomerId and ISNULL(PRS.IsDeleted,0) = 0  --and PRS.RefStdSource='U'              
              
ORDER BY RS.RefStdName;              
              
END 