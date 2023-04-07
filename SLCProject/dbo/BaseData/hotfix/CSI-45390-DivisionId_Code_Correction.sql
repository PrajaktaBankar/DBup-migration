USE SLCProject

GO
--Please Exceute below script on all servers DB

update ps set DivisionId = 2 , DivisionCode = 'DC'
from ProjectSection ps WITH(NOLOCK) where mSectionId in (3728,3730) and (DivisionId <>2 OR DivisionCode <> 'DC');
