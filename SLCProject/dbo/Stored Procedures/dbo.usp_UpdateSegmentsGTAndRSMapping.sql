CREATE PROCEDURE [dbo].[usp_UpdateSegmentsGTAndRSMapping]    
(    
 @SegmentStatusId BIGINT NULL = 0,    
 @IsDeleted INT NULL = 0,    
 @ProjectId INT = NULL,    
 @SectionId INT = NULL,    
 @CustomerId INT = NULL,    
 @UserId INT = NULL,    
 @SegmentId BIGINT = NULL,    
 @MSegmentId INT = NULL,    
 @SegmentDescription NVARCHAR(MAX) = NULL    
)    
AS    
BEGIN
 DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;
 DECLARE @PIsDeleted INT = @IsDeleted;
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PSectionId INT = @SectionId;
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PUserId INT = @UserId;
 DECLARE @PSegmentId BIGINT = @SegmentId;
 DECLARE @PMSegmentId INT = @MSegmentId;
 DECLARE @PSegmentDescription NVARCHAR(MAX) = @SegmentDescription;

BEGIN TRY

EXEC [usp_UpdateSegmentsGTMapping] 0
										,0
										,@PProjectId
										,@PSectionId
										,@PCustomerId
										,@PUserId
										,@PSegmentId
										,NULL
										,@PSegmentDescription

EXEC [usp_UpdateSegmentsRSMapping] 0
										,0
										,@PProjectId
										,@PSectionId
										,@PCustomerId
										,@PUserId
										,@PSegmentId
										,NULL
										,@PSegmentDescription

END TRY
BEGIN CATCH
	insert into BsdLogging..AutoSaveLogging
		values('usp_UpdateSegmentsGTAndRSMapping',
		getdate(),
		ERROR_MESSAGE(),
		ERROR_NUMBER(),
		ERROR_Severity(),
		ERROR_LINE(),
		ERROR_STATE(),
		ERROR_PROCEDURE(),
		concat('exec usp_UpdateSegmentsGTAndRSMapping ', ISNULL(@SegmentStatusId, 0), ',', ISNULL(@IsDeleted, 0), ',', 
			ISNULL(@ProjectId, 0), ',', ISNULL(@SectionId, 0), ',', ISNULL(@CustomerId, 0), ',', ISNULL(@UserId, 0), ',', 
			ISNULL(@SegmentId, 0), ',', ISNULL(@MSegmentId, 0),',''', ISNULL(@SegmentDescription, '') , ''''),
		''
	)

	DECLARE @AutoSaveLoggingId INT =  (SELECT @@IDENTITY AS [@@IDENTITY]);
    THROW 50010, @AutoSaveLoggingId, 1;
END CATCH
END
GO


