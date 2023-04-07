/*
 Server name : SLCProject002 (Server 02)
 Customer Support 72010: Table of Content Section in Office Master has a break in hierarchy - 24005/260
 Records updated: 6
*/

IF (SELECT DivisionId FROM ProjectSection WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 19013 AND  SectionId = 24306135) != 7
BEGIN
	UPDATE PS SET DivisionCode = '05' , DivisionId = 7 FROM ProjectSection PS WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 19013 AND  SectionId = 24306135;
END

IF (SELECT DivisionId FROM ProjectSection WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 19005 AND  SectionId = 24294209) != 7
BEGIN
	UPDATE PS SET DivisionCode = '05' , DivisionId = 7 FROM ProjectSection PS WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 19005 AND  SectionId = 24294209;
END

IF (SELECT DivisionId FROM ProjectSection WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 15085 AND  SectionId = 18788499) != 7
BEGIN
	UPDATE PS SET DivisionCode = '05' , DivisionId = 7 FROM ProjectSection PS WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 15085 AND  SectionId = 18788499;
END

IF (SELECT DivisionId FROM ProjectSection WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 19012 AND  SectionId = 24304738) != 7
BEGIN
	UPDATE PS SET DivisionCode = '05' , DivisionId = 7 FROM ProjectSection PS WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 19012 AND  SectionId = 24304738;
END

IF (SELECT DivisionId FROM ProjectSection WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 18869 AND  SectionId = 24088354) != 7
BEGIN
	UPDATE PS SET DivisionCode = '05' , DivisionId = 7 FROM ProjectSection PS WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 18869 AND  SectionId = 24088354;
END

IF (SELECT DivisionId FROM ProjectSection WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 18871 AND  SectionId = 24091820) != 7
BEGIN
	UPDATE PS SET DivisionCode = '05' , DivisionId = 7 FROM ProjectSection PS WITH(NOLOCK) WHERE CustomerId = 260 AND ProjectId = 18871 AND  SectionId = 24091820;
END