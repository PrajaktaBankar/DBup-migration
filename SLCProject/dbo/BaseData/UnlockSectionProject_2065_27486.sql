----------Server 3 ------------

-----For Unlock Section --------

Use SLCProject
go

update ProjectSection set IsLocked = 0,LockedBy=0,LockedByFullName='' 
where ProjectId=2065 and SourceTag='071327' and IsLocked = 1

