CREATE PROCEDURE [dbo].[usp_getLastActiveDateOfUsers]  
(    
 @UserIds nvarchar(max)  NULL,  
 @CustomerId INT  
)  
AS  
BEGIN
  
 DECLARE @PUserIds nvarchar(max) = @UserIds;
 DECLARE @PCustomerId INT = @CustomerId;
 --DECLARE @UserIds nvarchar(max) = '[2666, 2513,2514]';  
 DECLARE @Users TABLE(UserId INT NULL);

INSERT INTO @Users
	SELECT
		[value] AS UserId
	FROM OPENJSON(@PUserIds)

DROP TABLE IF EXISTS #LastActiveDetail

SELECT max(lastaccessed) LastActiveDate,UserId 
INTO #LastActiveDetail
FROM UserFolder WITH (NOLOCK)
WHERE CustomerId=@PCustomerId --AND UF.UserId = U.UserId
GROUP BY userid

SELECT
	U.UserId
   ,LAD.LastActiveDate
FROM @Users U
inner join #LastActiveDetail LAD on LAD.UserId=U.UserId

--CROSS APPLY (SELECT TOP 1
--		UF.LastAccessed AS LastActiveDate
--	FROM UserFolder UF WITH (NOLOCK)
--	WHERE UF.CustomerId = @PCustomerId
--	AND UF.UserId = U.UserId
--	ORDER BY UF.LastAccessed DESC) LastActiveDetails
END

GO
