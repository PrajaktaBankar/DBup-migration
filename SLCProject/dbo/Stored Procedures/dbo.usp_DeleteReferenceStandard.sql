CREATE procedure [dbo].[usp_DeleteReferenceStandard]
(@refStdId int )
AS
Begin
   DECLARE @PrefStdId int = @refStdId;
UPDATE rs
SET	  rs.IsDeleted = 1
from ReferenceStandard rs WITH (NOLOCK)
WHERE rs.RefStdId = @PrefStdId;

SELECT
	*
FROM ReferenceStandard WITH (NOLOCK)
WHERE RefStdId = @PrefStdId;
END;

GO
