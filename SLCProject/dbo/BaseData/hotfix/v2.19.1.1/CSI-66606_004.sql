/*
Customer Support 66606: SLC: Links Not Correctly Activating(S4)
Server - 004
*/
USE SLCProject
GO

update SCO SET ISDeleted = 1 FROM SelectedChoiceOption SCO WITH(NOLOCK) WHERE SelectedChoiceOptionId IN (3302586062,3302586063,3302606544,3302606545,2791034798,2791034799);