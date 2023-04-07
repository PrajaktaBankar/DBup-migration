USE SLCProject 


/*
Customer Support 62808: SLC: Design Criteria Sections appearing under Division 00
SERVER - Excute script on Server 004
*/
GO


UPDATE PS SET Divisionid = 2 , DivisionCode= 'DC' FROM ProjectSection PS WITH(NOLOCK)
 WHERE CustomerId = 1598 and SourceTag like 'DC%' and IsLastLevel = 1 and DivisionCode = '00';
--1168 Row updated