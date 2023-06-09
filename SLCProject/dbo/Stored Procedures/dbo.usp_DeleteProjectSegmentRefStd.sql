CREATE Procedure [dbo].[usp_DeleteProjectSegmentRefStd]
(
@refStdId int, @refStdCode int, @sectionId int, @projectId int, @customerId int
)
As
Begin
DECLARE @PrefStdId int = @refStdId;
DECLARE @PrefStdCode int = @refStdCode;
DECLARE @PsectionId int = @sectionId;
DECLARE @PprojectId int = @projectId;
DECLARE @PcustomerId int = @customerId;
   
   UPDATE PSRS 
   SET IsDeleted = 1
   FROM ProjectSegmentReferenceStandard PSRS  WITH (NOLOCK)
   Where RefStandardId = @PrefStdId and RefStdCode = @PrefStdCode and
   SectionId = @PsectionId and ProjectId= @PprojectId and CustomerId = @PcustomerId;
 
End;


GO
