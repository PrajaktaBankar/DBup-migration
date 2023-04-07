CREATE PROCEDURE usp_GetProjectDefaultAdminTypes    
as    
begin    
select ProjectOwnerTypeId,[Name],[Description],IsActive, SortOrder 
		from LuProjectOwnerType WITH(NOLOCK) order by SortOrder desc;
end