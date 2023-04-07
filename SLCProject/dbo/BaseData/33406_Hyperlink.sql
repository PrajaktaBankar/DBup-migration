
-- execute on 03

insert into ProjectHyperLink (SectionId	,SegmentId	,SegmentStatusId	,ProjectId	,CustomerId	,LinkTarget	,LinkText	,LuHyperLinkSourceTypeId	,CreateDate	,CreatedBy	,ModifiedDate	,ModifiedBy	,SLE_DocID	,SLE_SegmentID	,SLE_StatusID	,SLE_LinkNo	,A_HyperLinkId)
 values
(5669697,41072187,250214163,6107,375,'http://www.mmm.com','www.mmm.com',1,'2019-05-07 14:59:04.3766667',843,null, null,1000475,43,43,10,null), --832
(5669697,41048588,250214164,6107,375,'http://www.bakermfg.com','www.bakermfg.com',1,'2019-05-07 14:59:04.3766667',843,null, null,1000475,44,44,11,null), -- 893
(5669697,41094715,250214165,6107,375,'http://www.flintandwalling.com','www.flintandwalling.com',1,'2019-05-07 14:59:04.3766667',843,null, null,1000475,45,45,12,null), -- 902
(5669697,41059050,250214168,6107,375,'http://www.johnsonscreens.com','www.johnsonscreens.com',1,'2019-05-07 14:59:04.3766667',843,null, null,1000475,48,48,13,null), -- 932
(5669697,41064546,250214169,6107,375,'http://www.nibco.com','www.nibco.com',1,'2019-05-07 14:59:04.3766667',843,null, null,1000475,49,49,14,null), -- 937
(5669697,41054037,250214170,6107,375,'http://www.starite.com','www.starite.com',1,'2019-05-07 14:59:04.3766667',843,null, null,1000475,50,50,15,null), -- 958
(5669697,41065078,250214171,6107,375,'http://www.tnb.com','www.tnb.com',1,'2019-05-07 14:59:04.3766667',843,null, null,1000475,51,51,16,null), -- 961
(5669697,41094716,250214172,6107,375,'http://www.watts.com','www.watts.com',1,'2019-05-07 14:59:04.3766667',843,null, null,1000475,52,52,17,null) -- 937






update PS 
set SegmentDescription ='<span style="">3M<span class="fr-marker" data-id="0" data-type="false" style="display: none; line-height: 0;">​</span><span class="fr-marker" data-id="0" data-type="true" style="display: none; line-height: 0;">​</span>, St Paul, MN  <mark data-markjs="true" class="currentMatch">{HL#</mark>3455231}.</span>'
from ProjectSegment PS with (nolock)
where SegmentStatusId=250214163


update PS 
set SegmentDescription ='<span style="">Baker Manufacturing, Evansville, WI  {HL#3455232}.</span>'
from ProjectSegment PS with (nolock)
where SegmentStatusId=250214164


update PS 
set SegmentDescription ='<span style="">Flint &amp; Walling Inc, Kendallville, IN  (864) 347-1600  {HL#3455233}.</span>'
from ProjectSegment PS with (nolock)
where SegmentStatusId=250214165


update PS 
set SegmentDescription ='<span style="">Johnson Screens Inc., St. Paul MN  {HL#3455234}.</span>'
from ProjectSegment PS with (nolock)
where SegmentStatusId=250214168


update PS 
set SegmentDescription ='<span style="">Nibco Inc, Elkhart, IN  {HL#3455235} or Nibco Canada Inc, Markham, ON  (800) 268-3509.</span>'
from ProjectSegment PS with (nolock)
where SegmentStatusId=250214169


update PS 
set SegmentDescription ='<span style="">Sta-Rite, Delavan, WI  {HL#3455236}.</span>'
from ProjectSegment PS with (nolock)
where SegmentStatusId=250214170


update PS 
set SegmentDescription ='<span style="">Thomas &amp; Betts, Brooksville, FL  {HL#3455237}.</span>'
from ProjectSegment PS with (nolock)
where SegmentStatusId=250214171


update PS 
set SegmentDescription ='<span style="">Watts Flowmatic Inc., Dunnellon, FL  {HL#3455238}.</span>'
from ProjectSegment PS with (nolock)
where SegmentStatusId=250214172
