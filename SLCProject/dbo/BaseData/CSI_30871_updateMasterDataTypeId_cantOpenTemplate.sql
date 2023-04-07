

-- Customer Support 30871: Can't open template - Rachael Spires with BWBR Architects - 12606
-- Execute for All server
--01 153
--02 175
--03 
--04 0
UPDATE S
SET S.MasterDataTypeId = T.MasterDataTypeId
FROM TemplateStyle TS WITH (NOLOCK)
LEFT JOIN Style S WITH (NOLOCK)
	ON S.StyleId = TS.StyleId
LEFT JOIN Template T WITH (NOLOCK)
	ON T.TemplateId = TS.TemplateId
WHERE S.MasterDataTypeId IS NULL