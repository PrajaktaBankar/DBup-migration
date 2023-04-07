--Customer Support 59554: Section will not show up to print - Melinda with Nola | VanPeursem Architects - 21067
--Server 3

update ps
set ps.DivisionId = 12 
,ps.DivisionCode = 10 from ProjectSection ps WITH (NOLOCK)
where ps.SectionId = 15701339 and ps.ProjectId = 14084 and ps.CustomerId = 1462