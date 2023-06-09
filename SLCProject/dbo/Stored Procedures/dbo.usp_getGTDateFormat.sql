CREATE PROCEDURE [dbo].[usp_getGTDateFormat]
(  
@ProjectID INT  
  
)  
AS  
BEGIN
DECLARE @PProjectID INT = @ProjectID;

DECLARE @DateFormat NVARCHAR(50) = NULL,@TimeFormat NVARCHAR(50) = NULL;
DECLARE @MasterDataTypeId int =( SELECT TOP 1
		MasterDataTypeId
	FROM Project WITH(NOLOCK)
	WHERE ProjectId = @PProjectID)
SELECT
	@DateFormat = [DateFormat]
FROM ProjectDateFormat WITH(NOLOCK)
WHERE ProjectId = @PProjectID
SELECT
	@TimeFormat = [ClockFormat]
FROM ProjectDateFormat  WITH(NOLOCK)
WHERE ProjectId = @PProjectID
IF (@DateFormat IS NULL)
BEGIN
SELECT TOP 1
	@DateFormat = [DateFormat]
FROM ProjectDateFormat WITH(NOLOCK)
WHERE MasterDataTypeId = @MasterDataTypeId
AND ProjectId IS NULL
AND CustomerId IS NULL
AND UserId IS NULL
SELECT TOP 1
	@TimeFormat = [ClockFormat]
FROM ProjectDateFormat WITH(NOLOCK)
WHERE MasterDataTypeId = @MasterDataTypeId
AND ProjectId IS NULL
AND CustomerId IS NULL
AND UserId IS NULL
END
SELECT
	@DateFormat = DateFormat
FROM LuDateFormat WITH(NOLOCK)
WHERE [DateFormat] = @DateFormat

DECLARE @True BIT = 1;
DECLARE @False BIT = 0;

SELECT
	ISNULL(P.IsMigrated, 0) AS IsMigrated
   ,IIF(CAST(P.CreateDate AS DATE) < '2019-04-04', @True, @False) AS IsOldProject
   ,@DateFormat AS DateFormat
   ,@TimeFormat AS TimeFormat
FROM Project P WITH(NOLOCK)
WHERE P.ProjectId = @PProjectID
END

GO
