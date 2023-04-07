--Server 04
--72368 - SLC Choice Fields Data Issue
-- Starting with initial SegmentId as per the table

DECLARE @SegmentIdIterator AS BIGINT = 342072016
DECLARE @CustomerID as int = 2853
DECLARE @ProjectId AS BIGINT = 24733
DECLARE @SectionId AS BIGINT= 30141024
DECLARE @SegmentChoiceCodeLower AS BIGINT = 10001300
DECLARE @SegmentChoiceCodeUpper AS BIGINT = 10001314
DECLARE @ChoiceOptionCodeLower AS BIGINT = 10001401
DECLARE @ChoiceOptionCodeUpper AS BIGINT = 10001415


--Update IsDeleted flags
UPDATE [dbo].[SelectedChoiceOption] 
SET IsDeleted=0 
WHERE CustomerId=@Customerid and ProjectID=@ProjectId and SectionId = @SectionId 
AND  SegmentChoiceCode >= @SegmentChoiceCodeLower 
AND SegmentChoiceCode <= @SegmentChoiceCodeUpper

UPDATE [dbo].[ProjectChoiceOption]
SET IsDeleted=0 
WHERE CustomerId=@Customerid and ProjectID=@ProjectId and SectionId = @SectionId 
AND ChoiceOptionCode >= @ChoiceOptionCodeLower 
AND ChoiceOptionCode <= @ChoiceOptionCodeUpper

UPDATE [dbo].[ProjectSegmentChoice] 
SET IsDeleted=0 
WHERE CustomerId=@Customerid and ProjectID=@ProjectId and SectionId = @SectionId 
AND SegmentChoiceCode >= @SegmentChoiceCodeLower 
AND SegmentChoiceCode <= @SegmentChoiceCodeUpper

--SELECT * FROM ProjectSegmentStatus WHERE ProjectId = @ProjectId AND SectionId = @SectionId ORDER BY SequenceNumber


---------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------SPECIFIC SCRIPT--------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------

Update ProjectSegmentChoice SET SegmentId=342072032,SegmentStatusId=1841044247 WHERE SegmentChoiceCode=​​​​10001303​​​​ AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072031,SegmentStatusId=1841044246 WHERE SegmentChoiceCode=​​​​10001300​​​​ AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072029,SegmentStatusId=1841044245 WHERE SegmentChoiceCode=​​​10001304​​​ AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072027,SegmentStatusId=1841044244 WHERE SegmentChoiceCode=​​​10001305​​​ AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072026,SegmentStatusId=1841044243 WHERE SegmentChoiceCode=​​​10001306​​​ AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072025,SegmentStatusId=1841044242 WHERE SegmentChoiceCode=​​​10001307 AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072024,SegmentStatusId=1841044241 WHERE SegmentChoiceCode=​​​10001308​​​ AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072023,SegmentStatusId=1841044240 WHERE SegmentChoiceCode=​​​10001309​​​ AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072022,SegmentStatusId=1841044239 WHERE SegmentChoiceCode=10001310 AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072021,SegmentStatusId=1841044238 WHERE SegmentChoiceCode=​​​10001311​​​ AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072020,SegmentStatusId=1841044237 WHERE SegmentChoiceCode=​​​10001312​​​ AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072018,SegmentStatusId=1841044236 WHERE SegmentChoiceCode=​​​10001314​​​ AND projectid=@ProjectId AND sectionid=@SectionId
Update ProjectSegmentChoice SET SegmentId=342072017,SegmentStatusId=1841044235 WHERE SegmentChoiceCode=10001301 AND projectid=@ProjectId AND sectionid=@SectionId

