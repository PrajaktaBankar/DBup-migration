CREATE procedure [dbo].[usp_DuplicatestyleParagraphLineSpace]
 (
 @CopyTemplateId int null,
 @NewTemplateId int null
 )
 AS
 BEGIN
 DECLARE @PCopyTemplateId int = @CopyTemplateId;
 DECLARE @PNewTemplateId int = @NewTemplateId;
INSERT INTO StyleParagraphLineSpace (StyleId, DefaultSpacesId, BeforeSpacesId, AfterSpacesId, CustomLineSpacing)
	SELECT DISTINCT
		ts.StyleId
	   ,st.DefaultSpacesId
	   ,st.BeforeSpacesId
	   ,st.AfterSpacesId
	   ,CustomLineSpacing
	FROM TemplateStyle t WITH(NOLOCK) 
	INNER JOIN StyleParagraphLineSpace st WITH(NOLOCK) 
		ON st.StyleId = t.StyleId
	INNER JOIN TemplateStyle ts WITH(NOLOCK) 
		ON t.Level = ts.Level
	WHERE t.TemplateId = @PCopyTemplateId
	AND ts.TemplateId = @PNewTemplateId

UPDATE S
SET S.IsSystem = 0
FROM Style S WITH (NOLOCK)
INNER JOIN TemplateStyle TS WITH(NOLOCK) 
	ON TS.StyleId = S.StyleId
WHERE TS.TemplateId = @PNewTemplateId

END

GO
