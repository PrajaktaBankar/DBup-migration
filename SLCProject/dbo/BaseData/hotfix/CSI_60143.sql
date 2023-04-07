--Customer Support 60143: Printing Project Notes in a Section
--Server 3 

update pn
SET pn.NoteText ='<p>Include this Section if renovation is in clinical area</span> </p>' 
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 16172054
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 update pn
SET pn.NoteText =' <p>Does this describe what SFH will do prior to demolition?</p>'
from ProjectNote pn WITH (NOLOCK)
 where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129397
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
update pn
SET pn.NoteText =' <p>verify on drawings if concrete is referred to as "sealed concrete" or "polished concrete". &nbsp;Also verify if SHF is still allowing concrete to be exposed or prefer a VCT finish instead.</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129322 and pn.SegmentStatusId = 863825082

update pn
SET pn.NoteText ='<p>Does SFH ever do Polished Concrete?</p>'
from ProjectNote pn WITH (NOLOCK)
 where pn.CustomerId = 211 and ProjectId = 13711 and pn.SectionId = 15129322 and pn.SegmentStatusId = 863823225

--------------------------------------------------------------------------------------------------------------------------------------
update pn
SET pn.NoteText ='<p>Verify which decorative panels are required on Drawings</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and ProjectId = 13711 and pn.SectionId = 15700980  and pn.SegmentStatusId = 898516664

 update pn
SET pn.NoteText ='<p>Verify which wood paneling is required on Drawings</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15700980  and pn.SegmentStatusId = 900938209

 update pn
SET pn.NoteText ='<p>For non-security type transaction windows</span></p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15700980  and pn.SegmentStatusId = 899782672

 update pn
SET pn.NoteText ='<p>Indicate types of hardware required on Drawings</span></p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15700980  and pn.SegmentStatusId = 898516698

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 update pn
SET pn.NoteText ='<p>depending on moisture testing results,really wet conditions may need a sheet membrane, I''ve had to use one on a basement cafeteria that had consistent leaks for years. it created a floating floor for VCT installation</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15128986  and pn.SegmentStatusId = 863802617

 update pn
SET pn.NoteText ='<p>verify if SFH wants this</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15128986  and pn.SegmentStatusId = 863802457

 update pn
SET pn.NoteText ='<p>verify if CCC wants this?</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15128986  and pn.SegmentStatusId = 863802293

 update pn
SET pn.NoteText ='<p>if we let the testing agency recommend, then unit prices couldn''t be established ahead of time.
or we could ask CCC their preference and feedback.</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15128986  and pn.SegmentStatusId = 863802497

update pn
SET pn.NoteText ='<p>coordinate with concrete floor finishes section Div 03</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15128986  and pn.SegmentStatusId = 863802361

--------------------------------------------------------------------------------------------------------------------------------------------------------------
update pn
SET pn.NoteText ='<p>not sure if or what was used. &nbsp;Product data indicates options</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15128343  and pn.SegmentStatusId = 863778070
------------------------------------------------------------------------------------------------------------------------------------------------------------------
update pn
SET pn.NoteText ='<p> recessed standard, semi recessed only if wall size can''t accommodate.</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129470  and pn.SegmentStatusId = 863868630

update pn
SET pn.NoteText ='<p>recessed standard, semi recessed only if wall size can''t accommodate.</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129470  and pn.SegmentStatusId = 863870135

--------------------------------------------------------------------------------------------------------------------------------
update pn
SET pn.NoteText ='<p>This product is just a bond coat.</span> </p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129334  and pn.SegmentStatusId = 863841815

update pn
SET pn.NoteText ='<p>this product won''t work for a building up a mortar bed for sloping.use Laticrete 3701 with reinforcing mesh.this product is good for regular thin set tile</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129334  and pn.SegmentStatusId = 863841879

update pn
SET pn.NoteText =
'<p>use this to build up shower slope with mortar bed </p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129334  and pn.SegmentStatusId = 863849726

update pn
SET pn.NoteText =
'<p>should we specify something in case it''s needed? unexpected conditions/cracks?</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129334  and pn.SegmentStatusId = 863848892

update pn
SET pn.NoteText =
'<p>We won''t install this with epoxy showers floors.</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129334  and pn.SegmentStatusId = 863841867

update pn
SET pn.NoteText =
'<p>linear drains not in SFH guidelines, but Chris W is suggesting to Jenna...?</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129334  and pn.SegmentStatusId = 863851234

update pn
SET pn.NoteText =
'<p>per Katie W, SFH doesn''t use Schluter except for their trim pieces.</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129334  and pn.SegmentStatusId = 863841872

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
update pn
SET pn.NoteText =
'<p>Retain ceiling if expansion joint goes through gypsum board ceiling.</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129330  and pn.SegmentStatusId = 863824898

update pn
SET pn.NoteText =
'<p><a href="http://www.balcousa.com/"> Balco</a>&nbsp;is the renowned manufacturer of pre-engineered and custom architectural building components such as expansion joint systems, fire barriers, stair nosings and IllumiTread™ (photoluminescent egress systems), skillfully engineered for the commercial construction industry for worldwide distribution and quality service.</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129330  and pn.SegmentStatusId = 933663357

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
update pn
SET pn.NoteText =
'<p>Changed from Republic Storage Products, 3-tier, 12x18x24" units w/ custom color, to Art Metal Products, 4-tier, 12x18x18" units in #746 Popular Gray, per DRB Addendum #5</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15308433  and pn.SegmentStatusId = 877225880 and NoteId = 34533188

update pn
SET pn.NoteText =
'<p>Coat hooks are not standard with Box lockers,even though DRB SF Standard calls for coat hooks &nbsp;</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15308433  and pn.SegmentStatusId = 877225928 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
update pn
SET pn.NoteText =
'<p>coordinate fabric designation with SFH standards and drawings</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129442  and pn.SegmentStatusId = 863854013 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
update pn
SET pn.NoteText =
'<p>verify substrate with details - drawings and submittals differ. &nbsp;it may depend on the subcontractor</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129463  and pn.SegmentStatusId = 863869913 

update pn
SET pn.NoteText =
'<p>verify substrate with details - drawings and submittals differ. &nbsp;it may depend on the subcontractor</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129463  and pn.SegmentStatusId = 863869912 

update pn
SET pn.NoteText =
'<p>verify with details</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129463  and pn.SegmentStatusId = 863868187 

update pn
SET pn.NoteText =
'<p>verify there are wall panels or column covers with drawings</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129463  and pn.SegmentStatusId = 898568392 

update pn
SET pn.NoteText =
'<p>Does SF use integral sinks with the solid surfacing countertops?</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129463  and pn.SegmentStatusId = 863869917 

update pn
SET pn.NoteText =
'<p>>Does SF ever use stainless steel countertops over plam cabinets?</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129463  and pn.SegmentStatusId = 863871153 

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
update pn
SET pn.NoteText =
'<p>probably not needed for remodel unless current pit is having problems, if so, waterproofing type is probably different for retro fit cases</p>'
from ProjectNote pn WITH (NOLOCK)
where pn.CustomerId = 211 and pn.ProjectId = 13711 and pn.SectionId = 15129443  and pn.SegmentStatusId = 863855092 
