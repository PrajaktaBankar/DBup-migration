/*
 server name : SLCProject_SqlSlcOp003
 Customer Support 42832: Incorrect Section ID 096512 in Division 6 export (NWL Architects)

 ---For references-----
  
*/

UPDATE ProjectSection SET DivisionId=11,DivisionCode=09 
WHERE SourceTag='096512'
AND IsDeleted=0
AND CustomerId=375
