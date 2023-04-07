USE SLCProject

GO

CREATE PROC [dbo].[usp_SendEmailCopyProjectFailedJob]
(
@recipients VARCHAR(Max)=''
)
AS
BEGIN
DROP table IF exists #tempStep
DROP TABLE IF EXISTS #failedProject
DECLARE @profileName NVARCHAR(100)=(SELECT TOP 1 name FROM msdb.dbo.sysmail_profile)
IF(@profileName is not NULL)
BEGIN
SELECT cast('' as nvarchar(255)) as ProjectName , ROW_NUMBER() over(order by RequestId) as RowId,*
into #failedProject FROM CopyProjectRequest WITH(NOLOCK)
where IsEmailSent=0 and StatusId IN(4,5) AND ISNULL(IsDeleted,0)=0 AND CopyProjectTypeId=1

declare @i int=1, @count int=(select count(1) from #failedProject)
IF(@count>0)
BEGIN
set @recipients= 'bsdprodmonitoring@varseno.com';
DECLARE @CustomerId VARCHAR(1000);
DECLARE @projectName VARCHAR(1000);
DECLARE @customerName VARCHAR(1000);
DECLARE @projectId VARCHAR(1000);
DECLARE @userName VARCHAR(1000);
DECLARE @userId VARCHAR(1000);
DECLARE @failedStep VARCHAR(1000);
DECLARE @heading VARCHAR(1000)='Copy Project Process Has';
DECLARE @subtitle VARCHAR(1000) = 'See the copy project failure details below: ';
DECLARE @subject NVARCHAR(100) = 'BSD Copy Project: Failure'
DECLARE @failureTime DateTime = '';
DECLARE @statusDescription VARCHAR(1000)='';



CREATE TABLE #tempStep(StepID INT,StepName NVARCHAR(100))

INSERt into #tempStep VALUES(1,'Project Create')
INSERt into #tempStep VALUES(2,'CopyStart_Step')
INSERt into #tempStep VALUES(3,'CopyGlobalTems_Step')
INSERt into #tempStep VALUES(4,'CopySections_Step')
INSERt into #tempStep VALUES(5,'CopySegmentStatus_Step')
INSERt into #tempStep VALUES(6,'CopySegments_Step')
INSERt into #tempStep VALUES(7,'CopySegmentChoices_Step')
INSERt into #tempStep VALUES(8,'CopySegmentLinks_Step')
INSERt into #tempStep VALUES(9,'CopyNotes_Step')
INSERt into #tempStep VALUES(10,'CopyImages_Step')
INSERt into #tempStep VALUES(11,'CopyRefStds_Step')
INSERt into #tempStep VALUES(12,'CopyTags_Step')
INSERt into #tempStep VALUES(13,'CopyHeaderFooter_Step')
INSERt into #tempStep VALUES(14,'CopyComplete_Step')


update t
set t.ProjectName=p.Name
from #failedProject t inner join Project p WITH(NOLOCK)
ON p.ProjectId=t.TargetProjectId


DECLARE @Body NVARCHAR(MAX),
@TableHead VARCHAR(1000)='',
@TableTail VARCHAR(1000)='',
@RequsetId int,
@StepId INT

WHILE(@i<=@count)
BEGIN

select @RequsetId=RequestId,@projectName=ProjectName from #failedProject where RowId=@i
set @StepId=(SELECT MAX(CPH.Step) as StepId FROM CopyProjectHistory CPH with(nolock) where cph.Step<14 and CPH.RequestId=@RequsetId) + 1
SELECT @failedStep = StepName FROM #tempStep where StepID=@StepId

SELECT
@CustomerId= ISNULL(CPR.CustomerId,0),
@customerName=ISNULL(CPR.CustomerName,''),
@userId=ISNULL(CPR.CreatedById,0),
@userName=ISNULL(CPR.UserName,''),
@projectId=ISNULL(CPR.TargetProjectId,0),
@failureTime=ISNULL(CPR.ModifiedDate,''),
@StatusDescription = ISNULL(lu.Name,'')
FROM CopyProjectRequest CPR WITH(NOLOCK) INNER JOIN
CopyProjectHistory CPH WITH(NOLOCK) ON CPR.RequestId = CPH.RequestId
INNER JOIN LuCopyStatus lu WITH(NOLOCK) ON CPR.StatusId = lu.CopyStatusId
WHERE CPH.RequestId = @RequsetId AND ISNULL(CPR.IsDeleted,0)=0
AND CPR.CopyProjectTypeId=1

if(@statusDescription='Aborted')
BEGIN
SET @subject = 'BSD Copy Project: Taking Longer time than expected'
END

SET @Body = '<table style="width:100%; background-color:#fff; " border="0" cellpadding="0" cellspacing="0">
<tbody>
<tr>
<td style="vertical-align:top; " align="center" valign="top">
<table width="654" border="0" cellpadding="0" cellspacing="0" style="text-align:left; border: 1px solid #dedede;
box-shadow: 0 6px 6px #ccc;">
<tbody>
<tr>
<td style="vertical-align:top; padding-top:10px; ">
<table style="width:600px; margin-top:65px; " border="0" cellpadding="0" cellspacing="0">
<tbody>
<tr>
<td style="background-color: #312B7B; vertical-align: top;">
<table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="width:100%; background-color:#fff;">
<tbody>
<tr>
<td style="vertical-align: middle; text-align: center; "><img src="https://bsdspeclink.com/wp-content/uploads/2018/04/bsd-speclink-logo.png" alt="bsd_full_header"></td>
<td align="center"></td>
</tr>
</tbody>
</table>
</td>
</tr>
<tr>
<td style="vertical-align:top; background-color:#FFFFFF;padding:30px 20px 20px; ">
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td valign="top">
<p align="center">
<font size="3" color="#126bb5" style="font-size:18px;border-bottom:2px solid #ccc"><b>{{heading}} {{statusDescription}}</b></font>
</p>
<div style="padding:10px 20px 20px;color:#45555f;font-family:Arial,Verdana,Tahoma,Geneva,sans-serif;font-size:14px;line-height:18px;vertical-align:top;min-height:375px">
<p align="left">
<div style="color:#45555f;">
<br>
{{subtitle}}
</div>
</p><p align="left">
<div>
</p>
<div style="color:#45555f;">Customer ID: <b style="color:#000;font-size:14px">{{CustomerId}}</b></div>
<div style="color:#45555f;">Customer Name: <b style="color:#000;font-size:14px">{{customerName}}</b></div>
<div style="color:#45555f;">Project Name: <b style="color:#000;font-size:14px">{{projectName}}</b></div>
<div style="color:#45555f;">Project ID: <b style="color:#000;font-size:14px">{{projectId}}</b></div>
<div style="color:#45555f;">Username: <b style="color:#000;font-size:14px">{{userName}}</b></div>
<div style="color:#45555f;">User ID: <b style="color:#000;font-size:14px">{{userId}}</b></div>
<div style="color:#45555f;">Failed Step: <b style="color:#000;font-size:14px">{{failedStep}}</b></div>
<div style="color:#45555f;">Failed Type: <b style="color:#000;font-size:14px">{{statusDescription}}</b></div>
<div style="color:#45555f;">Date Time of the process failure: <b style="color: #000; font-size: 14px"> {{failureTime}} </b></div>
</br></br>
<span class="HOEnZb">
<font color="#888888">
</font>
</span>
</div><span class="HOEnZb"><font color="#888888">
</font></span></td></tr></tbody>
</table></td></tr></tbody></table></td></tr></tbody></table>
<span class="HOEnZb"><font color="#888888">
</font></span></td></tr></tbody></table>
</table>
</td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>'

SET @Body = REPLACE(@Body,'{{heading}}',@heading)
SET @Body = REPLACE(@Body,'{{CustomerId}}',@CustomerId)
SET @Body = REPLACE(@Body,'{{projectName}}',isnull(@projectName,''))
SET @Body = REPLACE(@Body,'{{customerName}}',isnull(@customerName,''))
SET @Body = REPLACE(@Body,'{{projectId}}',isnull(@projectId,''))
SET @Body = REPLACE(@Body,'{{userName}}',isnull(@userName,''))
SET @Body = REPLACE(@Body,'{{userId}}',isnull(@userId,''))
SET @Body = REPLACE(@Body,'{{failedStep}}',isnull(@failedStep,''))
SET @Body = REPLACE(@Body,'{{subtitle}}',isnull(@subtitle,''))
SET @Body = REPLACE(@Body,'{{failureTime}}',isnull(convert(varchar, getdate(), 0),''))
SET @Body = REPLACE(@Body,'{{statusDescription}}',ISNULL(@statusDescription,''))


SELECT @Body = @TableHead + ISNULL(@Body, '') + @TableTail
BEGIN try
EXEC msdb.dbo.sp_send_dbmail
@profile_name = @profileName
, @recipients = @recipients
, @subject = @subject
, @body=@Body
,@body_format = 'HTML';
END TRY
BEGIN CATCH
END CATCH
UPDATE CPR SET CPR.IsEmailSent= 1 FROM CopyProjectRequest CPR with(nolock) WHERE CPR.RequestId=@RequsetId
set @i=@i+1
END
END
END
END