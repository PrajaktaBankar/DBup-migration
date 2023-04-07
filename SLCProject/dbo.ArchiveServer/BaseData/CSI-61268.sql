--Customer Support 61268: SLC: Unable To Delete Project
--server-4

UPDATE PS set PS.IsLocked=0 FROM ProjectSection PS WITH(NOLOCK)  WHERE PS.SectionId=4073097  
and PS.ProjectId=3531
UPDATE PS set PS.IsLocked=0 FROM ProjectSection PS WITH(NOLOCK)  WHERE PS.SectionId=4073096  
and PS.ProjectId=3531

