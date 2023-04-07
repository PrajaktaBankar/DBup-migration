
CREATE PROCEDURE [dbo].[usp_RemoveIsDeletedRecords]        
AS        
BEGIN        
        
BEGIN TRY        
    
Delete SC     
from SegmentComment SC WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
--Delete TPS     
--from TrackProjectSegment TPS WITH(NOLOCK)     
--WHERE IsDeleted = 1    
    
Delete PCO     
from ProjectChoiceOption PCO WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
Delete PGT     
from ProjectGlobalTerm PGT WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
Delete PNI     
from ProjectNoteImage PNI WITH(NOLOCK)    
inner join ProjectNote PN WITH(NOLOCK)    
on PNI.ProjectId = PN.ProjectId AND PNI.SectionId = PN.SectionId AND PNI.NoteId = PN.NoteId    
WHERE PN.IsDeleted = 1    
    
Delete PN     
from ProjectNote PN WITH(NOLOCK)    
WHERE IsDeleted = 1    
    
Delete PRS     
from ProjectReferenceStandard PRS WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
--Delete tbl from ProjectRevitFile WITH(NOLOCK) WHERE IsDeleted = 1    
Delete PC     
from ProjectChoiceOption PC with(nolock)     
inner join ProjectSegmentChoice PS WITH(NOLOCK)    
on PC.SegmentChoiceId = PS.SegmentChoiceId    
where PS.IsDeleted=1    
    
Delete PSC     
from ProjectSegmentChoice PSC WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
Delete PSGT     
from ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
Delete PSL     
from ProjectSegmentLink PSL WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
Delete PSRS     
from ProjectSegmentReferenceStandard PSRS WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
Delete PSRT     
from ProjectSegmentRequirementTag PSRT WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
Delete PSUT     
from ProjectSegmentUserTag PSUT WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
Delete RS     
from ReferenceStandard RS WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
--Delete PS     
--from ProjectSection PS WITH(NOLOCK)     
--WHERE IsDeleted = 1    
    
    
Delete PCO    
from ProjectChoiceOption PCO WITH(NOLOCK)    
inner join ProjectSegmentChoice PSC WITH(NOLOCK)    
on PCO.SegmentChoiceId=PSC.SegmentChoiceId    
inner join ProjectSegment PSeg WITH(NOLOCK)    
on  PSC.SegmentId = PSeg.SegmentId    
WHERE PSeg.IsDeleted = 1    
    
Delete PSC    
from ProjectSegmentChoice PSC WITH(NOLOCK)    
inner join ProjectSegment PSeg WITH(NOLOCK)    
on  PSC.SegmentId = PSeg.SegmentId    
WHERE PSeg.IsDeleted = 1    
    
Delete PME    
from ProjectMigrationException PME WITH(NOLOCK)    
inner join ProjectSegment PSeg WITH(NOLOCK)    
on  PME.SegmentId = PSeg.SegmentId    
WHERE PSeg.IsDeleted = 1    
    
--Delete TPS    
--from TrackProjectSegment TPS WITH(NOLOCK)    
--inner join ProjectSegment PSeg WITH(NOLOCK)    
--on  TPS.SegmentId = PSeg.SegmentId    
--WHERE PSeg.IsDeleted = 1    
    
Delete PSeg     
from ProjectSegment PSeg WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
Delete SCO     
from SelectedChoiceOption SCO WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
--Delete tbl from LuDateFormat WITH(NOLOCK) WHERE IsDeleted = 1    
    
Delete PSRT    
from ProjectSegmentRequirementTag PSRT WITH(NOLOCK)    
inner join ProjectSegmentStatus PSS WITH(NOLOCK)    
on  PSRT.SegmentStatusId = PSS.SegmentStatusId    
WHERE PSS.IsDeleted = 1    
    
Delete PN    
from ProjectNote PN WITH(NOLOCK)    
inner join ProjectSegmentStatus PSS WITH(NOLOCK)    
on  PN.SegmentStatusId = PSS.SegmentStatusId    
WHERE PSS.IsDeleted = 1    
    
-------------------------------------------------    
Delete PCO    
from ProjectChoiceOption PCO with(nolock)    
inner join ProjectSegmentChoice psc with(nolock)    
on PCO.SegmentChoiceId = psc.SegmentChoiceId    
inner join ProjectSegment PS WITH(NOLOCK)    
on psc.SegmentId = PS.SegmentId    
inner join ProjectSegmentStatus PSS WITH(NOLOCK)    
on  PS.SegmentStatusId = PSS.SegmentStatusId    
WHERE PSS.IsDeleted = 1    
    
Delete psc    
from ProjectSegmentChoice psc with(nolock)    
inner join ProjectSegment PS WITH(NOLOCK)    
on psc.SegmentId = PS.SegmentId    
inner join ProjectSegmentStatus PSS WITH(NOLOCK)    
on  PS.SegmentStatusId = PSS.SegmentStatusId    
WHERE PSS.IsDeleted = 1    
    
Delete PS    
from ProjectSegment PS WITH(NOLOCK)    
inner join ProjectSegmentStatus PSS WITH(NOLOCK)    
on  PS.SegmentStatusId = PSS.SegmentStatusId    
WHERE PSS.IsDeleted = 1    
    
Delete PSUT    
from ProjectSegmentUserTag PSUT WITH(NOLOCK)    
inner join ProjectSegmentStatus PSS WITH(NOLOCK)    
on  PSUT.SegmentStatusId = PSS.SegmentStatusId    
WHERE PSS.IsDeleted = 1    
    
Delete PHL    
from ProjectHyperLink PHL WITH(NOLOCK)    
inner join ProjectSegmentStatus PSS WITH(NOLOCK)    
on  PHL.SegmentStatusId = PSS.SegmentStatusId    
WHERE PSS.IsDeleted = 1    
    
Delete PST    
from ProjectSegmentTab PST WITH(NOLOCK)    
inner join ProjectSegmentStatus PSS WITH(NOLOCK)    
on  PST.SegmentStatusId = PSS.SegmentStatusId    
WHERE PSS.IsDeleted = 1    
    
Delete PSS     
from ProjectSegmentStatus PSS WITH(NOLOCK)     
WHERE IsDeleted = 1    
---------------------------------------------------    
Delete TS    
from TemplateStyle TS with(nolock)    
inner join Style STYL WITH(NOLOCK)    
on TS.StyleId = STYL.StyleId     
WHERE STYL.IsDeleted = 1    
    
Delete STYL     
from Style STYL WITH(NOLOCK)     
WHERE IsDeleted = 1    
------------------------------------------------------    
    
-- P UserId - 1561 CustomerId - 643  ProjectId - 411 Project Name - NMS French Project    
--select P.*    
--from Project P with(nolock)    
--inner join Template TEMLT WITH(NOLOCK)     
--on P.TemplateId = TEMLT.TemplateId    
--WHERE TEMLT.IsDeleted = 1    
    
--Delete TEMLT     
--from Template TEMLT WITH(NOLOCK)     
--WHERE IsDeleted = 1    
-----------------------------------------------------------------------------------------    
Delete PE     
from ProjectExport PE WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
Delete UGT     
from UserGlobalTerm UGT WITH(NOLOCK)     
WHERE IsDeleted = 1    
    
    
END TRY        
BEGIN CATCH        
 SELECT ERROR_MESSAGE()        
          
END CATCH        
END  
GO


