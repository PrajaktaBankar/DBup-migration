-- Customer Support Ticket 76651 - Add City to the project
-- Even though the customer belongs to Server 2, since LuCity is a lookup table
-- fix has been applied for all servers
-- Adding 'Cutler City' to Florida, USA

DECLARE @CityName NVARCHAR(255)

SET @CityName='Cutler City'

IF((SELECT TOP 1 1 FROM [SLCProject_SqlSlcOp001]..LuCity WHERE City = @CityName) IS NULL)
INSERT INTO [SLCProject_SqlSlcOp001]..LuCity (City,StateProvinceId) VALUES (@CityName,978)

IF((SELECT TOP 1 1 FROM [SLCProject_SqlSlcOp002]..LuCity WHERE City = @CityName) IS NULL)
INSERT INTO [SLCProject_SqlSlcOp002]..LuCity (City,StateProvinceId) VALUES (@CityName,978)

IF((SELECT TOP 1 1 FROM [SLCProject_SqlSlcOp003]..LuCity WHERE City = @CityName) IS NULL)
INSERT INTO [SLCProject_SqlSlcOp003]..LuCity (City,StateProvinceId) VALUES (@CityName,978)

IF((SELECT TOP 1 1 FROM [SLCProject_SqlSlcOp004]..LuCity WHERE City = @CityName) IS NULL)
INSERT INTO [SLCProject_SqlSlcOp004]..LuCity (City,StateProvinceId) VALUES (@CityName,978)

IF((SELECT TOP 1 1 FROM [SLCProject_SqlSlcOp005]..LuCity WHERE City = @CityName) IS NULL)
INSERT INTO [SLCProject_SqlSlcOp005]..LuCity (City,StateProvinceId) VALUES (@CityName,978)

IF((SELECT TOP 1 1 FROM [SLCProject_SqlSlcOp007]..LuCity WHERE City = @CityName) IS NULL)
INSERT INTO [SLCProject_SqlSlcOp007]..LuCity (City,StateProvinceId) VALUES (@CityName,978)

