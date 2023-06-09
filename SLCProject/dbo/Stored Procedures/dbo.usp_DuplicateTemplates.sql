CREATE PROCEDURE [dbo].[usp_DuplicateTemplates]                      
@TemplateId int ,                  
@CustomerId int                       
As                      
BEGIN        
          
DECLARE @PTemplateId int = @TemplateId;        
DECLARE @PCustomerId int = @CustomerId;      
Declare @templateName nvarchar(max);        
Declare @newTemplateId int;      
DECLARE @NameCount INT = 0;        
DECLARE @ProjectName NVARCHAR(MAX) = '',@NamePrefix varchar(MAX)='Copy of ';        
DECLARE @isIncludeCopyofText bit=0    
DECLARE @leftBraketCount int=0    
DECLARE @finalTemplateName NVARCHAR(MAX)=''    
--Tempate Name    
SELECT TOP 1        
 @ProjectName = TRIM(P.[Name])        
FROM Template P WITH(NOLOCK)         
WHERE P.TemplateId = @PTemplateId    
--AND (P.CustomerId=@PCustomerId OR P.IsSystem=1)    
    
print '@ProjectName '+@ProjectName    
-- isIncludeCopyofText    
if CHARINDEX(@NamePrefix,@ProjectName) > 0   begin     set @isIncludeCopyofText=1 end      
else  begin set @isIncludeCopyofText=0 end    
print '@isIncludeCopyofText ' print @isIncludeCopyofText    
-- leftBraketCount    
set @leftBraketCount =  len(@ProjectName) - len(replace(@ProjectName,'(',''))    
print '@leftBraketCount 'print  @leftBraketCount    
    
if (@isIncludeCopyofText=0)    
begin    
select @NameCount = COUNT(TemplateId)+1 from Template WITH(NOLOCK) where CustomerId=@PCustomerId and IsDeleted=0    
 and NAME like @NamePrefix+@ProjectName+'%' --and @isIncludeCopyofText=0 and @leftBraketCount in (0 ,null )    
print '@NameCount' print @NameCount    
    
set @finalTemplateName=CONCAT( @NamePrefix ,@ProjectName,' (',@NameCount,')')    
print '@finalTemplateName' print @finalTemplateName    
end    
else    
begin    
select @NameCount = COUNT(TemplateId) from Template WITH(NOLOCK)  where CustomerId=@PCustomerId and IsDeleted=0    
 and NAME like @ProjectName+'%' and @leftBraketCount = @isIncludeCopyofText+1    
print '@NameCount' print @NameCount    
    
  set @NameCount=iif(@NameCount=0,1,@NameCount)  
  
set @finalTemplateName=CONCAT( @ProjectName,' (',@NameCount,')')    
end    
    
while(exists(select top 1 1 from template with(nolock) where name=@finalTemplateName and CustomerId=@CustomerId and ISNULL(IsDeleted,0)=0))  
begin  
 set @NameCount=@NameCount+1  
 set @finalTemplateName=CONCAT(@ProjectName,' (',@NameCount,')')  
end  
  
print '@finalTemplateName' print @finalTemplateName    
  set @finalTemplateName=concat(@NamePrefix,REPLACE(@finalTemplateName,@NamePrefix,''))  
INSERT INTO Template (CreateDate, Name, CreatedBy, IsDeleted, IsSystem, CustomerId,        
SequenceNumbering, TitleFormatId, MasterDataTypeId,ApplyTitleStyleToEOS)        
 SELECT        
  GETUTCDATE()        
    ,@finalTemplateName        
  --,CONCAT('Copy of ', @new, '(', @copiedTemplateNameCount, ')')          
    ,CreatedBy        
    ,0 AS IsDeleted        
    ,0 AS IsSystem        
    ,COALESCE(@PCustomerId, 0)        
    ,SequenceNumbering        
    ,TitleFormatId        
    ,MasterDataTypeId  
	,ApplyTitleStyleToEOS      
 FROM Template        WITH(NOLOCK)   
 WHERE TemplateId = @PTemplateId;        
        
SET @newTemplateId = (SELECT        
  IDENT_CURRENT('Template'));        
          
                      
 declare @Counter int =1;        
          
                      
 declare @newStyleId int;        
        
WITH Cte        
AS        
(SELECT        
  TemplateId        
    ,StyleId        
    ,Level        
    ,CustomerId        
    ,ROW_NUMBER() OVER (ORDER BY Level ASC) AS RowId        
 FROM TemplateStyle WITH(NOLOCK)         
 WHERE TemplateId = @PTemplateId)        
SELECT        
 * INTO #templateStyleTemp        
FROM Cte        
        
DECLARE @templateStyleTempCount INT = (SELECT        
  COUNT(*)        
 FROM #templateStyleTemp);        
        
WHILE @Counter <= @templateStyleTempCount        
BEGIN        
--                      
INSERT INTO Style (Alignment, IsBold, CharAfterNumber, CharBeforeNumber, FontName, FontSize, HangingIndent, IncludePrevious,        
IsItalic, LeftIndent, NumberFormat, NumberPosition, PrintUpperCase, ShowNumber, StartAt, Strikeout, Name, TopDistance, Underline, SpaceBelowParagraph,        
IsSystem, CustomerId, IsDeleted, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, Level, MasterDataTypeId, A_StyleId)        
 SELECT        
  Alignment        
    ,IsBold        
    ,CharAfterNumber        
    ,CharBeforeNumber        
    ,FontName        
    ,FontSize        
    ,HangingIndent        
    ,IncludePrevious        
    ,IsItalic        
    ,LeftIndent        
    ,NumberFormat        
    ,NumberPosition        
    ,PrintUpperCase        
    ,ShowNumber        
    ,StartAt        
    ,Strikeout        
    ,CONCAT(@finalTemplateName, ' Level ', (@Counter - 1))        
    ,TopDistance        
    ,Underline        
    ,SpaceBelowParagraph        
    ,0        
    ,COALESCE(@PCustomerId, 0)        
    ,0        
    ,CreatedBy        
    ,GETUTCDATE()        
    ,ModifiedBy        
    ,ModifiedDate        
    ,Level        
    ,MasterDataTypeId        
    ,A_StyleId        
 FROM Style        WITH(NOLOCK)   
 WHERE StyleId = (SELECT        
   StyleId        
  FROM #templateStyleTemp        
  WHERE RowId = @counter)        
        
SET @newStyleId = (SELECT        
  IDENT_CURRENT('Style'));        
        
--                      
INSERT INTO TemplateStyle (TemplateId, StyleId, Level, CustomerId)        
 SELECT        
  @newTemplateId        
    ,@newStyleId        
    ,Level        
    ,COALESCE(@PCustomerId, 0)        
 FROM #templateStyleTemp        
 WHERE RowId = @counter        
        
SET @Counter = @Counter + 1;        
          
                      
                      
 END;        
        
        
--select * from template,templateStyle,style                      
SELECT        
 *        
FROM Template WITH (NOLOCK)        
WHERE TemplateId = @newTemplateId;        
        
SELECT        
 ts.Level AS ts_Level        
   ,ts.StyleId AS ts_StyleId        
   ,ts.TemplateStyleId        
   ,ts.TemplateId        
   ,st.*        
FROM TemplateStyle ts WITH (NOLOCK)        
INNER JOIN Style st WITH (NOLOCK)        
 ON ts.StyleId = st.StyleId        
WHERE TemplateId = @newTemplateId; --518                      
        
END;   