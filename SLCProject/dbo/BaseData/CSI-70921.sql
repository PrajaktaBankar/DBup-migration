/*
 Server name : SLCProject_SqlSlcOp004 (Server 04)
 Customer Support 70921: Sections not selected appearing on the TOC Report - 40980/1812
*/

USE SLCProject_SqlSlcOp004
GO

DECLARE @CustomerId INT = 1812;
DECLARE @ProjectId INT = 24811;

UPDATE PSS SET PSS.SegmentStatusTypeId = 6
FROM ProjectSection PS WITH(NOLOCK) 
LEFT JOIN ProjectSegmentStatus PSS WITH (NOLOCK)           
    ON  PSS.CustomerId = PS.CustomerId AND PSS.ProjectId = PS.ProjectId AND PSS.SectionId = PS.SectionId      
    AND ISNULL(PSS.IndentLevel, 0) = 0 AND ISNULL(PSS.ParentSegmentStatusId, 0) = 0 AND ISNULL(PSS.SequenceNumber, 0) = 0 AND ISNULL(PSS.IsDeleted, 0) = 0
WHERE PS.CustomerId = @CustomerId AND PS.ProjectId = @ProjectId	
AND ISNULL(PS.IsDeleted, 0) = 0
AND (PSS.IsParentSegmentStatusActive = 1 AND PSS.SegmentStatusTypeId < 6)
AND DivisionCode = '31'
AND PS.mSectionId IN (903, 906);
