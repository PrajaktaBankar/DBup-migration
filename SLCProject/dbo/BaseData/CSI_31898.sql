--Customer Support 31898: Title and Section Spaced on SLC
--Execute this on Server 4

UPDATE PSS WITH (NOLOCK)
SET PSS.FormattingJson = NULL
FROM ProjectSegmentStatus PSS WHERE PSS.ProjectId = 684 AND PSS.SectionId = 783110 AND PSS.SegmentStatusId = 30389484