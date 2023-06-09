CREATE procedure [dbo].[usp_checkedRSLockedUnlocked]
(
@refStdId int ,@IsLockedById int , @IsLockedByFullName nvarchar(max) 
)
AS
Begin
DECLARE @PrefStdId int = @refStdId;
DECLARE @PIsLockedById int = @IsLockedById;
DECLARE @PIsLockedByFullName nvarchar(max) = @IsLockedByFullName;

	Declare @IsLocked bit;

SELECT top 1 @IsLocked = IsLocked FROM ReferenceStandard WITH(NOLOCK) WHERE RefStdId = @PrefStdId

IF (@IsLocked != 1 OR ISNULL(@IsLocked, 0) = 0)
BEGIN
	UPDATE rs 
	SET rs.IsLocked = 1
	   ,rs.IsLockedByFullName = @PIsLockedByFullName
	   ,rs.IsLockedById = @PIsLockedById
	   from ReferenceStandard rs WITH(NOLOCK)
	WHERE rs.RefStdId = @PrefStdId;
END;

SELECT
	refstd.RefStdId
   ,refstd.RefStdName
   ,refstd.RefStdSource
   ,refstd.RefStdCode
   ,refstd.CustomerId
   ,refstd.IsDeleted
   ,refstd.IsLocked
   ,refstd.IsLockedByFullName
   ,refstd.IsLockedById
   ,refStdEdtn.RefEdition
   ,refStdEdtn.LinkTarget
   ,refStdEdtn.RefStdTitle
FROM ReferenceStandard refstd WITH (NOLOCK)
INNER JOIN ReferenceStandardEdition refStdEdtn WITH (NOLOCK)
	ON refstd.RefStdId = refStdEdtn.RefStdId
WHERE refstd.RefStdId = @PrefStdId;

END;

GO
