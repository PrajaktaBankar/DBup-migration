
--Execute on Server 4
--Customer Support 45704: SLC header margins do not align with the page margins

UPDATE H
SET DefaultHeader = '<table style="width: 100%;"><tbody><tr><td style="width: 50.0000%;"><span style="font-family: &quot;Times New Roman&quot;, Times, serif, -webkit-standard; font-size: 11pt; text-transform: uppercase;">IDAHO YOUTH RANCH - HANDS OF PROMISE CAMPUS CALDWELL, IDAHO</span><br></td><td style="width: 50.0000%;"><div style="text-align: right;"><span style="font-family: &quot;Times New Roman&quot;, Times, serif, -webkit-standard; font-size: 11pt; text-transform: uppercase;">IYRHPC</span></div><br></td></tr></tbody></table>'
FROM Header H WITH(NOLOCK) WHERE H.CustomerId=1238 AND H.ProjectId=3744