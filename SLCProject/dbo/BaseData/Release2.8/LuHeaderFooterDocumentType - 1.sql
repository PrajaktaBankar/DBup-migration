

INSERT INTO [dbo].LuHeaderFooterDocumentType
VALUES('TOC Report')
GO
INSERT into [dbo].Header
values(NULL	,NULL,NULL,NULL,0,NULL,NULL,1,0,getUtcdate(),0,getUtcdate(),1,NULL,NULL,NULL,1,'Short','Short',NULL,1,NULL,NULL,NULL,NULL,3)

GO
INSERT into [dbo].Footer
values(NULL,NULL,NULL,NULL,0,NULL,NULL,1,0,getUtcdate(),0,getUtcdate(),1,NULL,NULL,NULL,1,'Short','Short',NULL,1
,'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>' 
,'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>' 
,'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>' 
,'<table style="width: 100%;" class="fr-invisible-borders"><tbody><tr><td style="width: 33.0000%;text-align:left;">{KW#ProjectName}&nbsp;</td><td style="width: 33.0000%;text-align:center;">{KW#ReportName}&nbsp;</td><td style="width:33.0000%;text-align:right;">{KW#DateField}&nbsp;</td></tr></table>'
,3)
