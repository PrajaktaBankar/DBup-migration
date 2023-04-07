
/*

SLC

Run on server 0 and Server 1


select * from SLCMasterStaging..GlobalTermStaging where MasterDataTypeId=1 order by Old_GlobalChoiceID desc
select * from SLCMaster..GlobalTerm where MasterDataTypeId=1 order by globaltermid desc

*/



declare @CreatedDate datetime=getutcdate()

set identity_insert slcmasterstaging..globaltermstaging on

Insert into SLCMasterStaging..GlobalTermStaging( GlobalTermId,[MasterDataTypeId],[Name],[Value],[GlobalTermCode],[CreateDate],[ModifiedDate],[PkGlobalChoicesID],[Old_GlobalChoiceID]
           ,[Action],[updold_name],[updold_value])
values (23, 1, 'Design Professional''s Project Number', 'Design Professional''s Project Number', 23, @CreatedDate, @CreatedDate, 23, 30, NULL, NULL, NULL)
,(24, 1, 'Construction Manager', 'Construction Manager', 24, @CreatedDate, @CreatedDate, 24, 31, NULL, NULL, NULL)
,(25, 1, 'Construction Manager''s Project Number', 'Construction Manager''s Project Number', 25, @CreatedDate, @CreatedDate, 25, 32, NULL, NULL, NULL)
,(26, 1, 'Design-Builder''s Project Number', 'Design-Builder''s Project Number', 26, @CreatedDate, @CreatedDate, 26, 33, NULL, NULL, NULL)
,(27, 1, 'Date of Substantial Completion', 'mm-dd-yyyy', 27, @CreatedDate, @CreatedDate, 27, 34, NULL, NULL, NULL)

set identity_insert slcmasterstaging..globaltermstaging off

go

declare @CreatedDate datetime=getutcdate()

set identity_insert SLCMaster..Globalterm on

Insert into SLCMaster..Globalterm( GlobalTermId,[MasterDataTypeId],[Name],[Value],[GlobalTermCode],[CreateDate],[ModifiedDate], GlobalTermFieldTypeId)
values (23, 1, 'Design Professional''s Project Number', 'Design Professional''s Project Number', 23, @CreatedDate, @CreatedDate, 1)
,(24, 1, 'Construction Manager', 'Construction Manager', 24, @CreatedDate, @CreatedDate, 1)
,(25, 1, 'Construction Manager''s Project Number', 'Construction Manager''s Project Number', 25, @CreatedDate, @CreatedDate,1)
,(26, 1, 'Design-Builder''s Project Number', 'Design-Builder''s Project Number', 26, @CreatedDate, @CreatedDate,1)
,(27, 1, 'Date of Substantial Completion', 'mm-dd-yyyy', 27, @CreatedDate, @CreatedDate,2)

set identity_insert SLCMaster..globalterm off


