

/*
server name : SLCProject_SqlSlcOp003
 Customer Support 43677: SLC footer will not right justify
*/


UPDATE F
SET F.DefaultFooter = '<table class="fr-invisible-borders" style="width: 100%;"><tbody><tr><td style="width: 39.5599%; text-align: left;">TILL ELEMENTARY<br>CPS NO: 2020-25381-ICR</td><td style="width: 27.1068%; text-align: center;">{KW#SectionID} - {KW#PageNumber}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#SectionName}&nbsp;</td></tr></tbody></table>'
FROM Footer F WITH(nolock) 
WHERE F.ProjectId = 9622 and F.CustomerId=2246;


 UPDATE F
SET F.DefaultFooter = '<table class="fr-invisible-borders" style="width: 100%;"><tbody><tr><td style="width: 39.5599%; text-align: left;">TILL ELEMENTARY<br>CPS NO: 2020-25381-ICR</td><td style="width: 27.1068%; text-align: center;">{KW#SectionID} - {KW#PageNumber}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#SectionName}&nbsp;</td></tr></tbody></table>'
FROM Footer F WITH(nolock) 
WHERE F.ProjectId = 9964 and F.CustomerId=2246;


