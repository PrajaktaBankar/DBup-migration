UPDATE PS  SET PS.ProjectUoMId=2 From LuProjectSize PS 
GO

INSERT INTO LuProjectSize
VALUES('0 - 500',1),
('501 - 2,500',1),
('2,501 - 10,000',1),
('10,001 - 50,000',1),
('50,000+',1)
GO

INSERT INTO LuProjectCost
VALUES( '0 - 1,500,000','CA')
,('1,500,001 - 20,000,000','CA')
,('20,000,001 - 135,000,000','CA')
,('135,000,001 - 670,000,000','CA')
,('670,000,000+','CA')
GO
