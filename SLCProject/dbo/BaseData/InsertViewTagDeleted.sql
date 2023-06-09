 --insert row in dbo.LuProjectSpecTypeTag for handling deleted tags.
--execute on server 3
--Customer Support 30395: Removing master editors added short form or outline tag comes back after a refresh
  
  if not exists(select top 1 1 from LuProjectSpecTypeTag WITH(NOLOCK) WHERE SpecTypeTagId=0)
  begin
  set identity_insert dbo.luprojectspectypetag on
  insert into dbo.LuProjectSpecTypeTag(SpecTypeTagId, TagType, Description, IsActive, SortOrder)
  values (0, 'DT', 'Deleted', 0, 5)
  set identity_insert dbo.luprojectspectypetag off
  end
   