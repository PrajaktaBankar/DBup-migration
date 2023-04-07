USE [SLCProject_SqlSlcOp004]
GO

UPDATE S SET S.DefaultSpacesId = 1, S.BeforeSpacesId=7, S.AfterSpacesId = 7, 
CustomLineSpacing = '1.00'
FROM StyleParagraphLineSpace S WITH (NOLOCK)
Where StyleId IN(SELECT StyleId FROM TemplateStyle WITH (NOLOCK) WHERE TemplateId in(899
,1419
,1795
,1906
,2056
,2134
,2135
,2136
,2137
,2138
,2139
,2140))
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
 StyleId IN(SELECT StyleId FROM TemplateStyle WITH (NOLOCK) WHERE TemplateId in(899
,1419
,1795
,1906
,2056
,2134
,2135
,2136
,2137
,2138
,2139
,2140))
)
DELETE FROM cte
WHERE row_num > 1;

