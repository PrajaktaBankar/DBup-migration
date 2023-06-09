CREATE PROCEDURE [dbo].[usp_CheckDivisionIsAccessForImportWord]          
(          
 @ProjectId INT,          
 @CustomerId INT,          
 @SourceTag VARCHAR(18),          
 @UserId INT,          
 @ParentSectionId INT,          
 @UserAccessDivisionId NVARCHAR(MAX) = ''          
)          
AS          
BEGIN          
          
 DECLARE @PProjectId INT = @ProjectId;          
 DECLARE @PCustomerId INT = @CustomerId;          
 DECLARE @PSourceTag VARCHAR(18) = @SourceTag;          
 DECLARE @PUserId INT = @UserId;          
 DECLARE @PParentSectionId INT = @ParentSectionId;          
 DECLARE @PUserAccessDivisionId NVARCHAR(MAX) = @UserAccessDivisionId;          
          
--DECLARE VARIABLES          
DECLARE @UserAccessDivisionIdTbl TABLE (          
 DivisionId INT          
);          
DECLARE @FutureDivisionIdOfSectionTbl TABLE (          
 DivisionId INT          
);          
DECLARE @FutureDivisionId INT = NULL;          
          
DECLARE @BsdMasterDataTypeId INT = 1;          
DECLARE @MasterDataTypeId INT = ( SELECT TOP 1          
  MasterDataTypeId          
 FROM Project WITH(NOLOCK)          
 WHERE ProjectId = @PProjectId);          
          
DECLARE @IsSuccess BIT = 1;          
DECLARE @ErrorMessage NVARCHAR(MAX) = '';          
          
--PUT USER DIVISION ID'S INTO TABLE          
INSERT INTO @UserAccessDivisionIdTbl (DivisionId)          
 SELECT          
  *          
 FROM dbo.fn_SplitString(@PUserAccessDivisionId, ',');          
          
--CALCULATE DIVISION ID OF USER SECTION WHICH IS GOING TO BE          
INSERT INTO @FutureDivisionIdOfSectionTbl (DivisionId)          
EXEC usp_CalculateDivisionIdForUserSection @PProjectId          
            ,@PCustomerId          
            ,@PSourceTag          
            ,@PUserId          
            ,@PParentSectionId          
SELECT TOP 1          
 @FutureDivisionId = DivisionId          
FROM @FutureDivisionIdOfSectionTbl;          
          
DECLARE @GrandParentSectionId INT = (SELECT ParentSectionId FROM ProjectSection WITH(NOLOCK) WHERE SectionId = @PParentSectionId AND ProjectId = @PProjectId AND CustomerId = @PCustomerId);
DECLARE @IsImportingInMasterDivision BIT = 0;    
IF EXISTS(select 1 from ProjectSection P WITH(NOLOCK) WHERE P.SectionId = @GrandParentSectionId AND P.mSectionId IS NULL)
 SET @IsImportingInMasterDivision = 0;    
ELSE     
 SET @IsImportingInMasterDivision = 1;     
    
--PERFORM VALIDATIONS          
IF @IsImportingInMasterDivision = 1 AND @PUserAccessDivisionId != ''          
 AND @FutureDivisionId NOT IN (SELECT          
   DivisionId          
  FROM @UserAccessDivisionIdTbl)          
BEGIN          
SET @IsSuccess = 0;          
SET @ErrorMessage = 'You don''t have access rights to import section(s) in this division';          
END          
          
--If Division id is null and parent section is Unassigned Sections then return the division id from SLCMaster..Division          
IF(COALESCE(@FutureDivisionId, 0) =0)          
BEGIN          
SELECT @FutureDivisionId =DV.DivisionId           
FROM SLCMaster..Division DV WITH(NOLOCK)          
INNER JOIN ProjectSection PS  WITH(NOLOCK)          
ON TRIM(PS.Description)=TRIM(DV.DivisionTitle)           
AND DV.FormatTypeId=PS.FormatTypeId           
INNER JOIN Project P WITH(NOLOCK) ON p.ProjectId=PS.ProjectId          
AND DV.MasterDataTypeId=P.MasterDataTypeId AND P.CustomerId=PS.CustomerId          
WHERE PS.SectionId=@PParentSectionId           
AND PS.CustomerId=@PCustomerId          
AND TRIM(PS.Description) = TRIM('Unassigned Sections')          
END          
          
--RETURN DATA          
SELECT          
 @IsSuccess AS IsSuccess          
   ,@ErrorMessage AS ErrorMessage          
   ,COALESCE(@FutureDivisionId, 0) AS DivisionId          
          
END 
GO