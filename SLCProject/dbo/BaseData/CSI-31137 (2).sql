--USE [SLCProject_SqlSlcOp002]
--Customer Support 31137: Cannot Change Indent of Paragraphs and Words Are Breaking Improperly Across Lines

DECLARE @SectionId INT = 2914556;--6013132;

--Start : Update SequenceNumbers
DECLARE @statusIds NVARCHAR(MAX) = '';
SET @statusIds = (SELECT STUFF
(
(
SELECT CONCAT(',', PSS.SegmentStatusId)
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
WHERE PSS.SectionId = @SectionId
ORDER BY PSS.SequenceNumber
FOR XML PATH('')
),
1, 1, ''
) AS CommaSeparatedSeqNumbers);
SET @statusIds = '[' + @statusIds + ']';
EXEC usp_UpdateSegmentStatusSequence @statusIds
--End : Update SequenceNumbers

DROP TABLE IF EXISTS #SegmentsOfSection
SELECT PSS.SegmentStatusId, PSS.ParentSegmentStatusId, PSS.IndentLevel, PSS.SequenceNumber
INTO #SegmentsOfSection
FROM ProjectSegmentStatus PSS WITH (NOLOCK) WHERE PSS.SectionId = @SectionId ORDER BY PSS.SequenceNumber

DROP TABLE IF EXISTS #UpdatedHirarchyTable
SELECT SegmentStatusId, ParentSegmentStatusId, IndentLevel, 
ISNULL((SELECT TOP 1 SegmentStatusId
FROM #SegmentsOfSection SOS  WITH (NOLOCK)
WHERE SOS.SequenceNumber < PSS.SequenceNumber AND SOS.IndentLevel = (PSS.IndentLevel - 1)
ORDER BY SOS.SequenceNumber DESC), 0) AS ActualParentId
INTO #UpdatedHirarchyTable
FROM #SegmentsOfSection PSS WITH (NOLOCK)

--Update Parent Child Relationship
UPDATE PSS 
SET PSS.ParentSegmentStatusId = UHT.ActualParentId 
FROM #UpdatedHirarchyTable UHT WITH (NOLOCK) 
INNER JOIN ProjectSegmentStatus AS PSS WITH (NOLOCK) 
ON UHT.SegmentStatusId = PSS.SegmentStatusId;


UPDATE PSS SET PSS.SequenceNumber = 73.0001 FROM ProjectSegmentStatus PSS WITH (NOLOCK) WHERE PSS.SegmentStatusId = 111144458;
UPDATE PSS SET PSS.ParentSegmentStatusId = 111144458 FROM ProjectSegmentStatus PSS WITH (NOLOCK) WHERE PSS.SegmentStatusId = 111144456;
UPDATE PSS SET PSS.ParentSegmentStatusId = 111144458 FROM ProjectSegmentStatus PSS WITH (NOLOCK) WHERE PSS.SegmentStatusId = 111144457;