

CREATE PROCEDURE usp_UpdateStatusForBatchPrintProcess        
AS        
BEGIN        
  DROP TABLE IF EXISTS #ProjectExportTableVar           
  CREATE TABLE #ProjectExportTableVar (          
   ProjectExportId INT,         
   ProjectId INT,            
   CustomerId INT        
  )           
        
  DROP TABLE IF EXISTS #PrintRequestDetailstTableVar          
  CREATE TABLE #PrintRequestDetailstTableVar(          
  PrintRequestId INT,         
  ProjectId INT,            
  CustomerId INT        
  )         
        
  INSERT INTO #ProjectExportTableVar        
  Select ProjectExportId,ProjectId,CustomerId from ProjectExport WITH (NOLOCK) where  DATEDIFF(MONTH, CreatedDate, GETUTCDATE()) <6 and FileStatus='In Progress'  and  DATEDIFF(MINUTE, CreatedDate, GETUTCDATE()) >120          
        
  INSERT INTO #PrintRequestDetailstTableVar        
  Select PrintRequestId,ProjectId,CustomerId from PrintRequestDetails WITH (NOLOCK) where  DATEDIFF(MONTH, CreatedDate, GETUTCDATE()) <6 and PrintStatus='In Progress'  and DATEDIFF(MINUTE, CreatedDate, GETUTCDATE()) >120        
        
   UPDATE PE            
   SET PE.FileStatus = 'Failed',PE.PrintFailureReason='Print Request Terminated Automatically'         
   from ProjectExport PE WITH (NOLOCK) INNER JOIN #ProjectExportTableVar PETV         
   ON PE.ProjectExportId=PETV.ProjectExportId and PE.ProjectId=PETV.ProjectId and PE.CustomerId=PETV.CustomerId         
        
   UPDATE PRD            
   SET PRD.PrintStatus = 'Failed', PRD.PrintFailureReason='Print Request Terminated Automatically'       
   from PrintRequestDetails PRD WITH (NOLOCK) INNER JOIN #PrintRequestDetailstTableVar PETV         
   ON PRD.PrintRequestId=PETV.PrintRequestId and PRD.ProjectId=PETV.ProjectId and PRD.CustomerId=PETV.CustomerId         
        
 END