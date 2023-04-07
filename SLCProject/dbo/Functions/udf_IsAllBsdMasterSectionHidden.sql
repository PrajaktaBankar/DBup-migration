CREATE FUNCTION [dbo].[udf_IsAllBsdMasterSectionHidden](@ProjectId INT, @CustomerId INT)          
RETURNS BIT          
AS                      
BEGIN                      
 DECLARE @IsAllBsdMasterSectionHidden BIT = 1;            
 DECLARE @MasterDataTypeId INT = (SELECT MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @ProjectId);       
 DECLARE @ProjectSectionTbl Table (SectionId INT,ParentSectionId INT,IsHidden BIT,IsLastLevel INT,ProjectId int,CustomerId INT)         
      
 IF(@MasterDataTypeId = 1 OR @MasterDataTypeId =4) -- BSD Master          
 BEGIN       
 INSERT INTO @ProjectSectionTbl      
 SELECT PS.SectionId,PS.ParentSectionId,PS.IsHidden,PS.IsLastLevel, PS.ProjectId,PS.CustomerId FROM ProjectSection PS WITH(NOLOCK) WHERE PS.ProjectId=@ProjectId       
 and PS.CustomerId=@CustomerId  and ISNULL(IsDeleted,0) = 0    
      
 SELECT TOP 1 @IsAllBsdMasterSectionHidden=0 FROM @ProjectSectionTbl PS1  inner join @ProjectSectionTbl PS2    
  ON PS1.SectionId=PS2.ParentSectionId  LEFT JOIN @ProjectSectionTbl PST on PS2.SectionId=PST.ParentSectionId       
  WHERE ISNULL(PST.IsHidden,0) = 0 and PST.IsLastLevel=1 and  PST.ProjectId=@ProjectId and PST.CustomerId=@CustomerId and ISNULL(PS1.IsHidden,0) = 0 and ISNULL(PS2.IsHidden,0) = 0     
      
 END          
 ELSE-- NMS Master          
 BEGIN    
 INSERT INTO @ProjectSectionTbl      
 SELECT PS.SectionId,PS.ParentSectionId,PS.IsHidden,PS.IsLastLevel, PS.ProjectId,PS.CustomerId FROM ProjectSection PS WITH(NOLOCK) WHERE PS.ProjectId=@ProjectId       
 and PS.CustomerId=@CustomerId  and ISNULL(IsDeleted,0) = 0    
    
 SELECT TOP 1 @IsAllBsdMasterSectionHidden=0 FROM @ProjectSectionTbl PS1  inner join @ProjectSectionTbl PS2    
 ON PS1.SectionId=PS2.ParentSectionId  LEFT JOIN @ProjectSectionTbl PST on PS2.SectionId=PST.ParentSectionId       
 WHERE PST.IsLastLevel=1 and  PST.ProjectId=@ProjectId and PST.CustomerId=@CustomerId and ISNULL(PS1.IsHidden,0) = 0  and ISNULL(PST.IsHidden,0) = 0     
    
 END;          
            
 RETURN @IsAllBsdMasterSectionHidden;                      
END   