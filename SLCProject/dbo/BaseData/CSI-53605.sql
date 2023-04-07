--Execute Server 3
--Customer Support 53605: SLC text will not unbold
 UPDATE PS SET SegmentDescription='<span>ADMINISTRATIVE REQUIREMENTS</span>' FROM ProjectSegment PS WITH (NOLOCK) WHERE  ProjectId=7750 and SegmentStatusId=368618666
 UPDATE PS SET SegmentDescription='<span>MOCKUP - FOR STC RATED ASSEMBLIES</span>' FROM ProjectSegment PS WITH (NOLOCK) WHERE  ProjectId=7750 and SegmentStatusId=368618621