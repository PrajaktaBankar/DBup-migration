CREATE FUNCTION [dbo].[fn_GetDivisionParentSectionId](@ProjectId INT, @CustomerId INT, @SortOrder INT, @SourceTag NVARCHAR(50))          
RETURNS INT          
AS          
BEGIN          
 DECLARE @ParentSectionId INT = -1;
 DECLARE @tProjectSection TABLE  
 (  
   SectionId INT,
   ParentSectionId INT,
   mSectionId INT,
   SourceTag NVARCHAR(20),
   SortOrder INT
 );
 
 INSERT INTO @tProjectSection (SectionId, ParentSectionId, mSectionId, SourceTag, SortOrder)
 SELECT PS.SectionId, PS.ParentSectionId, PS.mSectionId, PS.SourceTag, PS.SortOrder FROM ProjectSection PS WITH(NOLOCK) 
 WHERE ProjectId = @ProjectId AND CustomerId = @CustomerId AND ISNULL(ISDELETED,0) = 0
 AND (ParentSectionId = 0 OR mSectionId IN (1,2,3,4,5,3000001, 3000109, 3000635, 3000921, 3001044) OR
	SourceTag IN ('02','21','31','40'));
           
 IF(ISNUMERIC(SUBSTRING(@SourceTag,1,1)) = 1)          
 BEGIN          
  IF(@SortOrder <= (SELECT TOP 1 SortOrder FROM @tProjectSection  WHERE SourceTag = '02'))          
   SELECT @ParentSectionId = SectionId FROM @tProjectSection  WHERE ParentSectionId = 0 AND (mSectionId = 5 OR mSectionId = 3000001); -- Front End Group          
  IF(@SortOrder <= (SELECT TOP 1 SortOrder FROM @tProjectSection  WHERE SourceTag = '21'))          
   SELECT @ParentSectionId = SectionId FROM @tProjectSection  WHERE ParentSectionId = 0 AND (mSectionId = 1 OR mSectionId = 3000109); -- Facility Construction Subgroup - Divisions 02 through 14         
  ELSE IF(@SortOrder <= (SELECT TOP 1 SortOrder FROM @tProjectSection  WHERE SourceTag = '31'))          
   SELECT @ParentSectionId = SectionId FROM @tProjectSection  WHERE ParentSectionId = 0 AND (mSectionId = 2 OR mSectionId = 3000635); -- Facility Services Subgroup - Divisions 21 through 28
          
  ELSE IF(@SortOrder <= (SELECT TOP 1 SortOrder FROM @tProjectSection  WHERE SourceTag = '40'))          
   SELECT @ParentSectionId = SectionId FROM @tProjectSection  WHERE ParentSectionId = 0 AND (mSectionId = 3 OR mSectionId = 3000921); -- Site and Infrastructure Subgroup - Divisions 31 through 35      
  ELSE           
   SELECT @ParentSectionId = SectionId FROM @tProjectSection  WHERE ParentSectionId = 0 AND (mSectionId = 4 OR mSectionId = 3001044); --Process Equipment Subgroup - Divisions 40 through 48 
 END          
 ELSE           
 BEGIN          
   SELECT @ParentSectionId = SectionId FROM @tProjectSection  WHERE ParentSectionId = 0 AND (mSectionId = 4 OR mSectionId = 3001044); --Process Equipment Subgroup - Divisions 40 through 48 
 END          
 RETURN @ParentSectionId;          
END 