use [SLCProject_SqlSlcOp004]
 
 GO
  /*
  server name : Server 004
 Customer Support 57903: SLC: TOC Section Numbers Not Ordered Correctly
 
 */
 update  pt
 set pt.DivisionId=3,
 pt.DivisionCode = 01
 from ProjectSection pt WITH(NOLOCK)
 where ProjectId = 9319 and CustomerId = 2742 and SourceTag  like '%015420%'

