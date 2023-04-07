-- Please execute this script on server 02

use SLCProject_SqlSlcOp002
go
UPDATE PR SET PrintStatus = 'Failed' , IsDeleted = 1 FROM 
PrintRequestDetails PR WITH(NOLOCK) WHERE PrintRequestId = 52208;