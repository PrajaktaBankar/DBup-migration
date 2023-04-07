/*
Customer Support 39356: SLC User Has Duplicated Levels in Edit Templates

Server :2

For reference
select * from Template where CustomerId=481  and TemplateId=347
select * from Template where CustomerId=481  and TemplateId=583

select * from TemplateStyle where TemplateId=347 and CustomerId=481
*/


UPDATE  TS  SET TS.TemplateId=583 FROM TemplateStyle TS with (nolock) 
WHERE TS.TemplateStyleId BETWEEN 5257 AND 5265 and TS.CustomerId=481

UPDATE  TS  SET TS.TemplateId=584 FROM TemplateStyle TS with (nolock)
WHERE TS.TemplateStyleId BETWEEN 5266 AND 5274 and TS.CustomerId=481

UPDATE  TS  SET TS.TemplateId=585 FROM TemplateStyle TS with (nolock)
WHERE TS.TemplateStyleId BETWEEN 5275 AND 5283 and TS.CustomerId=481

UPDATE  TS SET TS.TemplateId=586 FROM TemplateStyle TS with (nolock)
WHERE TS.TemplateStyleId BETWEEN 5284 AND 5292 and TS.CustomerId=481

UPDATE  TS  SET TS.TemplateId=587 FROM TemplateStyle TS with (nolock)
WHERE TS.TemplateStyleId BETWEEN 5293 AND 5301 and TS.CustomerId=481

UPDATE  TS  SET TS.TemplateId=588 FROM TemplateStyle TS with (nolock)
WHERE TS.TemplateStyleId BETWEEN 5302 AND 5310 and TS.CustomerId=481

UPDATE  TS  SET TS.TemplateId=589 FROM TemplateStyle TS with (nolock)
WHERE TS.TemplateStyleId BETWEEN 5311 AND 5319 and TS.CustomerId=481

Delete  from TemplateStyle  where TemplateStyleId in(8103,8105,8107,8109,8111,8113,8115,8117,8119) and TemplateId=890 and CustomerId=481
Delete from Style where StyleId in(13454,13456,13458,13460,13462,13464,13466,13468,13470)  and CustomerId=481
