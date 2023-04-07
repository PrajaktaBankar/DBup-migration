--Execute this on Server 4
--Customer Support 76764: SLC: Blank Title Paragraph Appearing Above Title
--Record will be affected 5

Update ProjectSegment
Set IsDeleted = 1
Where ProjectId = 32010 And CustomerId = 1429 And SectionId = 40227944 And SegmentId = 431225132

Update ProjectSegmentStatus
Set IsDeleted = 1
Where ProjectId = 32010 And CustomerId = 1429 And SectionId = 40227944 And SegmentStatusId = 2319472313

Update ProjectSegmentStatus
Set SequenceNumber = '0.0000', SegmentId = null, SegmentOrigin = 'M'
Where ProjectId = 32010 And CustomerId = 1429 And SectionId = 40227944 And SegmentStatusId = 2319471965

Update ProjectSection
Set SortOrder = 13
Where ProjectId = 32010 And CustomerId = 1429 And SectionId = 40161644

Update ProjectSection
Set SortOrder = 9
Where ProjectId = 32010 And CustomerId = 1429 And SectionId = 40227944
