Use [SLCProject]
Go 

----------Server 2 ------------

-----For Unlock Section --------
update ProjectSection set IsLockedImportSection=0 where 
ProjectId=2205 and IsLockedImportSection =1


update ProjectSection set IsLocked=0 where 
ProjectId=2205 and SourceTag='017800' and IsLocked=1