CREATE PROCEDURE [dbo].[usp_GetHeaderFooterKeywordDetails]         
@ProjectId INT,        
@CustomerId INT        
AS            
BEGIN        
DECLARE @PProjectId INT = @ProjectId;        
DECLARE @PCustomerId INT = @CustomerId;        
--DECLARE @KeywordFormatStart NVARCHAR(MAX) = '{KW#';        
--DECLARE @KeywordFormatEnd NVARCHAR(MAX) = '}';        
        
DECLARE @KeywordFormatStart NVARCHAR(MAX) = '';        
DECLARE @KeywordFormatEnd NVARCHAR(MAX) = '';        
        
DECLARE @KeywordsTable TABLE (        
 KeywordDescription NVARCHAR(MAX),        
 KeywordFormat NVARCHAR(MAX),        
 KeywordTypeId int        
);        
        
INSERT INTO @KeywordsTable (KeywordDescription, KeywordFormat,KeywordTypeId)        
 VALUES ('Division ID', @KeywordFormatStart + 'DivisionID' + @KeywordFormatEnd,1),        
 ('Division Name', @KeywordFormatStart + 'DivisionName' + @KeywordFormatEnd,1),        
 ('Section ID', @KeywordFormatStart + 'SectionID' + @KeywordFormatEnd,1),        
 ('Section Name', @KeywordFormatStart + 'SectionName' + @KeywordFormatEnd,1),        
 ('Project ID', @KeywordFormatStart + 'ProjectID' + @KeywordFormatEnd,1),   
 ('Project Location', @KeywordFormatStart + 'DBInfoProjectLocation' + @KeywordFormatEnd,1),
 --('Delegated Design Engineers to be Licensed in', @KeywordFormatStart + 'DBInfoProjectLocation' + @KeywordFormatEnd),        
 --('Project Location', @KeywordFormatStart + 'ProjectLocation' + @KeywordFormatEnd),        
 ('Project Name', @KeywordFormatStart + 'ProjectName' + @KeywordFormatEnd,0),        
 ('Page Number', @KeywordFormatStart + 'PageNumber' + @KeywordFormatEnd,1),        
 ('Section Page Count', @KeywordFormatStart + 'SectionPageCount' + @KeywordFormatEnd,1),        
 ('Project Page Count', @KeywordFormatStart + 'PageCount' + @KeywordFormatEnd,1),        
 ('Date', @KeywordFormatStart + 'DateField' + @KeywordFormatEnd,1),        
 ('Time', @KeywordFormatStart + 'TimeField' + @KeywordFormatEnd,1),        
        
 ('Report Name', @KeywordFormatStart + 'ReportName' + @KeywordFormatEnd,2),        
 ('Page Number', @KeywordFormatStart + 'PageNumber' + @KeywordFormatEnd,2),        
 ('Section Page Count', @KeywordFormatStart + 'SectionPageCount' + @KeywordFormatEnd,2),        
 ('Project Page Count', @KeywordFormatStart + 'PageCount' + @KeywordFormatEnd,2),        
 ('Date', @KeywordFormatStart + 'DateField' + @KeywordFormatEnd,2),        
 ('Time', @KeywordFormatStart + 'TimeField' + @KeywordFormatEnd,2)  ,      
 --('Project Name', @KeywordFormatStart + 'ProjectName' + @KeywordFormatEnd,2)        
      
  ('Report Name', @KeywordFormatStart + 'ReportName' + @KeywordFormatEnd,3),        
 ('Page Number', @KeywordFormatStart + 'PageNumber' + @KeywordFormatEnd,3),        
 ('Date', @KeywordFormatStart + 'DateField' + @KeywordFormatEnd,3),        
 ('Time', @KeywordFormatStart + 'TimeField' + @KeywordFormatEnd,3)       
        
SELECT        
 *        
FROM @KeywordsTable         
END 