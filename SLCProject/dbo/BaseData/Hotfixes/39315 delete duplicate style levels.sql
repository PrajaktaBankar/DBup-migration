/*
 server name : SLCProject_SqlSlcOp002
 Customer Support 39315: SLC User Has Duplicated Style Levels in Edit Templates

 ---For references-----
select * from Template where CustomerId=429  and TemplateId IN(721,69)

select * from TemplateStyle where TemplateId=721 and CustomerId=429 and styleId in(11591,11593,11595,11597,11599,11601,11603,11605,11607)
select * from style where CustomerId=429 and styleId in(11591,11593,11595,11597,11599,11601,11603,11605,11607)

select * from TemplateStyle where TemplateId=69 and CustomerId=429 and styleid in(1061,1062,1063,1064,1065,1066,1067,1068,1069)
select * from style where CustomerId=429 and styleId in(1061,1062,1063,1064,1065,1066,1067,1068,1069) 
*/

Delete  from TemplateStyle  where TemplateStyleId in(6502,6504,6506,6508,6510,6512,6514,6516,6518) and TemplateId=721 and CustomerId=429
Delete from Style where StyleId in(11591,11593,11595,11597,11599,11601,11603,11605,11607)  and CustomerId=429

Delete  from TemplateStyle  where TemplateStyleId in(622,623,624,625,626,627,628,629,630) and TemplateId=69 and CustomerId=429
Delete from Style where styleId in(1061,1062,1063,1064,1065,1066,1067,1068,1069)  and CustomerId=429
