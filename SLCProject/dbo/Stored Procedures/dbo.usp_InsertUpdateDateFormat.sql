CREATE PROCEDURE [dbo].[usp_InsertUpdateDateFormat]  
@ProjectDateFormatId INT,
@MasterDataTypeId INT,
@ProjectId INT,
@CustomerId INT,
@UserId INT,
@ClockFormat NVARCHAR(MAX),
@DateFormat NVARCHAR(MAX)

AS  
BEGIN
  
DECLARE @PProjectDateFormatId INT = @ProjectDateFormatId;
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PUserId INT = @UserId;
DECLARE @PClockFormat NVARCHAR(MAX) = @ClockFormat;
DECLARE @PDateFormat NVARCHAR(MAX) = @DateFormat;

	IF(NOT EXISTS (SELECT
		ProjectId
	FROM [ProjectDateFormat] WITH (NOLOCK)
	WHERE CustomerId = @PCustomerId
	AND UserId = @PUserId
	AND ProjectId = @PProjectId
	AND MasterDataTypeId = @PMasterDataTypeId)
)
BEGIN

INSERT INTO ProjectDateFormat (MasterDataTypeId, ProjectId, CustomerId, UserId, ClockFormat, DateFormat, CreateDate)
	VALUES (@PMasterDataTypeId, @PProjectId, @PCustomerId, @PUserId, @PClockFormat, @PDateFormat, GETUTCDATE())

END
ELSE
BEGIN
IF (@PProjectId > 0)
BEGIN
UPDATE PDF
SET ClockFormat = @PClockFormat
   ,DateFormat = @PDateFormat
FROM ProjectDateFormat PDF WITH (NOLOCK)
WHERE ProjectId = @PProjectId
AND CustomerId = @PCustomerId
AND UserId = @PUserId
END
END
END

GO
