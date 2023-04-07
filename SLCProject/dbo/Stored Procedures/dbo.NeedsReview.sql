CREATE PROCEDURE [dbo].[NeedsReview]
  @projectId     INT null,
  @sectionId     int NULL,
  @customerId    int NULL,
  @userId        int NULL=0,
  @CatalogueType nvarchar (50) NULL='FS'
AS
  BEGIN
	DECLARE @PprojectId     INT = @projectId;
	DECLARE @PsectionId     int = @sectionId;
	DECLARE @PcustomerId    int = @customerId;
	DECLARE @PuserId        int = @userId;
	DECLARE @PCatalogueType nvarchar (50) = @CatalogueType;
    DECLARE @SEGMENTDETAILS TABLE
                                  (
                                                                segmentstatusid       bigint,
                                                                parentsegmentstatusid bigint,
                                                                sectionid             int,
                                                                msectionid            int,
                                                                segmentid             bigint,
                                                                msegmentid            int,
                                                                msegmentstatusid      int,
                                                                indentlevel           int,
                                                                segmentsource         char(1),
                                                                segmentorigin         char(2),
                                                                rownumber             int,
                                                                actionname            varchar(100),
                                                                sequencenumber        varchar(50),
                                                                projectid             int,
                                                                mastersegmentisdelete bit,
                                                                messagedescription    varchar(100)
                                  )
    DECLARE @SegmentStatusId    bigint=0;
    DECLARE @InitialParentFlag  int=1
    DECLARE @InitialRecordCount int=0
    DECLARE @InitialChildFlag   int=1
    DECLARE @IndentLevel        int=0
    SELECT     pss.segmentstatusid,
               row_number() OVER(ORDER BY pss.segmentstatusid) AS rownumber
    INTO       #temp
    FROM       slcmaster..segmentstatus ss  with(noLock)
    INNER JOIN projectsegmentstatus pss with(noLock)
    ON         ss.segmentstatusid=pss.msegmentstatusid
    WHERE      ss.isdeleted=1
    AND        isnull(pss.isdeleted,0)=0
    AND        pss.projectid=@PprojectId
    AND        pss.sectionid=@PsectionId
    AND        pss.customerid=@PcustomerId

    SELECT @InitialRecordCount=count(1)
    FROM   #temp
    IF (@InitialRecordCount>0)
    BEGIN
      WHILE @InitialParentFlag <= @InitialRecordCount
      BEGIN
	  PRINT @InitialParentFlag
	  SELECT @SegmentStatusId=segmentstatusid FROM #temp where rownumber=@InitialParentFlag
           
	   
       ; WITH parent AS
        (
               SELECT c1.segmentstatusid,
                      c1.parentsegmentstatusid,
                      c1.sectionid,
                      -- c1.segmentid,
                      isnull(c1.msegmentid,0)       AS msegmentid,
                      isnull(c1.segmentid,0)        AS segmentid,
                      isnull(c1.msegmentstatusid,0) AS msegmentstatusid,
                      c1.indentlevel,
                      c1.segmentsource,
                      c1.segmentorigin,
                      c1.projectid,
                      c1.customerid,
                      c1.sequencenumber
               FROM   projectsegmentstatus c1 WITH (NOLOCK)
               WHERE  c1.segmentstatusid = @SegmentStatusId
               UNION ALL
               SELECT     c2.segmentstatusid,
                          c2.parentsegmentstatusid,
                          c2.sectionid,
                          -- c2.segmentid,
                          isnull(c2.msegmentid,0)       AS msegmentid,
                          isnull(c2.segmentid,0)        AS segmentid,
                          isnull(c2.msegmentstatusid,0) AS msegmentstatusid,
                          c2.indentlevel,
                          c2.segmentsource,
                          c2.segmentorigin,
                          c2.projectid,
                          c2.customerid,
                          c2.sequencenumber
               FROM       projectsegmentstatus c2 WITH (NOLOCK)
               INNER JOIN parent
               ON         parent.segmentstatusid = c2.parentsegmentstatusid)
        INSERT INTO @SegmentDetails
                    (
                                segmentstatusid,
                                parentsegmentstatusid,
                                sectionid,
                                segmentid,
                                msegmentid,
                                msegmentstatusid,
                                indentlevel,
                                segmentsource,
                                segmentorigin,
                                rownumber,
                                sequencenumber
                    )
        SELECT   segmentstatusid,
                 parentsegmentstatusid,
                 sectionid,
                 segmentid,
                 msegmentid,
                 msegmentstatusid,
                 indentlevel,
                 segmentsource,
                 segmentorigin,
                 row_number() OVER(ORDER BY segmentstatusid) AS rownumber,
                 sequencenumber
        FROM     parent 
        SELECT @IndentLevel=indentlevel
        FROM   @SegmentDetails
        WHERE  segmentstatusid=@SegmentStatusId
        DECLARE @site_value                int;
        declare @CurrentSegmentStatusId    bigint=0;
        declare @MessageDescription        varchar(100);
        declare @IndentLevelIterationCount int
        SELECT @IndentLevelIterationCount=count(segmentstatusid)
        FROM   @SegmentDetails
        WHERE  segmentstatusid=@SegmentStatusId
        SET @site_value = 1;
        if EXISTS
        (
               SELECT top 1 1 
               FROM   @SegmentDetails
               WHERE  indentlevel > @IndentLevel)
        BEGIN
          WHILE @site_value <= @IndentLevelIterationCount
          BEGIN
            SELECT @CurrentSegmentStatusId=segmentstatusid
            FROM   @SegmentDetails
            WHERE  rownumber=@site_value
            SELECT @MessageDescription=','+sequencenumber
            FROM   @SegmentDetails
            WHERE  rownumber=@site_value
            UPDATE @SegmentDetails
            SET    messagedescription=@MessageDescription
            WHERE  segmentstatusid=@SegmentStatusId
            UPDATE @SegmentDetails
            SET    messagedescription=@MessageDescription
            WHERE  parentsegmentstatusid=@SegmentStatusId
                   -- IF EXISTS(SELECT * FROM @SegmentDetails WHERE parentsegmentstatusid = @CurrentSegmentStatusId)
                   -- BEGIN
                   --UPDATE @SegmentDetails SET ActionName='DELETE' WHERE parentsegmentstatusid=@CurrentSegmentStatusId
                   --AND segmentorigin='M' and segmentsource='M' and ActionName!='DELETE'
                   -- END
            SET    @site_value = @site_value + 1;
          
          end;
          update @SegmentDetails
          SET    actionname='NEED_TO_PROMOTE'
          SELECT  Sd.RowNumber,
          Sd.parentsegmentstatusid,
          Sd.msegmentid AS MSegmentId,
           Sd.msegmentstatusid AS MSegmentStatusId,
           Sd.segmentstatusid AS PSegmentStatusId,
           S.SectionId AS MSectionId,
           Sd.sectionid AS PSectionId,
           Sd.segmentsource AS SegmentSource,
           S.SegmentCode AS SegmentCode,
           S.SegmentDescription AS SegmentDescription,
           Sd.ActionName,
           Sd.SequenceNumber,
           Sd.segmentorigin AS SegmentOrigine,
           Sd.SegmentId AS PSegmentId,
           cast(1 as bit) as MasterSegmentIsDelete,
           Sd.MessageDescription INTO #FinalSegmentDetails
           FROM @SegmentDetails Sd INNER JOIN SLCMaster..Segment S
          ON Sd.msegmentstatusid=S.SegmentStatusId AND S.SegmentId=Sd.msegmentid
        END
		ELSE IF EXISTS(SELECT top 1 1
               FROM   @SegmentDetails
               WHERE  segmentsource='M' AND segmentorigin='M' AND segmentstatusid=@SegmentStatusId)
			   BEGIN
				PRINT 'bsc'
			   END
		
		SET @InitialParentFlag = @InitialParentFlag + 1;
      END
    END

	select * from #FinalSegmentDetails
  END
GO


