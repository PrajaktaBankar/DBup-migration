-- Execute on server 3

use SLCProject;

go


update PS set SegmentDescription = '{RSTEMP#69}' from ProjectSegment PS WITH(NOLOCK) where SegmentId = 34403859;
update PS set SegmentDescription = '{RSTEMP#10003930}' from ProjectSegment PS WITH(NOLOCK) where SegmentId = 34403860;
update PS set SegmentDescription = '{RSTEMP#2301}' from ProjectSegment PS WITH(NOLOCK) where SegmentId = 34403861;
update PS set SegmentDescription = '{RSTEMP#2705}' from ProjectSegment PS WITH(NOLOCK) where SegmentId = 34403862;
update PS set SegmentDescription = '{RSTEMP#853}' from ProjectSegment PS WITH(NOLOCK) where SegmentId = 34403863;
update PS set SegmentDescription = '{RSTEMP#882}' from ProjectSegment PS WITH(NOLOCK) where SegmentId = 34403864;
update PS set SegmentDescription = '{RSTEMP#1053}' from ProjectSegment PS WITH(NOLOCK) where SegmentId = 34403865;
update PS set SegmentDescription = '{RSTEMP#900}' from ProjectSegment PS WITH(NOLOCK) where SegmentId = 34403869;
update PS set SegmentDescription = '{RSTEMP#981}' from ProjectSegment PS WITH(NOLOCK) where SegmentId = 34403866;
update PS set SegmentDescription = '{RSTEMP#1056}' from ProjectSegment PS WITH(NOLOCK) where SegmentId = 34403868;
update PS set SegmentDescription = '{RSTEMP#10003912}' from ProjectSegment PS WITH(NOLOCK) where SegmentId = 34403867;



update PSS set ParentSegmentStatusId = 213253425 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 215935016;
update PSS set ParentSegmentStatusId = 213253425 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 215935017;
update PSS set ParentSegmentStatusId = 213253425 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 215935018;
update PSS set ParentSegmentStatusId = 213253425 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 215935019;
update PSS set ParentSegmentStatusId = 213253425 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 215935020;
update PSS set ParentSegmentStatusId = 213253425 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 215935021;
update PSS set ParentSegmentStatusId = 213253425 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 215935022;
update PSS set ParentSegmentStatusId = 213253425 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 215935026;
update PSS set ParentSegmentStatusId = 213253425 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 215935023;
update PSS set ParentSegmentStatusId = 213253425 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 215935025;
update PSS set ParentSegmentStatusId = 213253425 from ProjectSegmentStatus PSS WITH(NOLOCK) where SegmentStatusId = 215935024;