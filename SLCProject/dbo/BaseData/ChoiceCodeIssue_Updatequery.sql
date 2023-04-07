SELECT
	*
FROM SelectedChoiceOption
WHERE ProjectId = 6304
AND SegmentChoiceCode = 186532
UPDATE ps
SET ps.SegmentDescription = '{CH#186532}Joints between Fixtures in Wet Areas and Floors, Walls, and Ceilings:  Mildew-resistant silicone sealant; {CH#186531}.'
FROM ProjectSegment ps WITH (NOLOCK)
WHERE Projectid = 6304
AND SegmentStatusId = 267589938