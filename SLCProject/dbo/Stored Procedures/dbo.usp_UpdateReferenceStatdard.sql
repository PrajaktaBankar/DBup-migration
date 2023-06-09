CREATE Procedure [dbo].[usp_UpdateReferenceStatdard]    
(    
@inpRefStdDtoJson nvarchar(max)    
)    
As    
Begin    
DECLARE @PinpRefStdDtoJson nvarchar(max) = @inpRefStdDtoJson;    
  Declare @ReferenceStandard Table(    
  [RefStdId] int,    
  [ModifiedBy] int    
 );    
    
  Declare @ReferenceStandardEdition Table(    
 [RefStdEditionId] int,    
 [RefEdition] nvarchar(255),    
 [RefStdTitle] nvarchar(1024),    
 [LinkTarget] nvarchar(1024),    
 [CreatedBy] int,    
 [RefStdId] int,    
 [CustomerId] int,    
 [ModifiedBy] int,    
 [A_RefStdEditionId] int    
 );    
    
 Declare @inpRefStdTbl Table(    
   ReferenceStandard nvarchar(max),    
   ReferenceStandardEdition nvarchar(max)    
 );    
    
INSERT INTO @inpRefStdTbl (ReferenceStandard, ReferenceStandardEdition)    
 SELECT    
  *    
 FROM OPENJSON(@PinpRefStdDtoJson)    
 WITH (    
 ReferenceStandard NVARCHAR(MAX) AS JSON,    
 ReferenceStandardEdition NVARCHAR(MAX) AS JSON    
 );    
    
DECLARE @refStndJson NVARCHAR(MAX);    
DECLARE @refStndEdtnJson NVARCHAR(MAX);    
    
SELECT    
 @refStndJson = ReferenceStandard    
   ,@refStndEdtnJson = ReferenceStandardEdition    
FROM @inpRefStdTbl;    
    
INSERT INTO @ReferenceStandard ([RefStdId], [ModifiedBy])    
 SELECT    
  *    
 FROM OPENJSON(@refStndJson)    
 WITH (    
 [RefStdId] INT '$.Id',    
 ModifiedBy INT '$.ModifiedBy'    
 );    
    
INSERT INTO @ReferenceStandardEdition ([RefStdEditionId], [RefEdition], [RefStdTitle], [LinkTarget], [CreatedBy],    
[RefStdId], [CustomerId], [ModifiedBy], [A_RefStdEditionId])    
 SELECT    
  *    
 FROM OPENJSON(@refStndEdtnJson)    
 WITH (    
 [RefStdEditionId] INT '$.RefStdEditionId',    
 RefEdition NVARCHAR(255) '$.RefEdition',    
 RefStdTitle NVARCHAR(1024) '$.RefStdTitle',    
 LinkTarget NVARCHAR(1024) '$.LinkTarget',    
 CreatedBy INT '$.CreatedBy',    
 RefStdId INT '$.RefStdId',    
 CustomerId INT '$.CustomerId',    
 [ModifiedBy] INT '$.ModifiedBy',    
 [A_RefStdEditionId] INT '$.A_RefStdEditionId'    
 );    
    
UPDATE refstd    
SET refstd.ModifiedDate = GETUTCDATE()    
   ,refstd.ModifiedBy = temp_refStd.ModifiedBy    
   ,refstd.Islocked =    
 CASE    
  WHEN refstd.IsLocked = 1 THEN 0    
  ELSE refstd.IsLocked    
 END    
   ,refstd.IsLockedById =    
 CASE    
  WHEN refstd.IsLocked = 1 THEN NULL    
  ELSE refstd.IsLockedById    
 END    
   ,refstd.IsLockedByFullName =    
 CASE    
  WHEN refstd.IsLocked = 1 THEN NULL    
  ELSE refstd.IsLockedByFullName    
 END    
FROM @ReferenceStandard temp_refStd    
INNER JOIN ReferenceStandard refstd WITH (NOLOCK)    
 ON refstd.RefStdId = temp_refStd.RefStdId    
  
  INSERT INTO ReferenceStandardEdition ( [RefEdition], [RefStdTitle],[LinkTarget], [CreateDate],[CreatedBy],    
[RefStdId], [CustomerId], [ModifiedBy], [A_RefStdEditionId])   
select  [RefEdition], [RefStdTitle], [LinkTarget], GETUTCDATE(),[CreatedBy],    
[RefStdId], [CustomerId], [ModifiedBy], [A_RefStdEditionId]   
from @ReferenceStandardEdition   
  
--UPDATE refStdEdtn    
--SET refStdEdtn.RefEdition = temp_refStdEdtn.RefEdition    
--   ,refStdEdtn.RefStdTitle = temp_refStdEdtn.RefStdTitle    
--   ,refStdEdtn.LinkTarget = temp_refStdEdtn.LinkTarget    
--   ,refStdEdtn.ModifiedDate = GETUTCDATE()    
--   ,refStdEdtn.ModifiedBy = temp_refStdEdtn.ModifiedBy    
--FROM @ReferenceStandardEdition temp_refStdEdtn    
--INNER JOIN ReferenceStandardEdition refStdEdtn WITH (NOLOCK)    
-- ON temp_refStdEdtn.RefStdEditionId = refStdEdtn.RefStdEditionId    
    
SELECT    
 *    
FROM ReferenceStandard WITH (NOLOCK)    
WHERE RefStdId = (SELECT    
  RefStdId    
 FROM @ReferenceStandard );    
END; 