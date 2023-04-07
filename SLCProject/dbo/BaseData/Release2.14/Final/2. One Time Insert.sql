Use [SLCProject]
GO

Update t set t.ApplyTitleStyleToEOS=0 from Template t With(nolock)
 where  IsSystem = 1 AND  t.ApplyTitleStyleToEOS = 1