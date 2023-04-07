/*
 ---For references-----
 Customer Support 56568: Cloud - Error Code When Exporting All Text Draft Section - Occurs in ALL Projects
*/

ALTER TABLE ProjectExport
ALTER COLUMN FileName nvarchar(500)

ALTER TABLE PrintRequestDetails
ALTER COLUMN FileName nvarchar(500)
