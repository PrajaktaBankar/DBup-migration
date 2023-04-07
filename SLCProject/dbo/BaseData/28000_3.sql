USE SLCProject
GO

--Customer Support 28000: SLC User Says Fill In The Blank Text was Replaced with {CH#} Issue - PPL 34275
--EXECUTE On server 2


 DELETE psc 
 FROM ProjectSegmentChoice psc  LEFT OUTER JOIN ProjectChoiceOption pco 
 on pco.SegmentChoiceId=psc.SegmentChoiceId and pco.ProjectId=psc.ProjectId AND pco.SectionId=psc.SectionId
 AND pco.CustomerId=psc.CustomerId
 WHERE   psc.ProjectId=5026  and pco.SegmentChoiceId IS NULL
  