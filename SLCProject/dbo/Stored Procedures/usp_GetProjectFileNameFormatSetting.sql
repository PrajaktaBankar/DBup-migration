CREATE PROCEDURE [dbo].[usp_GetProjectFileNameFormatSetting]  
(               
 @ProjectId INT,                          
 @CustomerId INT                                                           
)AS                                    
BEGIN  

  DECLARE @PProjectId INT = @ProjectId                          
  DECLARE @PCustomerId INT = @CustomerId     
  DECLARE @PFileDateFormat NVARCHAR(100);    
IF  NOT EXISTS(select TOP 1 1 from ProjectDateFormat WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId)    
BEGIN  

SELECT @PFileDateFormat=PDF.DateFormat FROM Project P WITH(NOLOCK) INNER JOIN ProjectDateFormat PDF WITH(NOLOCK)    
ON P.MasterDataTypeId = PDF.MasterDataTypeId AND PDF.ProjectId IS NULL    
WHERE P.ProjectId = @PProjectId AND P.CustomerId=@PCustomerId    
    
END  
ELSE    
BEGIN 

SELECT @PFileDateFormat=[DateFormat] from ProjectDateFormat WITH(NOLOCK) WHERE ProjectId = @PProjectId AND CustomerId = @PCustomerId 

END                                    
             
              
IF NOT EXISTS (SELECT TOP 1                          
  1                          
 FROM FileNameFormatSetting WITH (NOLOCK)                          
 WHERE ProjectId = @PProjectId                           
 AND CustomerId = @PCustomerId)                          
BEGIN      
       
select FileFormatCategoryId,IncludeAutherSectionId,Separator,  case when CHARINDEX('D:',FormatJsonWithPlaceHolder) = 0 then FormatJsonWithPlaceHolder else  
 REPLACE(FormatJsonWithPlaceHolder,SUBSTRING( FormatJsonWithPlaceHolder,( CHARINDEX('D:', FormatJsonWithPlaceHolder)+2) ,((CHARINDEX('@}', FormatJsonWithPlaceHolder))-( CHARINDEX('D:', FormatJsonWithPlaceHolder)+2) )),@PFileDateFormat)  end as  
   FormatJsonWithPlaceHolder,@PProjectId as ProjectId,@PCustomerId as CustomerId               
  FROM FileNameFormatSetting WITH(NOLOCK)  WHERE ProjectId IS NULL  AND CustomerId IS NULL    
            
  select [Name], PlaceHolder,[Value],IsForDocument,IsForProjectReport          
  FROM LuFileNamePlaceHolder WITH(NOLOCK)                   
              
END                          
ELSE                          
BEGIN       
                  
   select FileFormatCategoryId,IncludeAutherSectionId,Separator,    case when CHARINDEX('D:',FormatJsonWithPlaceHolder) = 0 then FormatJsonWithPlaceHolder else  
   REPLACE(FormatJsonWithPlaceHolder,SUBSTRING( FormatJsonWithPlaceHolder,( CHARINDEX('D:', FormatJsonWithPlaceHolder)+2) ,((CHARINDEX('@}', FormatJsonWithPlaceHolder))-( CHARINDEX('D:', FormatJsonWithPlaceHolder)+2) )),@PFileDateFormat)  end as  
   FormatJsonWithPlaceHolder,ProjectId,CustomerId              
   FROM FileNameFormatSetting WITH(NOLOCK)  WHERE ProjectId=@PProjectId and CustomerId=@PCustomerId                
              
  select [Name],PlaceHolder,[Value] ,IsForDocument,IsForProjectReport              
  FROM LuFileNamePlaceHolder WITH(NOLOCK)                  
END              
END    
    
