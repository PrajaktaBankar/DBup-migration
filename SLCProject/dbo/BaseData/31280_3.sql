--Execute this on Server 2
--Customer Support 31280: CH# -Aaron Pilate with GH2 Architects - 12550
       
       INSERT INTO ProjectChoiceOption
       select 
       psc.SegmentChoiceId	,co.SortOrder	,psc.SegmentChoiceSource	,co.OptionJson	,psc.ProjectId	,psc.SectionId	,psc.CustomerId	,co.ChoiceOptionCode
       	,psc.CreatedBy	,co.CreateDate	,psc.ModifiedBy	,co.ModifiedDate	, null as A_ChoiceOptionId	,0 as IsDeleted 
       	from ProjectSegmentChoice psc WITH(NOLOCK)
       	 INNER JOIN ProjectSegment ps WITH(NOLOCK) ON 
       ps.ProjectId=psc.ProjectId and ps.CustomerId=psc.CustomerId and ps.SectionId=psc.SectionId and ps.SegmentStatusId=psc.SegmentStatusId 
       and ps.SegmentId=psc.SegmentId 
	   INNER JOIN ProjectSegmentStatus pss  WITH(NOLOCK)
       on ps.ProjectId=pss.ProjectId and ps.SectionId=pss.SectionId and ps.SegmentStatusId=pss.SegmentStatusId and ps.SegmentId=pss.SegmentId
       and ps.CustomerId=pss.CustomerId
       LEFT OUTER JOIN ProjectChoiceOption pco WITH(NOLOCK) ON
       pco.ProjectId=ps.ProjectId and pco.SectionId=ps.SectionId and pco.CustomerId=ps.CustomerId AND pco.SegmentChoiceId=psc.SegmentChoiceId
       INNER JOIN SLCMaster..SegmentChoice slcmc WITH(NOLOCK) on slcmc.SegmentChoiceCode=psc.SegmentChoiceCode 
       INNER JOIN SLCMaster..ChoiceOption  co WITH(NOLOCK) ON co.SegmentChoiceId=slcmc.SegmentChoiceId
       WHERE  ps.ProjectId=4827 and  ps.IsDeleted=0 and pco.SegmentChoiceId IS NULL order BY co.ChoiceOptionCode

    
     INSERT INTO SelectedChoiceOption
     select DISTINCT  psc.SegmentChoiceCode	,sclmsco.ChoiceOptionCode,	psc.SegmentChoiceSource	,sclmsco.IsSelected	,psc.SectionId	
     ,psc.ProjectId	,psc.CustomerId	,null as OptionJson,0 as	IsDeleted 
	 from ProjectSegmentChoice psc WITH(NOLOCK) 
	 INNER JOIN ProjectSegment ps WITH(NOLOCK) ON 
    ps.ProjectId=psc.ProjectId and ps.CustomerId=psc.CustomerId and ps.SectionId=psc.SectionId and ps.SegmentStatusId=psc.SegmentStatusId 
    and ps.SegmentId=psc.SegmentId 
	INNER JOIN ProjectSegmentStatus pss WITH(NOLOCK)
    on ps.ProjectId=pss.ProjectId and ps.SectionId=pss.SectionId and ps.SegmentStatusId=pss.SegmentStatusId and ps.SegmentId=pss.SegmentId
    and ps.CustomerId=pss.CustomerId
    inner JOIN ProjectChoiceOption pco WITH(NOLOCK) ON
    pco.ProjectId=ps.ProjectId and pco.SectionId=ps.SectionId and pco.CustomerId=ps.CustomerId AND pco.SegmentChoiceId=psc.SegmentChoiceId  
    LEFT OUTER JOIN SelectedChoiceOption sco WITH(NOLOCK) ON sco.ProjectId=pco.ProjectId and pco.SectionId=sco.SectionId and pco.CustomerId=sco.CustomerId and psc.SegmentChoiceCode=sco.SegmentChoiceCode
    and pco.ChoiceOptionCode=sco.ChoiceOptionCode and sco.ChoiceOptionSource='U'
    INNER JOIN SLCMaster..SegmentChoice slcmc WITH(NOLOCK) on slcmc.SegmentChoiceCode=psc.SegmentChoiceCode 
    INNER JOIN SLCMaster..ChoiceOption co WITH(NOLOCK) ON co.SegmentChoiceId=slcmc.SegmentChoiceId AND co.ChoiceOptionCode=pco.ChoiceOptionCode
    INNER JOIN SLCMaster..SelectedChoiceOption sclmsco WITH(NOLOCK) on slcmc.SegmentChoiceCode=sclmsco.SegmentChoiceCode and co.ChoiceOptionCode=sclmsco.ChoiceOptionCode
    WHERE  ps.ProjectId=4827 and  ps.IsDeleted=0  and sco.ChoiceOptionCode IS NULL order BY sclmsco.ChoiceOptionCode


   INSERT INTO SelectedChoiceOption
   SELECT 
   psc.SegmentChoiceCode	,pco.ChoiceOptionCode	,pco.ChoiceOptionSource	,slcmsco.IsSelected	,psc.SectionId	,psc.ProjectId	,psc.CustomerId	,null as OptionJson	,0 as IsDeleted
    FROM ProjectChoiceOption pco WITH(NOLOCK)
   INNER JOIN ProjectSegmentChoice psc WITH(NOLOCK)
   ON pco.ProjectId=psc.ProjectId and pco.CustomerId=psc.CustomerId and pco.SectionId=psc.SectionId AND
   pco.SegmentChoiceId=psc.SegmentChoiceId 
   LEFT OUTER JOIN SelectedChoiceOption sco WITH(NOLOCK) ON pco.CustomerId=sco.CustomerId and pco.SectionId=sco.SectionId 
   and pco.ProjectId=sco.ProjectId and pco.ChoiceOptionCode=sco.ChoiceOptionCode and psc.SegmentChoiceCode=sco.SegmentChoiceCode
   and sco.ChoiceOptionSource=pco.ChoiceOptionSource and sco.ChoiceOptionSource='U'
   INNER JOIN SLCMaster..SelectedChoiceOption slcmsco WITH(NOLOCK) ON slcmsco.SegmentChoiceCode=psc.SegmentChoiceCode 
   WHERE psc.ProjectId=4827  and   sco.ChoiceOptionCode IS NULL
    
	
		
UPDATE ps SET  ps.Description=slcms.Description from ProjectSection ps WITH(NOLOCK) 
INNER JOIN SLCMaster.dbo.Section slcms WITH(NOLOCK) on ps.mSectionId=slcms.SectionId and ps.SourceTag=slcms.SourceTag
WHERE   CustomerId=874 and ps.Description like '%\plain\rtlch\af1%'