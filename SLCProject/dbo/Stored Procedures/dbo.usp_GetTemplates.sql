CREATE PROCEDURE [dbo].[usp_GetTemplates]
(      
 @CustomerId INT,      
 @masterDataTypeId INT      
)      
AS      
BEGIN      
 DECLARE @PCustomerId INT = @CustomerId;      
 --DECLARE @PmasterDataTypeId INT = @masterDataTypeId;      
    
 SELECT      
     T.TemplateId      
    ,T.[Name]      
    ,T.TitleFormatId      
    ,T.SequenceNumbering      
    ,T.CustomerId      
    ,T.IsSystem      
    --,T.IsDeleted      
    --,T.CreatedBy      
    --,T.CreateDate      
    --,T.ModifiedBy      
    --,T.ModifiedDate      
    ,T.MasterDataTypeId      
    --,T.A_TemplateId      
    ,T.ApplyTitleStyleToEOS      
 FROM Template T WITH (NOLOCK)    
 WHERE (T.CustomerId = @PCustomerId OR T.IsSystem = 1) AND ISNULL(T.IsDeleted, 0) = 0
END;

--EXEC usp_GetTemplates 641, 1