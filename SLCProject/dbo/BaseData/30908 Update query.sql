/*
server name : SLCMaster_SqlSlcOp001,SLCMaster_SqlSlcOp002,SLCMaster_SqlSlcOp003,SLCMaster_SqlSlcOp004
Row affected 1 for each query
Customer Support 30908: NMS Master Section 00 0110 needs to be re-loaded

*/

update seg
set SegmentDescription='<table><tgroup align="left" cols="3" colsep="1" rowsep="1"><colspec colname="1" colwidth="165pt" /><colspec colname="2" colwidth="165pt" /><colspec colname="3" colwidth="165pt" /><tbody valign="top"><tr><td>Section Number</td><td>Section Title</td><td>No. of Pages</td></tr></tbody></tgroup></table>'
from Segment seg where SegmentDescription like '%Section Title%' and SectionId=2018 and MasterDataTypeId=2

update seg 
set SegmentDescription='<table><tgroup align="left" cols="3" colsep="1" rowsep="1"><colspec colname="1" colwidth="165pt" /><colspec colname="2" colwidth="165pt" /><colspec colname="3" colwidth="165pt" /><tbody valign="top"><tr><td>Numéro de la section</td><td>Titre de la section</td><td>Nombre de pages</td></tr></tbody></tgroup></table>'
from Segment seg where SegmentDescription like '%Section Title%' and SectionId=3105
 

