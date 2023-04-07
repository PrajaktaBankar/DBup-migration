--Execute it on server 5
USE SLCProject_SqlSlcOp005
Go

UPDATE  PS 
SET PS.SegmentDescription ='<span akgd="1" akgdvalue="BLUEFINLLC" contenteditable="false">{GT#10000024}</span>'
FROM ProjectSegment PS With(NOLOCK)
WHERE  PS.CustomerId = 1033 AND
PS.SegmentDescription = '<span akgd="1" akgdvalue="BLUEFINLLC" contenteditable="false">{GT#10000023}</span>'
AND PS.ProjectId IN(2700,2699,2689,2687,2668,2621,2616)