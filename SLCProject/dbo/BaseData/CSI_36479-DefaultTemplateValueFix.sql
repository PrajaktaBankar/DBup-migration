use SLCProject
go
/*
	80 twips was the top distance for 1,2,3,4 levels. I arrived at multiplying 5760 by a factor of 1440 to 1 point.
	Somehow SLC uses 1 point multipled by a factor of 1440 to save the value to TopDistance in Style table.

	Gembox uses points as measurement.
	SLE which uses RTF format used twips as measurement.

	1440 twips = 72 points = 1 inch
	1 twip = 0.05 points
	80 twips = 4 points 
	10 twips = 0.5 points

	For SLC:
	1 point = 1440
	0.5 point = 720
	4 points = 5760

	FOr SLE to SLC conversion, use below formula:
	0.05 x SLE_TopDistance x 1440
	for template 1,2,3,4,5
	
	0.05 (points) x SLE_TopDistance (twips) x 1440 (SLC Factor)

	In SLC, gembox uses points, by dividing the resulting value by 1440, this will get converted to points.

*/

Update dbo.StyleParagraphLineSpace 
		set DefaultSpacesId=null
			, BeforeSpacesId=7
			, AfterSpacesId=7
			, CustomLineSpacing=1
from dbo.StyleParagraphLineSpace spl
inner join dbo.TemplateStyle ts on ts.StyleId=spl.StyleId
where ts.TemplateId in (1,2,3,4,5)

/*
select spl.* from dbo.StyleParagraphLineSpace spl
inner join dbo.TemplateStyle ts on ts.StyleId=spl.StyleId
where ts.TemplateId in (1,2,3,4,5)
*/

Update s set TopDistance= 0.05*TopDistance*1440
from dbo.Style s
inner join dbo.TemplateStyle ts on ts.StyleId=s.StyleId
where ts.TemplateId in (1,2,3,4,5)

/*
select  TopDistance, *
from dbo.Style s
inner join dbo.TemplateStyle ts on ts.StyleId=s.StyleId
where ts.TemplateId in (1,2,3,4,5)
*/
