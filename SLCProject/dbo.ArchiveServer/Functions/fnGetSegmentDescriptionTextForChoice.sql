CREATE FUNCTION [dbo].[fnGetSegmentDescriptionTextForChoice]  
(    
 @segmentStatusId BIGINT  
)    
RETURNS nvarchar(max)    
AS    
BEGIN  
   
 -- Declare the return variable here    
 DECLARE @ChoiceCounter int=1,@ChoiceCount int=0  
 DECLARE @OptionCounter int=1,@OptionCount int=0  
 DECLARE @ItemCounter int=1,@ItemCount int=0  
 DECLARE @OptionTypeName NVARCHAR(255),@SortOrder INT,@Value NVARCHAR(255),@Id INT  
 DECLARE @ChoiceOptionText NVARCHAR(1024)  
 DECLARE @ProjectId int,@origin nvarchar(2),@sectionId int,@segmentId BIGINT,@mSegmentId int,@mSegmentStatusId INT  
 DECLARE @Description NVARCHAR(1024),@sourceTag VARCHAR(10)  
 DECLARE @segmentDescription NVARCHAR(max)=''  
  
 SELECT   
 @ProjectId=ProjectId,@origin=SegmentOrigin,@sectionId=SectionId,  
 @segmentId=SegmentId,@mSegmentId=mSegmentId,@mSegmentStatusId=mSegmentStatusId  
 FROM dbo.ProjectSegmentStatus with (nolock)  
 WHERE SegmentStatusId=@segmentStatusId  
   
  --All Choices  
 DECLARE @AllChoices TABLE(srNo int,choiceCode bigint);  
  
 --All Choices with Options  
 DECLARE @ChoiceTable TABLE    
 (    
 srNo int,    
 choiceCode bigint,    
 optionJson nvarchar(max),    
 finalChoiceText nvarchar(max),  
 sortOrder int  
 );  
  
 --Single Choice with Options  
 DECLARE @ChoiceTableTemp TABLE    
 (    
 srNo int,    
 choiceCode bigint,    
 optionJson nvarchar(max),    
 optionText nvarchar(max),  
 sortOrder int  
 );  
  
 --All Options in single choice  
 DECLARE @ChoiceOptionTable TABLE    
 (    
 srNo int,    
 OptionTypeName varchar(200),    
 SortOrder int,    
 Value nvarchar(1024),    
 Id int    
 );  
  
 -- Segment Description for given @SegmentId    
 DECLARE @ChoiceCode bigint=0  
 DECLARE @OptionJson nvarchar(max)=''  
 DECLARE @Saperator nvarchar(5)=''  
  
    
   --Step 1 : Get Segment Description based on origin    
   IF(@origin='M')    
   BEGIN  
  select TOP 1 @segmentDescription=SegmentDescription FROM [SLCMaster].[dbo].[Segment] WITH(NOLOCK) where SegmentId=@mSegmentId  
  IF(@segmentDescription like '%{CH#%')  
  BEGIN  
    
  -- All Choice Option for given Segment       
   INSERT INTO @ChoiceTable (srNo, ChoiceCode, optionJson, finalChoiceText,SortOrder)  
    SELECT  
     ROW_NUMBER() OVER (ORDER BY co.ChoiceOptionId) AS Id  
       ,sc.SegmentChoiceCode  
       ,co.OptionJson  
       ,''  
       ,co.SortOrder  
    FROM [SLCMaster].[dbo].[SegmentChoice] AS sc  with (nolock)  
    INNER JOIN [SLCMaster].[dbo].[ChoiceOption] AS co  with (nolock)  
     ON sc.SegmentChoiceId = co.SegmentChoiceId  
    INNER JOIN [SelectedChoiceOption] sco  with (nolock)  
     ON  sco.SectionId=@sectionId  
      AND sco.ChoiceOptionCode = co.ChoiceOptionCode  
      AND sco.SegmentChoiceCode = sc.SegmentChoiceCode  
    WHERE sc.SegmentStatusId=@mSegmentStatusId  
    AND sco.SectionId=@sectionId  
    AND sco.ProjectId=@ProjectId  
    AND sco.IsSelected = 1   
    AND sco.ChoiceOptionSource='M'  
    ORDER BY co.SortOrder;  
  
    INSERT INTO @AllChoices  
    SELECT distinct ROW_NUMBER() OVER (ORDER BY ChoiceCode) AS Id,* from  
    (  
    select distinct ChoiceCode from @ChoiceTable  
    ) as x  
  
    --Get count of All Choices  
    SET @ChoiceCount=(SELECT COUNT(1) FROM @AllChoices)  
  
    WHILE(@ChoiceCounter<=@ChoiceCount)  
    BEGIN  
     SELECT @ChoiceCode=choiceCode FROM @AllChoices WHERE srNo=@ChoiceCounter  
     SELECT TOP 1 @Saperator=IIF(ChoiceTypeId=2,' and ',IIF(ChoiceTypeId=3,' or ',''))  
      from [SLCMaster].[dbo].[SegmentChoice]  with (nolock)   
      where SegmentStatusId=@mSegmentStatusId  
      and SegmentChoiceCode=@choiceCode  
     --CLEAR @ChoiceTableTemp  
     DELETE FROM @ChoiceTableTemp  
     --Get all options  
     INSERT INTO @ChoiceTableTemp  
     SELECT  ROW_NUMBER() OVER (ORDER BY sortOrder ) AS Id,*  
     FROM (  
     SELECT DISTINCT ChoiceCode, optionJson, finalChoiceText,sortOrder FROM @ChoiceTable   
     WHERE choiceCode=@ChoiceCode) as x  
  
     SET @optionCount=@@rowcount  
     SET @OptionCounter=1  
   
     --Iterate options  
     WHILE(@OptionCounter<=@optionCount)  
     BEGIN  
      SELECT @OptionJson=optionJson FROM @ChoiceTableTemp WHERE srNo=@OptionCounter  
  
      --CLEAR @ChoiceOptionTable  
      DELETE FROM @ChoiceOptionTable  
      --Get all items in options  
      INSERT INTO @ChoiceOptionTable  
      SELECT ROW_NUMBER() OVER (ORDER BY [SortOrder]) AS srNo,* FROM OPENJSON(@OptionJson)  
      WITH (  
       OptionTypeName NVARCHAR(200) '$.OptionTypeName',  
       [SortOrder] INT '$.SortOrder',  
       [Value] NVARCHAR(255) '$.Value',  
       [Id] INT '$.Id'  
      );  
  
      SET @ItemCount=@@rowcount  
      SET @ItemCounter=1  
      SET @ChoiceOptionText=''  
    
      --Iterate all items  
      WHILE(@ItemCounter<=@ItemCount)  
      BEGIN  
       SELECT  
         @OptionTypeName = OptionTypeName  
        ,@SortOrder = SortOrder  
        ,@Value = Value  
        ,@Id = Id  
       FROM @ChoiceOptionTable  
       WHERE srNo = @ItemCounter  
  
       IF (@OptionTypeName IN('CustomText','NoneNA','GlobalTerm', 'UnitOfMeasure'))  
       BEGIN  
        SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,' ', @Value,' ')  
       END   
       ELSE IF (@OptionTypeName IN('FillInBlank'))  
       BEGIN  
        IF(@Value='' OR @Value is null)  
         SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, ' [_______] ')  
        ELSE   
         SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')  
       END   
         
       ELSE IF(@OptionTypeName='SectionID')    
       BEGIN  
        SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, (SELECT  
         SourceTag  
        FROM SLCMaster.dbo.Section WITH (NOLOCK)  
        WHERE sectionid = @Id),' ')  
       END    
       ELSE IF(@OptionTypeName='ReferenceStandard')    
       BEGIN  
        SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')  
    
       END    
       ELSE IF(@OptionTypeName='ReferenceEditionDate')    
       BEGIN  
        SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value, '')  
       END    
       ELSE IF(@OptionTypeName='SectionTitle')    
       BEGIN  
        SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, (SELECT  
         Description FROM SLCMaster.dbo.Section WITH (NOLOCK) WHERE sectionid = @Id),' '  
        )  
       END  
       SET @ItemCounter=@ItemCounter+1  
      END  
    
      UPDATE @ChoiceTableTemp  
      SET optionText=@ChoiceOptionText  
      WHERE srNo=@OptionCounter and ChoiceCode=@ChoiceCode  
       
      SET @OptionCounter=@OptionCounter+1  
     END  
  
     --set @ChoiceOptionText=(SELECT optionText+',' FROM @ChoiceTableTemp WHERE choiceCode=@ChoiceCode FOR XML PATH(''))  
     DECLARE @count int,@i int=2  
  
     SELECT @count=count(1) FROM @ChoiceTableTemp  
     SELECT TOP 1 @ChoiceOptionText=optionText FROM @ChoiceTableTemp  
     WHILE (@i<@count)  
     BEGIN  
      SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,', ',(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))  
      SET @i=@i+1  
     END  
  
     IF(@count>1)  
     SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,@Saperator,(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))  
  
     SET @segmentDescription = REPLACE(@segmentDescription, CONCAT('{CH#', @choiceCode, '}'), @ChoiceOptionText)  
  
     SET @ChoiceCounter=@ChoiceCounter+1  
    END  
   END  
    END    
    ELSE IF(@origin='U')    
    BEGIN  
   select TOP 1 @segmentDescription=SegmentDescription FROM [dbo].[ProjectSegment] WITH(NOLOCK) where SegmentId=@segmentId and SectionId=@SectionId   
     
   IF(@segmentDescription like '%{CH#%')  
   BEGIN  
  
   -- store all choices WITH OPTIONS  
   INSERT INTO @ChoiceTable (srNo, ChoiceCode, optionJson, finalChoiceText,sortOrder)  
   SELECT    
   ROW_NUMBER() OVER (ORDER BY co.ChoiceOptionId) AS Id  
   ,sc.SegmentChoiceCode  
   ,co.OptionJson  
   ,''     
   ,co.SortOrder  
   FROM [ProjectSegmentChoice] AS sc  with (nolock)  
   INNER JOIN [ProjectChoiceOption] AS co with (nolock)  
   ON co.SectionId = sc.SectionId  
   and sc.SegmentChoiceId = co.SegmentChoiceId  
   INNER JOIN [SelectedChoiceOption] sco with (nolock)  
   ON sco.SectionId = sc.SectionId  
   AND sco.ProjectId = sc.ProjectId  
   AND sco.SegmentChoiceCode = sc.SegmentChoiceCode  
   and sco.ChoiceOptionCode=co.ChoiceOptionCode  
   WHERE sc.SectionId=@sectionId and    
   sc.SegmentStatusId=@segmentStatusId  
   AND sco.IsSelected = 1  and sco.ChoiceOptionSource='U'  
   ORDER BY co.SortOrder,sc.SegmentChoiceCode;  
  
   --GET ALL CHOICES WITHOUT OPTIONS  
   INSERT INTO @AllChoices  
   SELECT distinct ROW_NUMBER() OVER (ORDER BY ChoiceCode) AS Id,* from  
   (  
   select distinct ChoiceCode from @ChoiceTable  
   ) as x  
  
   --Get count of All Choices  
   SET @ChoiceCount=(SELECT COUNT(1) FROM @AllChoices)  
   --Iterate choices  
   WHILE(@ChoiceCounter<=@ChoiceCount)  
   BEGIN  
    SELECT @ChoiceCode=choiceCode FROM @AllChoices WHERE srNo=@ChoiceCounter  
    SELECT TOP 1 @Saperator=IIF(ChoiceTypeId=2,' and ',IIF(ChoiceTypeId=3,' or ',''))   
    from [dbo].[ProjectSegmentChoice] with (nolock)  
    where SectionId=@sectionId and SegmentStatusId=@segmentStatusId  
    AND SegmentChoiceCode=@choiceCode  
  
    --CLEAR @ChoiceTableTemp  
    DELETE FROM @ChoiceTableTemp  
    --Get all options  
    --INSERT INTO @ChoiceTableTemp  
    --SELECT ROW_NUMBER() OVER (ORDER BY srNo) AS Id,ChoiceCode, optionJson, finalChoiceText FROM @ChoiceTable WHERE choiceCode=@ChoiceCode  
    INSERT INTO @ChoiceTableTemp  
    SELECT  ROW_NUMBER() OVER (ORDER BY sortOrder ) AS Id,*  
    FROM (  
    SELECT DISTINCT ChoiceCode, optionJson, finalChoiceText,sortOrder FROM @ChoiceTable WHERE choiceCode=@ChoiceCode) as x  
  
    SET @optionCount=@@rowcount  
    SET @OptionCounter=1  
       
    --Iterate options  
    WHILE(@OptionCounter<=@optionCount)  
    BEGIN  
     SELECT @OptionJson=optionJson FROM @ChoiceTableTemp WHERE srNo=@OptionCounter  
  
     --CLEAR @ChoiceOptionTable  
     DELETE FROM @ChoiceOptionTable  
     --Get all items in options  
     INSERT INTO @ChoiceOptionTable  
     SELECT ROW_NUMBER() OVER (ORDER BY [SortOrder]) AS srNo,* FROM OPENJSON(@OptionJson)  
     WITH (  
      OptionTypeName NVARCHAR(200) '$.OptionTypeName',  
      [SortOrder] INT '$.SortOrder',  
      [Value] NVARCHAR(255) '$.Value',  
      [Id] INT '$.Id'  
     );  
  
     SET @ItemCount=@@rowcount  
     SET @ItemCounter=1  
     SET @ChoiceOptionText=''  
    
     --Iterate all items  
     WHILE(@ItemCounter<=@ItemCount)  
     BEGIN  
      SELECT  
        @OptionTypeName = OptionTypeName  
       ,@SortOrder = SortOrder  
       ,@Value = Value  
       ,@Id = Id  
      FROM @ChoiceOptionTable  
      WHERE srNo = @ItemCounter  
  
      IF (@OptionTypeName IN('CustomText','NoneNA','GlobalTerm', 'UnitOfMeasure'))  
      BEGIN  
       SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,' ', @Value,' ')  
      END   
      ELSE IF (@OptionTypeName IN('FillInBlank'))  
      BEGIN  
       IF(@Value='' OR @Value is null)  
        SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, ' [_______] ')  
       ELSE   
        SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')  
      END   
      ELSE IF(@OptionTypeName='SectionID')    
      BEGIN  
       SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,@Value,' ')  
       --set @sourceTag=(SELECT  
       --SourceTag  
       --FROM [SLCProject].[dbo].[ProjectSection]  
       --WHERE sectionid = @Id and ProjectId=@ProjectId)  
  
       --SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,iif(@sourceTag is null OR LEN(@sourceTag)<=0,(SELECT  
       -- SourceTag  
       --FROM SLCMaster.dbo.Section  
       --WHERE sectionid = @Id),@sourceTag)  
       --)  
    
      END    
      ELSE IF(@OptionTypeName='ReferenceStandard')    
      BEGIN  
       SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,' ')  
    
      END    
      ELSE IF(@OptionTypeName='ReferenceEditionDate')    
      BEGIN  
    
       SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, @Value,'')  
    
      END    
      ELSE IF(@OptionTypeName='SectionTitle')    
      BEGIN  
  
      SET @Description=(SELECT  
       Description  
       FROM [ProjectSection] with (nolock)  
       WHERE sectionid = @Id and ProjectId=@ProjectId)  
  
       SET @ChoiceOptionText = CONCAT(@ChoiceOptionText,iif(@Description is null,(SELECT  
        Description  
       FROM SLCMaster.dbo.Section WITH (NOLOCK)  
       WHERE sectionid = @Id),@Description),' '  
       )  
       --SET @ChoiceOptionText = CONCAT(@ChoiceOptionText, (SELECT  
       --Description  
       --FROM [SLCProject].[dbo].[ProjectSection]  
       --WHERE sectionid = @Id)  
       --)  
    
      END  
       
      SET @ItemCounter=@ItemCounter+1  
     END  
    
     UPDATE @ChoiceTableTemp  
     SET optionText=@ChoiceOptionText  
     WHERE srNo=@OptionCounter and ChoiceCode=@ChoiceCode  
  
     SET @OptionCounter=@OptionCounter+1  
    END  
  
      
    SELECT @count=count(1) FROM @ChoiceTableTemp  
    SELECT TOP 1 @ChoiceOptionText=optionText FROM @ChoiceTableTemp  
    WHILE (@i<@count)  
    BEGIN  
     SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,', ',(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))  
     SET @i=@i+1  
    END  
  
    IF(@count>1)  
    SET @ChoiceOptionText=CONCAT(@ChoiceOptionText,@Saperator,(SELECT optionText FROM @ChoiceTableTemp WHERE srNo=@i))  
              
    SET @segmentDescription = REPLACE(@segmentDescription, CONCAT('{CH#', @choiceCode, '}'), @ChoiceOptionText)  
  
    SET @ChoiceCounter=@ChoiceCounter+1  
   END  
   END  
    END  
    
   return @segmentDescription;  
   
END  
GO


