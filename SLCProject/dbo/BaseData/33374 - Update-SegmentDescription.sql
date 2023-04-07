use SLCProject
go
--Customer Support 33374: CH# Issues - Dewayne Dean - LDS Church - 40958 
-- Execute on server 03
 update p set  p.SegmentDescription='<span style="">3M<span class="fr-marker" data-id="0" data-type="false" style="display: none; line-height: 0;">?</span><span class="fr-marker" data-id="0" data-type="true" style="display: none; line-height: 0;">?</span>, St Paul, MN  <mark data-markjs="true" class="currentMatch">{HL#3455231}.</mark></span>'
 FROM ProjectSegment p with (NOLOCK) WHERE SegmentStatusId=250214163