use SLCProject
/*
Server - Execute on server 005
Customer Support 65751: SLC: Div 9 Not Showing From Print Menu
*/
GO

update PS SET DivisionId = 11, DivisionCode = '09' FROM ProjectSection PS WITH(NOLOCK) where SectionId in (8485400, 8485401, 8485402) and  Projectid = 6671; 
update PS SET DivisionId = 11, DivisionCode = '09' FROM ProjectSection PS WITH(NOLOCK) where SectionId in (6848124, 6848138, 6848195) and  Projectid = 5415;
update PS SET DivisionId = 11, DivisionCode = '09' FROM ProjectSection PS WITH(NOLOCK) where SectionId in (6915272, 6915273, 6915271) and  Projectid = 5417;


