 --Execute on server 3
 --Customer Support 56183: lvl issue and paragraphs not turning on - Davison Associates - 53494
 UPDATE PSS SET PSS.parentSegmentStatusId = 854957714
 FROM ProjectSegmentStatus PSS WITH(NOLOCK)
 WHere PSS.SegmentStatusId in(854957715,854957716,854957720,854957721,854957722) 
 AND PSS.SectionId=14758971