
--Fix for Template Style Issue -- Customer Support 61333

DELETE FROM SLCProject..TemplateStyle WHERE CustomerId = 1792 AND TemplateId = 1190 AND TemplateStyleId IN (11022,11023)
UPDATE SLCProject..Style SET HangingIndent = 0, ShowNumber = 0, [Name] = 'Ayres New Template Level 1', A_StyleId = 93
WHERE CustomerId = 1792 AND StyleId = 16202

