--CSI Customer Support 60789: SLC TOC Report adding sections to the wrong division - 40958
--Server 3 

update ps 
set ps.DivisionCode = 10
    ,ps.DivisionId = 12 from ProjectSection ps WITH (NOLOCK)
where ps.CustomerId = 383 and ps.ProjectId = 13928 and ps.SectionId=15427655

update ps 
set ps.DivisionCode = 10
    ,ps.DivisionId = 12 from ProjectSection ps WITH (NOLOCK)
where ps.CustomerId = 383 and ps.ProjectId = 13928 and ps.SectionId = 15427680