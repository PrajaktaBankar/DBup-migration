/*
 server name : SLCProject_SqlSlcOp004
 Customer Support 54037: SLC Export Issues
*/

Update  PS
SET PS.SegmentDescription= '<span cid="2bc31941-61a0-11eb-8a95-ef5d62c7f81f" class="del" ct="del" dt="1611862612180" uid="24437" un="Lavinia  Matulevich ">Provide manufacture''s warranty for retractable platform edge against structural fatigue, corrosion, or cracking for from 10 years from the date of Substantial Completion.</span><span cid="49ac91c0-61a0-11eb-8a95-ef5d62c7f81f" class="ins ch-i cts-0" ct="ins" dt="1611862662364" uid="24437" un="Lavinia  Matulevich ">Manufacturer''s Warranty: Retractable platform edge manufacturer agrees to repair or replace the </span><span cid="41b9f660-61a0-11eb-8a95-ef5d62c7f81f" class="ins ch-i cts-0" ct="ins" dt="1611862649030" uid="24437" un="Lavinia  Matulevich ">retractable platform edge that deteriorate within specified warranty period at no additional cost to NJ Transit. Deterioration of</span><span cid="5a146600-61a0-11eb-8a95-ef5d62c7f81f" class="ins ch-i cts-0" ct="ins" dt="1611862689888" uid="24437" un="Lavinia  Matulevich ">retractable platform edge is defined as structural fatique, corrosion or cracking.</span>'
FROM ProjectSegment PS With(NOLOCK)
Where PS.CustomerId=2742
and PS.SectionId=15854759 
and PS.SegmentDescription like '%defined as structural fatique, corrosion or cracking.%'
