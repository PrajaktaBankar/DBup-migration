USE [SLCProject_SqlSlcOp004]
GO
DECLARE @ProjectId INT = 20047 ;
DECLARE @SegmentTable TABLE  
	(  
	rowNo int,  
	SegmentId int,  
	SegmentStatusId INT,  
	SectionId INT,
	ProjectId int,
	CustomerId INT,
	SegmentDescription varchar(max),
	IsDeleted bit
	);
				
INSERT INTO @SegmentTable (rowNo, SegmentId, SegmentStatusId, SectionId,ProjectId,CustomerId,SegmentDescription,IsDeleted)
	SELECT
	ROW_NUMBER() OVER (ORDER BY PS.SegmentId) AS rowNo
	,PS.SegmentId
	,PS.SegmentStatusId
	,PS.SectionId
	,PS.ProjectId
	,PS.CustomerId
	,PS.SegmentDescription
	,PS.IsDeleted
	FROM ProjectSegment PS WITH(NOLOCK)
	WHERE 
     ProjectId = @ProjectId 
    AND ISNULL(IsDeleted,0)=0
    AND SegmentDescription like '%style="color: rgb(65, 65, 65)%' 


DECLARE @count INT;
SET @count = 1;
DECLARE @TotalCount INT = (SELECT count(*) FROM @SegmentTable)
DECLARE @Descr VARCHAR(MAX) =''
    
WHILE @count<= @TotalCount
BEGIN
   PRINT @count
   SET @Descr = (Select SegmentDescription From	@SegmentTable WHERE rowNo = @count)
   UPDATE @SegmentTable  
   SET SegmentDescription = REPLACE(REPLACE(REPLACE(REPLACE(SegmentDescription, 'style="color: rgb(65, 65, 65); font-family: Arial; font-size: 13.3333px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: left; text-indent: 0px; text-transform: none; white-space: normal; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; background-color: rgb(242, 242, 242); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; display: inline !important; float: none;"',''),'style="color: rgb(65, 65, 65); font-family: Arial; font-size: 13.3333px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: left; text-indent: 0px; text-transform: none; white-space: pre-wrap; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; background-color: rgb(255, 255, 255); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; display: inline !important; float: none;',''),'style="color: rgb(65, 65, 65); font-family: Arial; font-size: 13.3333px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-align: left; text-indent: 0px; text-transform: none; white-space: pre-wrap; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; background-color: rgb(242, 242, 242); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; display: inline !important; float: none;"',''),'style="color: rgb(65, 65, 65); font-family: Arial; font-size: 13.3333px; font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 700; letter-spacing: normal; orphans: 2; text-align: left; text-indent: 0px; text-transform: uppercase; white-space: pre-wrap; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; background-color: rgb(242, 242, 242); text-decoration-thickness: initial; text-decoration-style: initial; text-decoration-color: initial; display: inline !important; float: none;"','')
   WHERE rowNo = @count

   SET @count = @count + 1;
END;


UPDATE PS SET PS.SegmentDescription =
temp.SegmentDescription
 FROM ProjectSegment PS WITH(NOLOCK)
INNER JOIN  @SegmentTable  temp
ON PS.SegmentId = temp.SegmentId

