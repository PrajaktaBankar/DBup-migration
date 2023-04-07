/*
Customer Support 37095: SLC Find/Replace Highlighting
server :2
for references:
--360900036,360900040,360900040,360900140
select * from ProjectSegmentStatus where SegmentStatusId=360900040

----62525171,62523438,62524028,62526145
select * from ProjectSegment where SegmentId=61485991
example:
<mark class="currentMatch" data-markjs="true">Project</mark> Title Page
*/



update PS set PS.SegmentDescription ='C.Project Title Page' from ProjectSegment PS with(nolock) where PS.SegmentId =61489473 and PS.SectionId=8766338 and PS.ProjectId=7328
update PS set PS.SegmentDescription ='PROJECT NO.<span contenteditable="false" akgdvalue="10xxxx.01" akgd="1">​{GT#10000024}​&nbsp;</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61487565 and PS.SectionId=8766338 and PS.ProjectId=7328
update PS set PS.SegmentDescription ='Project Manager' from ProjectSegment PS with(nolock) where PS.SegmentId =61489614 and SectionId=8766338 and ProjectId=7328
update PS set PS.SegmentDescription ='PROJECT NO.<span contenteditable="false" akgdvalue="10xxxx.01" akgd="1"> {GT#10000024} &nbsp;</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61487565 and PS.SectionId=8766338 and PS.ProjectId=7328

update PS set PS.SegmentDescription ='<span>The project2 is yeared at:</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61489546 and PS.SectionId=8765480 and PS.ProjectId=7328
update PS set PS.SegmentDescription ='<span>The accompanying Drawings and Specifications show and describe the yearion and type of project2 to be performed under thparty test. project2 is more specifically defined on the drawings listed in Section 00 01 15.</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61485989 and PS.SectionId=8765480 and PS.ProjectId=7328
update PS set PS.SegmentDescription ='<span>The ​​​{GT#1}​​​ consists of:</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61486523 and PS.SectionId=8765480 and PS.ProjectId=7328
update PS set PS.SegmentDescription ='<span>The project2 under this contract is to provide, furnish and install all labor, materials and equipment required to complete the project2, installed, tested, and ready for use, and as described in these documents.</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61486812 and PS.SectionId=8765480 and PS.ProjectId=7328
update PS set PS.SegmentDescription ='<span>Port of Tacoma will furnish the Contractor with the following material:</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61486445 and PS.SectionId=8765480 and PS.ProjectId=7328
update PS set PS.SegmentDescription ='<span>The ​​​{GT#1}​​​ consists of:</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61486908 and SectionId=8765480 and ProjectId=7328
update PS set PS.SegmentDescription ='<span>The project2 under this contract is to provide, furnish and install all labor, materials and equipment required to complete the project2, installed, tested, and ready for use, and as described in these documents.</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61485895 and PS.SectionId=8765480 and PS.ProjectId=7328
update PS set PS.SegmentDescription ='<span>Test test test The Contractor shall,by test test test way of the Engineer, familiarize itself with other contracts replace which have been awarded, about to be awarded or are in progress in the same or immediate area. The Contractor shall coordinate the progress of its project2 with the <span>established</span> schedules for completion and phasing.</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61485991 and SectionId=8765480 and ProjectId=7328
update PS set PS.SegmentDescription ='<span>The accompanying Specifications describe the yearion and type of project2 to be performed under this test.</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61486758 and SectionId=8765480 and ProjectId=7328
update PS set PS.SegmentDescription ='<span>The {GT#1} consists of:</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61486523 and PS.SectionId=8765480 and PS.ProjectId=7328
update PS set PS.SegmentDescription ='<span>The {GT#1} consists of:</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =61486908 and PS.SectionId=8765480 and PS.ProjectId=7328

update PS set PS.SegmentDescription ='Project Title Page' from ProjectSegment PS with(nolock) where PS.SegmentId =62525171 and PS.SectionId=8860329 and PS.ProjectId=7399
update PS set PS.SegmentDescription ='PORT OF TACOMA' from ProjectSegment PS with(nolock) where PS.SegmentId =62523438 and PS.SectionId=8860329 and PS.ProjectId=7399
update PS set PS.SegmentDescription ='PROJECT NO.<span class="GTEditTC" contenteditable="false" ct="GTEditTC" akgd="0" akgdvalue="10xxxx.01" dt="1586553818000" uid="13291" cid="6b65f340-7e6d-11ea-b645-bb0b05e797f8"><span class="del">10xxxx.01</span>​{GT#10000024}​</span>' from ProjectSegment PS with(nolock) where PS.SegmentId =62524028 and PS.SectionId=8860329 and PS.ProjectId=7399
update PS set PS.SegmentDescription ='Project Manager' from ProjectSegment PS with(nolock) where PS.SegmentId =62526145 and PS.SectionId=8860329 and PS.ProjectId=7399
update PS set PS.SegmentDescription ='PROJECT NO.<span class="GTEditTC" contenteditable="false" ct="GTEditTC" akgd="0" akgdvalue="10xxxx.01" dt="1586553818000" uid="13291" cid="6b65f340-7e6d-11ea-b645-bb0b05e797f8"><span class="del">10xxxx.01</span> {GT#10000024} </span>' from ProjectSegment PS with(nolock) where PS.SegmentId =62524028 and PS.SectionId=8860329 and PS.ProjectId=7399



