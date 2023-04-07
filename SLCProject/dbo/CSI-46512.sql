--Execute on server 2
--Customer Support 46512: SLC header margins do not align

UPDATE H
SET DefaultHeader = '<table class="fr-invisible-borders" style="width: 100%;"><tbody><tr><td style="width: 33.3333%;">PROJECT NO. {GT#2}&nbsp;</td><td style="width: 33.3333%;"><div style="text-align: center;">{GT#1}</div></td><td style="width: 33.3333%;"><div style="text-align: right;">PAGE&nbsp;{KW#PageNumber}&nbsp;</div></td></tr><tr><td style="width: 33.3333%;">16 NOV 2020</td><td style="width: 33.3333%;"><br></td><td style="width: 33.3333%;"><div style="text-align: right;">SECTION&nbsp;{KW#SectionID}&nbsp;</div></td></tr><tr><td style="width: 33.3333%;"><br></td><td style="width: 33.3333%;"><div style="text-align: center;">{KW#SectionName}</div></td><td style="width: 33.3333%;"><br></td></tr></tbody></table>'
FROM Header H WITH(NOLOCK) WHERE H.CustomerId=629 AND H.ProjectId=10939