/*
User Story 71101: Tech: Separate out the Save & Disable link engine configuration
*/
use SLCPROJECT

update UserPreference
set [Value]='[{"EnableLinkEngineSettingVisible":true,"EnableAutosaveButton":true}]'
where [Name]='Summary Info Setting'