CREATE PROCEDURE [dbo].[usp_getProjectCountByCustomerId]    
(    
  @CustomerId NVARCHAR(MAX) NULL=''
 )
AS    
BEGIN
DECLARE @PCustomerId NVARCHAR(MAX) =@CustomerId;
SET NOCOUNT ON;

DECLARE @CustomerIdTbl TABLE (
	CustomerId INT
);

INSERT INTO @CustomerIdTbl (CustomerId)
	SELECT
		*
	FROM dbo.fn_SplitString(@PCustomerId, ',');

SELECT
	p.CustomerId
   ,COUNT(ProjectId) AS ProjectCount
FROM [Project] p WITH (NOLOCK)
INNER JOIN @CustomerIdTbl CTbl
	ON P.CustomerId = CTbl.CustomerId
GROUP BY p.CustomerId
END

GO
