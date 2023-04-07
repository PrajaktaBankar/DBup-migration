
--• Design Professional’s Project Number  (This text field should be alphanumeric and capable of accepting up to 64 characters)
--• Construction Manager
--• Construction Manager’s Project Number (This text field should be alphanumeric and capable of accepting up to 64 characters)
--• Design-Builder’s Project Number (This text field should be alphanumeric and capable of accepting up to 64 characters)
--• Date of Substantial Completion (obviously a date field, similar to existing date fields)

--select * from SLE_Master..GlobalChoices order by GlobalChoiceID desc
--select * from Staging_Master..GlobalChoices order by GlobalChoiceID desc
--select * from SLE_Publication..GlobalChoices order by GlobalChoiceID desc

declare @CreatedDate as datetime = getdate()

Insert into SLE_Master.dbo.GlobalChoices(GlobalChoiceID, Name, [Description], LastChange, Source, SortOrder)
values (30, 'Design Professional''s Project Number', 'Design Professional''s Project Number', @CreatedDate, 'M', 240)	
,(31, 'Construction Manager', 'Construction Manager', @CreatedDate, 'M', 250)	
,(32, 'Construction Manager''s Project Number', 'Construction Manager''s Project Number', @CreatedDate, 'M', 260)
,(33, 'Design-Builder''s Project Number', 'Design-Builder''s Project Number', @CreatedDate, 'M', 270)
,(34, 'Date of Substantial Completion', 'Date of Substantial Completion', @CreatedDate, 'M', 280)

Insert into Staging_Master.dbo.GlobalChoices(GlobalChoiceID, Name, [Description], LastChange, Source, SortOrder)
values (30, 'Design Professional''s Project Number', 'Design Professional''s Project Number', @CreatedDate, 'M', 240)	
,(31, 'Construction Manager', 'Construction Manager', @CreatedDate, 'M', 250)	
,(32, 'Construction Manager''s Project Number', 'Construction Manager''s Project Number', @CreatedDate, 'M', 260)
,(33, 'Design-Builder''s Project Number', 'Design-Builder''s Project Number', @CreatedDate, 'M', 270)
,(34, 'Date of Substantial Completion', 'Date of Substantial Completion', @CreatedDate, 'M', 280)

Insert into SLE_Publication.dbo.GlobalChoices(GlobalChoiceID, Name, [Description], LastChange, Source, SortOrder)
values (30, 'Design Professional''s Project Number', 'Design Professional''s Project Number', @CreatedDate, 'M', 240)	
,(31, 'Construction Manager', 'Construction Manager', @CreatedDate, 'M', 250)	
,(32, 'Construction Manager''s Project Number', 'Construction Manager''s Project Number', @CreatedDate, 'M', 260)
,(33, 'Design-Builder''s Project Number', 'Design-Builder''s Project Number', @CreatedDate, 'M', 270)
,(34, 'Date of Substantial Completion', 'Date of Substantial Completion', @CreatedDate, 'M', 280)
