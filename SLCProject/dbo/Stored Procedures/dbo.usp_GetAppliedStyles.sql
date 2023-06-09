CREATE PROCEDURE [dbo].[usp_GetAppliedStyles]      
(      
 @TemplateId INT      
)      
AS      
BEGIN  
      
  DECLARE  @PTemplateId INT =  @TemplateId;  
SELECT  
 ts.CustomerId  
   ,ts.TemplateStyleId  
   ,  
 --Cast(ts.Level as int) as Level,       
 ts.Level  
   ,ts.StyleId  
   ,ts.TemplateId  
   ,st.Alignment  
   ,st.IsBold  
   ,st.CharAfterNumber  
   ,st.CharBeforeNumber  
   ,st.FontName  
   ,st.FontSize  
   ,st.HangingIndent  
   ,st.IncludePrevious  
   ,st.IsItalic  
   ,st.LeftIndent  
   ,st.NumberFormat  
   ,st.NumberPosition  
   ,st.PrintUpperCase  
   ,st.ShowNumber  
   ,st.StartAt  
   ,st.Name AS st_Name  
   ,st.TopDistance  
   ,st.Underline  
   ,st.SpaceBelowParagraph  
   ,st.IsSystem  
   ,st.IsDeleted  
   ,st.CreatedBy  
   ,st.CreateDate  
   ,st.ModifiedBy  
   ,st.ModifiedDate  
   ,st.MasterDataTypeId  
   ,tp.A_TemplateId  
   ,tp.Name AS tp_Name  
   ,tp.TitleFormatId  
   ,tp.SequenceNumbering  
   ,tp.IsSystem AS tp_IsSystem  
   ,tp.IsDeleted AS tp_IsDeleted  
   ,tp.CreatedBy AS tp_CreatedBy  
   ,tp.CreateDate AS tp_CreateDate  
   ,tp.ModifiedBy AS tp_ModifiedBy  
   ,tp.ModifiedDate AS tp_ModifiedDate  
   ,tp.MasterDataTypeId AS tp_MasterDataTypeId  
   ,ISNULL(tp.ApplyTitleStyleToEOS,0) as ApplyTitleStyleToEOS
FROM TemplateStyle ts WITH (NOLOCK)  
INNER JOIN Template tp WITH (NOLOCK)  
 ON ts.TemplateId = tp.TemplateId  
INNER JOIN Style st WITH (NOLOCK)  
 ON ts.StyleId = st.StyleId  
WHERE ts.TemplateId = @PTemplateId;  
  
END;  

GO
