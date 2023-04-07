IF NOT EXISTS (SELECT [Id] FROM [dbo].[LuProjectSectionIdSeparator] WHERE [Separator] = '_')
BEGIN
    INSERT INTO [dbo].[LuProjectSectionIdSeparator]([ProjectId],[CustomerId],[UserId],[Separator])
    VALUES (NULL,NULL,NULL,'_')
END