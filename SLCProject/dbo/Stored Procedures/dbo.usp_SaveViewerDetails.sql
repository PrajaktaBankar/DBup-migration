CREATE PROCEDURE [dbo].[usp_SaveViewerDetails]
@CustomerId INT NULL, @UserId INT NULL, @Workstation NVARCHAR (50) NULL, @CreatedBy INT NULL=NULL, @ModifiedBy INT NULL=NULL, @IsActive BIT NULL
AS
BEGIN
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PUserId INT = @UserId;
DECLARE @PWorkstation NVARCHAR (50) = @Workstation;
DECLARE @PCreatedBy INT = @CreatedBy;
DECLARE @PModifiedBy INT = @ModifiedBy;
DECLARE @PIsActive BIT = @IsActive;

    DECLARE @CreatedDate AS DATETIME = GETDATE();
    DECLARE @ModifiedDate AS DATETIME = GETDATE();
    IF (NOT EXISTS (SELECT
		TOP 1 1
	FROM [StandaloneViewerDetails] WITH (NOLOCK)
	WHERE [CustomerId] = @PCustomerId
	AND [UserId] = @PUserId)
)
BEGIN
INSERT INTO [StandaloneViewerDetails] ([CustomerId], [UserId], [Workstation], CreatedDate, CreatedBy, MODIFIEDDATE, ModifiedBy, [IsActive])
	VALUES (@PCustomerId, @PUserId, @PWorkstation, @CreatedDate, @PCreatedBy, @ModifiedDate, @PModifiedBy, @PIsActive);
END
ELSE
BEGIN
UPDATE SVD
SET SVD.[Workstation] = @PWorkstation
   ,SVD.[IsActive] = @PIsActive
   ,SVD.MODIFIEDDATE = @ModifiedDate
   ,SVD.ModifiedBy = @PModifiedBy
   FROM [StandaloneViewerDetails] SVD WITH (NOLOCK)
WHERE SVD.[CustomerId] = @PCustomerId
AND SVD.[UserId] = @PUserId;
END
END

GO
