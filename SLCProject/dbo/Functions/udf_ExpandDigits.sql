    
-- function: standardize alphanumeric string by left padding 0 to the numeric string inside @src    
-- we assume source string to be less than 1K in length (you can change it if needed)    
-- example    
-- select dbo.udf_ExpandDigits('a1-bc23-def456-ghij', 5, '0') will return    
-- a00001-bc00023-def00456-ghij    
     
CREATE FUNCTION dbo.udf_ExpandDigits(@src varchar(1024), @plen int, @letter char(1))    
returns varchar(max)    
as     
begin    
   if @plen >= 100    
      return @src;    
   declare @p int, @p2 int, @num varchar(100);    
   declare @ret_val varchar(max)='';    
   if (PATINDEX('%[0-9]%', @src) =0 )    
      set @ret_val = @src;    
   else    
   begin    
      set @p = patindex('%[0-9]%', @src);    
     
     
      while(@p > 0)    
      begin    
         set @p2=patindex('%[^0-9]%', substring(@src, @p, 1000))     
         if (@p2 > 0)    
         begin    
            set @num=substring(@src, @p, @p2-1);    
            set @ret_val += left(@src, @p-1) + case when len(@num) < @plen then right(replicate(@letter, @plen) + @num, @plen) else @num end; ;    
            set @src = substring(@src, @p+@p2-1, len(@src));    
            set @p = patindex('%[0-9]%', @src);    
         end    
         else    
         begin    
            set @num = substring(@src, @p, len(@src));    
            set @ret_val += left(@src, @p-1)+ case when len(@num) < @plen then right(replicate(@letter, @plen) + @num, @plen) else @num end;    
            set @src ='';    
            break;    
         end    
     
      end -- while (@p > 0)    
      if len(@src) > 0    
         set @ret_val += @src;    
   end -- else    
   return @ret_val;    
end -- function    