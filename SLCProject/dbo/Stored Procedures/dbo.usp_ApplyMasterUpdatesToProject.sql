CREATE PROCEDURE [dbo].[usp_ApplyMasterUpdatesToProject]    
 @ProjectId INT, @CustomerId INT AS    
BEGIN    
DECLARE @PProjectId INT = @ProjectId;    
DECLARE @PCustomerId INT = @CustomerId;    
    
DECLARE @InsertAction NVARCHAR(10) = 'INSERT';    
DECLARE @UpdateAction NVARCHAR(10) = 'UPDATE';    
DECLARE @DeleteAction NVARCHAR(10) = 'DELETE';    
DECLARE @DeleteRevertAction NVARCHAR(20) = 'DELETE_REVERT';    
    
DECLARE @LastMasterApplyDate DATETIME2(7) = NULL;    
DECLARE @IsProjectIdEntryExists BIT = 0;    
DECLARE @MasterDataTypeId INT = NULL;    
    
DECLARE @LastMasterUpdatedByActionType DATETIME2(7) = NULL;    
DECLARE @TableName NVARCHAR(50) = NULL;    
DECLARE @CommandType NVARCHAR(50) = NULL;    
DECLARE @IsProcess BIT = 0;    
    
DECLARE @LoopCounter INT = 1;    
DECLARE @ApplyMasterUpdateTypes TABLE (    
 Id INT IDENTITY(1,1) NOT NULL,    
 TableName NVARCHAR(50) NULL,    
 CommandType NVARCHAR(50) NULL    
);    
    
--INSERT VALUES INSIDE ApplyMasterUpdateTypes TABLE    
INSERT INTO @ApplyMasterUpdateTypes (TableName, CommandType)    
 VALUES ('Section', @InsertAction),    
 ('Section', @UpdateAction),    
 ('Section', @DeleteAction),    
 ('SegmentStatus', @UpdateAction),    
 ('SegmentRequirementTag', @DeleteAction)    
    
--GET MasterDataTypeId OF PROJECT    
SET @MasterDataTypeId = (SELECT TOP 1    
  P.MasterDataTypeId    
 FROM Project P WITH (NOLOCK)    
 WHERE P.ProjectId = @PProjectId);    
    
--CHECK ProjectId ENTRY EXISTS OR NOT AND GET LastUpdateDate OF IT'S    
IF EXISTS (SELECT TOP 1    
  1    
 FROM ApplyMasterUpdateLog AML WITH (NOLOCK)    
 WHERE AML.ProjectId = @PProjectId)    
BEGIN    
SET @IsProjectIdEntryExists = 1;    
SET @LastMasterApplyDate = (SELECT TOP 1    
  AML.LastUpdateDate    
 FROM ApplyMasterUpdateLog AML WITH (NOLOCK)    
 WHERE AML.ProjectId = @PProjectId    
 ORDER BY AML.ID DESC);    
END    
    
--LOOP TYPES TO CHECK WHICH TO BE PROCESS AND WHICH TO BE NOT    
declare @ApplyMasterUpdateTypesRowCount INT=( SELECT COUNT(*) FROM @ApplyMasterUpdateTypes)    
WHILE (@LoopCounter <= @ApplyMasterUpdateTypesRowCount)    
BEGIN    
SELECT    
 @TableName = AMT.TableName    
   ,@CommandType = AMT.CommandType    
FROM @ApplyMasterUpdateTypes AMT    
WHERE AMT.Id = @LoopCounter;    
    
SET @LastMasterUpdatedByActionType = (SELECT TOP 1    
  MUL.CreatedDate    
 FROM SLCMaster..MasterUpdateLog MUL WITH (NOLOCK)    
 WHERE ISNULL(MUL.RecordsCount, 0) > 0    
 AND MUL.TableName = @TableName    
 AND MUL.CommandType = @CommandType    
 AND MUL.MasterDataTypeId = @MasterDataTypeId    
 ORDER BY MUL.id DESC);    
    
IF @IsProjectIdEntryExists = 0    
BEGIN    
SET @IsProcess = 1;    
END    
ELSE IF @LastMasterUpdatedByActionType IS NOT NULL AND @LastMasterApplyDate < @LastMasterUpdatedByActionType    
BEGIN    
SET @IsProcess = 1;    
END    
    
--PROCESS ACCORDING TO THAT    
IF @TableName = 'Section'     
 AND @CommandType = @InsertAction     
 AND @IsProcess = 1    
BEGIN    
EXEC usp_InsertNewSection_ApplyMasterUpdate @PProjectId    
             ,@PCustomerId;    
END    
ELSE    
IF @TableName = 'Section'    
 AND @CommandType = @UpdateAction    
 AND @IsProcess = 1    
BEGIN    
EXEC usp_UpdateSection_ApplyMasterUpdate @PProjectId    
          ,@PCustomerId;    
EXEC usp_InsertNewSection_ApplyMasterUpdate @PProjectId    
             ,@PCustomerId;    
END    
ELSE    
IF @TableName = 'Section'    
 AND @CommandType = @DeleteAction    
 AND @IsProcess = 1    
BEGIN    
EXEC usp_DeleteMasterSection_ApplyMasterUpdate @PProjectId    
             ,@PCustomerId;    
SET @LoopCounter = @LoopCounter;    
END    
ELSE IF @TableName = 'SegmentStatus' AND @CommandType = @UpdateAction    
BEGIN    
--NOTE:Moved [EXEC usp_UpdateSegmentStatus_ApplyMasterUpdate] under [usp_GetSegments]    
SET @LoopCounter = @LoopCounter;    
END    
ELSE    
IF @TableName = 'SegmentRequirementTag'    
 AND @CommandType = @DeleteAction    
 AND @IsProcess = 1    
BEGIN    
--NOTE:Moved [EXEC usp_DeleteSegmentRequirementTag_ApplyMasterUpdate] under [usp_GetSegments]    
SET @LoopCounter = @LoopCounter;    
END    
    
SET @LoopCounter = @LoopCounter + 1;    
END    
    
--INSERT/UPDATE ENTRY OF ProjectId IN ApplyMasterUpdateLog    
IF @IsProjectIdEntryExists = 0    
BEGIN    
INSERT INTO ApplyMasterUpdateLog (ProjectId, LastUpdateDate)    
 VALUES (@PProjectId, GETUTCDATE());    
END    
ELSE    
BEGIN    
UPDATE AML    
SET AML.LastUpdateDate = GETUTCDATE()    
FROM ApplyMasterUpdateLog AML WITH (NOLOCK)    
WHERE AML.ProjectId = @PProjectId    
END    
END