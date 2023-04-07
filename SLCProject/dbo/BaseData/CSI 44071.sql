 
/*
server name : SLCProject_SqlSlcOp003
 Customer Support 44071: SLC client can't open two sections after hitting browser back buttons - 16195

*/

 update TS
 set TS.StyleId=3991
 from TemplateStyle TS WITH(nolock) 
 where TS.TemplateId=264 and TS.TemplateStyleId=2382