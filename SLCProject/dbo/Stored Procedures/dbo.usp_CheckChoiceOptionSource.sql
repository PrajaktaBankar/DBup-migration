CREATE PROCEDURE [dbo].[usp_CheckChoiceOptionSource]    

@projectid INT,
@sectionid INT,
@customerid INT,
@segmentchoiceid BIGINT,
@ChoiceOptionCode BIGINT

AS    
BEGIN   
DECLARE @Pprojectid INT = @projectid;
DECLARE @Psectionid INT = @sectionid;
DECLARE @Pcustomerid INT = @customerid;
DECLARE @Psegmentchoiceid BIGINT = @segmentchoiceid;
DECLARE @PChoiceOptionCode BIGINT = @ChoiceOptionCode;
--Set Nocount On
Set Nocount on;
 
			SELECT ChoiceOptionId 
				FROM 
					[ProjectChoiceOption] WITH(NoLock)
				WHERE 
					projectId=@Pprojectid AND 
					SectionId=@Psectionid AND 
					SegmentChoiceid=@Psegmentchoiceid AND 
					CustomerId=@Pcustomerid AND  
					ChoiceOptionCode=@PChoiceOptionCode AND
					ChoiceOptionSource='U' 

END
GO


