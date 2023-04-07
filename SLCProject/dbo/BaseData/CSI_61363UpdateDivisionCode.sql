/*
Customer Support 61363: SLC: Unable To Access Moved Sections

Server:execute all server

description:
select *  From ProjectSection PS WITH(NOLOCK) where mSectionId>0 and IsLastLevel = 1 and DivisionCode = '9'
DivisionCode is not updating correctly it should insert 99 but in actual updating 9 that it was wrong.
so we give data fix for this.
*/

update PS set PS.DivisionId = 38 , PS.DivisionCode = 99  From ProjectSection PS WITH(NOLOCK) 
where PS.mSectionId>0 and PS.IsLastLevel = 1 and PS.DivisionCode = '9' and PS.IsDeleted = 0








