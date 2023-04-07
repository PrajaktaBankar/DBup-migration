Use [SLCProject_SqlSlcOp003]
GO

UPDATE S SET S.DefaultSpacesId = 1, S.BeforeSpacesId=7, S.AfterSpacesId = 7, 
CustomLineSpacing = '1.00'
FROM StyleParagraphLineSpace S WITH (NOLOCK)
Where StyleId IN(SELECT StyleId FROM TemplateStyle WITH (NOLOCK) WHERE TemplateId = 1125)
GO

WITH cte AS (
    SELECT 
        StyleId, 
                DefaultSpacesId, 
                BeforeSpacesId,
				AfterSpacesId,
				CustomLineSpacing, 
        ROW_NUMBER() OVER (
            PARTITION BY 
                StyleId, 
                DefaultSpacesId, 
                BeforeSpacesId,
				AfterSpacesId,
				CustomLineSpacing
            ORDER BY 
                StyleId, 
                DefaultSpacesId, 
                BeforeSpacesId,
				AfterSpacesId,
				CustomLineSpacing
        ) row_num
     FROM 
        [StyleParagraphLineSpace] WITH (NOLOCK)
		WHERE
 StyleId IN(SELECT StyleId FROM TemplateStyle WITH (NOLOCK) WHERE TemplateId = 1125)
)
DELETE FROM cte
WHERE row_num > 1;
GO