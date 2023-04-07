USE SLCProject

GO

UPDATE PS SET DivisionCode = '99' , DivisionId = 3000037 FROM ProjectSection PS WITH(NOLOCK) WHERE  mSectionId = 3001403;