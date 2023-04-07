CREATE PROCEDURE [dbo].[usp_ActionOnMasterSegmentModify] @ProjectId              INT, 
                                                         @SectionId              INT, 
                                                         @CustomerId             INT, 
                                                         @UserId                 INT, 
                                                         @SegmentStatusId        BIGINT, 
                                                         @SegmentDescription     NVARCHAR(MAX), 
                                                         @BaseSegmentDescription NVARCHAR(MAX), 
                                                         @SegmentId              BIGINT, 
                                                         @SegmentSource          CHAR(1), 
                                                         @SegmentOrigin          CHAR(2), 
                                                         @ParentSegmentStatusId  BIGINT, 
                                                         @IndentLevel            INT, 
                                                         @IsShowAutoNumber       BIT, 
                                                         @FormattingJson         NVARCHAR(MAX), 
                                                         @IsPageBreak            BIT, 
                                                         @SpecTypeTagId          INT
AS
    BEGIN

	BEGIN TRY
        DECLARE @PProjectId INT= @ProjectId;
        DECLARE @PSectionId INT= @SectionId;
        DECLARE @PCustomerId INT= @CustomerId;
        DECLARE @PUserId INT= @UserId;
        DECLARE @PSegmentStatusId BIGINT= @SegmentStatusId;
        DECLARE @PSegmentDescription NVARCHAR(MAX)= @SegmentDescription;
        DECLARE @PBaseSegmentDescription NVARCHAR(MAX)= @BaseSegmentDescription;
        DECLARE @PSegmentId BIGINT= @SegmentId;
        DECLARE @PSegmentSource CHAR(1)= @SegmentSource;
        DECLARE @PSegmentOrigin CHAR(2)= @SegmentOrigin;
        DECLARE @PParentSegmentStatusId BIGINT= @ParentSegmentStatusId;
        DECLARE @PIndentLevel INT= @IndentLevel;
        DECLARE @PIsShowAutoNumber BIT= @IsShowAutoNumber;
        DECLARE @PFormattingJson NVARCHAR(MAX)= @FormattingJson;
        DECLARE @PIsPageBreak BIT= @IsPageBreak;
        DECLARE @PSpecTypeTagId INT= @SpecTypeTagId;
        --Set Nocount On  
        SET NOCOUNT ON;
        DECLARE @IsNewSegmentCreated BIT= 0;
        PRINT 'segment call';
        --1]FIRST DELETE IF EXISTING USER SEGMENT CREATED    
        --IF @PSegmentStatusId>0  
        --begin  
        IF @PSegmentId IS NULL
           OR @PSegmentId <= 0
            BEGIN
                IF @PSegmentOrigin = 'U'
                    BEGIN
                        --CREATE NEW SEGMENT    
                        INSERT INTO ProjectSegment
                        (SegmentStatusId, 
                         SectionId, 
                         ProjectId, 
                         CustomerId, 
                         SegmentDescription, 
                         BaseSegmentDescription, 
                         SegmentSource, 
                         CreatedBy, 
                         CreateDate, 
                         ModifiedBy, 
                         ModifiedDate
                        )
                        VALUES
                        (@PSegmentStatusId, 
                         @PSectionId, 
                         @PProjectId, 
                         @PCustomerId, 
                         @PSegmentDescription, 
                         @PBaseSegmentDescription, 
                         'U', 
                         @PUserId, 
                         GETUTCDATE(), 
                         @PUserId, 
                         GETUTCDATE()
                        );

                        --GET NEW ID AND UPDATE IT  
                        SET @PSegmentId = SCOPE_IDENTITY();
                        UPDATE PSS
                          SET 
                              SegmentId = @PSegmentId
                        FROM ProjectSegmentStatus PSS WITH(NOLOCK)
                        WHERE SegmentStatusId = @PSegmentStatusId;
                        SET @IsNewSegmentCreated = 1;
                END;
        END;
            ELSE
            BEGIN

                --UPDATE SEGMENT 

                IF @PSegmentOrigin = 'U'
                    BEGIN
                        UPDATE PS
                          SET 
                              PS.SegmentDescription = @PSegmentDescription, 
                              PS.BaseSegmentDescription = @PBaseSegmentDescription, 
                              PS.ModifiedBy = @PUserId, 
                              PS.ModifiedDate = GETUTCDATE()
                        FROM ProjectSegment PS WITH(NOLOCK)
                        WHERE SegmentId = @PSegmentId;
                END;
                --  EXEC [dbo].[usp_UpdateSegmentsGTMapping]  0, 0, @PProjectId, @PSectionId ,@PCustomerId,@PUserId, @PSegmentId,NULL,@PSegmentDescription  
        END;
        UPDATE PSST
          SET 
              PSST.ModifiedBy = @PUserId, 
              PSST.ModifiedDate = GETUTCDATE(), 
              PSST.SegmentOrigin = @PSegmentOrigin, 
              PSST.ParentSegmentStatusId = @PParentSegmentStatusId, 
              PSST.IndentLevel = @PIndentLevel, 
              PSST.IsShowAutoNumber = @PIsShowAutoNumber, 
              PSST.FormattingJson = @PFormattingJson, 
              PSST.IsPageBreak = @PIsPageBreak
        FROM ProjectSegmentStatus PSST WITH(NOLOCK)
        WHERE PSST.SegmentStatusId = @PSegmentStatusId;
        IF @IsNewSegmentCreated = 1
            BEGIN
                --COPY MASTER LINKS AS USER LINKS WHEN MASTER SEGMENT IS MODIFIED  
                EXEC usp_CopyMasterLinksAsUserLinks 
                     @PProjectId, 
                     @PCustomerId, 
                     @PSegmentStatusId, 
                     @PUserId,
					 @PSectionId;
        END;
END TRY
BEGIN CATCH
	insert into BsdLogging..AutoSaveLogging
		values('usp_ActionOnMasterSegmentModify',
		getdate(),
		ERROR_MESSAGE(),
		ERROR_NUMBER(),
		ERROR_Severity(),
		ERROR_LINE(),
		ERROR_STATE(),
		ERROR_PROCEDURE(),
		concat('exec usp_ActionOnMasterSegmentModify ',@PProjectId,',',@PSectionId,',',@PCustomerId,',',@UserId,',',@SegmentStatusId,',''',@SegmentDescription,''',NULL,',@SegmentId,',''',@SegmentSource,''',''',@SegmentOrigin,''',',@ParentSegmentStatusId,',',@IndentLevel,',',@IsShowAutoNumber,',','''',@FormattingJson,''',',@IsPageBreak,',', @SpecTypeTagId),
		@SegmentDescription
	)
END CATCH
END;
GO


