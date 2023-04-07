--Customer Support 57742: SLC: TOC Showing Phantom Sections (Gresham Smith)
--Server 4

update pss set pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss WITH (NOLOCK)
where pss.SegmentStatusId in (820446736,820446814,820446818,820447026,820446940,820446941,820446942,820446944,820446945 )

update pss set pss.IsParentSegmentStatusActive = 1, pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446948
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820449516 and pss.SequenceNumber=865.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820446939 and pss.SequenceNumber=866.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455820 and pss.SequenceNumber=867.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455822 and pss.SequenceNumber=868.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455824 and pss.SequenceNumber=869.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455826 and pss.SequenceNumber=870.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820446940 and pss.SequenceNumber=871.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455828 and pss.SequenceNumber=872.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455830 and pss.SequenceNumber=873.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820446941 and pss.SequenceNumber=874.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820453864 and pss.SequenceNumber=875.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455832 and pss.SequenceNumber=876.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820446942 and pss.SequenceNumber=877.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455834 and pss.SequenceNumber=878.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820446943 and pss.SequenceNumber=879.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820446944 and pss.SequenceNumber=880.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455836 and pss.SequenceNumber=881.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820449518 and pss.SequenceNumber=882.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820446945 and pss.SequenceNumber=883.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820446946 and pss.SequenceNumber=884.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455838 and pss.SequenceNumber=885.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820446947 and pss.SequenceNumber=886.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455840 and pss.SequenceNumber=887.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455842 and pss.SequenceNumber=888.0000 
update pss set pss.ParentSegmentStatusId =  820446758 , pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820446948 and pss.SequenceNumber=889.0000 

update pss set pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss WITH (NOLOCK)
where pss.SegmentStatusId in (820455822,820455832 ,820446942 ,820455836,820446945,820446947,820455832,820455836,820446943,820446946,820446949,820446954,820446936,820455966)

update pss set pss.IsParentSegmentStatusActive = 1 , pss.ParentSegmentStatusId =820446720  from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446760

update pss set pss.IsParentSegmentStatusActive = 1,  pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId in( 820446939,820449516)
update pss set pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId in ( 820455820 , 820455822 , 820455824 , 820446940) 
update pss set pss.IsParentSegmentStatusActive = 1,pss.ParentSegmentStatusId =820446720  from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446762

update pss set pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss WITH (NOLOCK)
where pss.SegmentStatusId in (820446824,820446826,820446828,820446829,820446830,820456216,820456218,820449528,820449532,820449534,820456242,820448892,820448902,820456250)

update pss set pss.IsParentSegmentStatusActive = 1, pss.ParentSegmentStatusId =820446720 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446764

update pss set pss.IsParentSegmentStatusActive = 1,pss.ParentSegmentStatusId =820446720  from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446766

update pss set pss.IsParentSegmentStatusActive = 1, pss.ParentSegmentStatusId =820446720 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446768

update pss set pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss WITH (NOLOCK)
where pss.SegmentStatusId in (820449204,  820447025, 820446827, 820456224, 820448886,820448266,820446838,820446839,820446772,820456170,820446840,820446841,820456188,820446842,820449556,820448608,820456154,820456156,820446843,820446844,820446845)

update pss set pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss WITH (NOLOCK)
where pss.SegmentStatusId in (820446846,820446953,820449262,820446848,820447015,820446849,820446850,820449310,820456056,820446840,820446841,820456188,820446842,820449556,820448608,820456154,820456156,820446843,820446844,820446845,820446847,820456036)

update pss set pss.IsParentSegmentStatusActive = 1, pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820455206
update pss set pss.IsParentSegmentStatusActive = 1, pss.ParentSegmentStatusId =820446720 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446776
update pss set pss.IsParentSegmentStatusActive = 1 , pss.ParentSegmentStatusId =820446720  from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446810

update pss set pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss WITH (NOLOCK)
where pss.SegmentStatusId in (820446865,820446851,820446852,820446854,820446853,820446855,820446857,820446858,820446859,820446860,820446861,820446862,820446863,820446966)

update pss set pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss WITH (NOLOCK)
where pss.SegmentStatusId in (820446968,820446969,820446970,820446971,820446965,820446967,820453958,820453956,820453962,820453966,820453970,820446972,820447016,820446973,820453898,820446974,820453930)

update pss set pss.IsParentSegmentStatusActive = 1 ,pss.ParentSegmentStatusId =820446720 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446690
update pss  set pss.IsParentSegmentStatusActive = 1 ,pss.ParentSegmentStatusId =820446720 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446692
update pss set pss.IsParentSegmentStatusActive = 1, pss.ParentSegmentStatusId =820446720 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446694 
update pss set pss.IsParentSegmentStatusActive = 1, pss.ParentSegmentStatusId =820446720 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446700
update pss set pss.IsParentSegmentStatusActive = 1, pss.ParentSegmentStatusId =820446720 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446696

update pss set pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss WITH (NOLOCK)
where pss.SegmentStatusId in (820453930,820453946,820446975,820454170,820446976,820446977,820446979,820446980,820446981,820446982,820446984,820446986,820446988,820446984,820446981,820446990,820446991,820446992)

update pss set pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss WITH (NOLOCK)
where pss.SegmentStatusId in (820446993,820446994,820446995,820447002,820447003,820447004,820446996,820446997,820446998,820446999,820447000,820447001,820446985,820446961)

update pss set pss.ParentSegmentStatusId =820446720 from ProjectSegmentstatus pss  WITH (NOLOCK) where pss.SegmentStatusId = 820453792
update pss  set pss.ParentSegmentStatusId =820446720 from ProjectSegmentstatus pss  WITH (NOLOCK) where pss.SegmentStatusId = 820453794
update pss  set pss.ParentSegmentStatusId = 820446720 from ProjectSegmentstatus pss  WITH (NOLOCK) where pss.SegmentStatusId in ( 820453736 ,820446698, 820454164, 820454166 , 820454168)

update pss set pss.IsParentSegmentStatusActive = 1 ,pss.ParentSegmentStatusId = 820446720 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820446964
update pss set pss.IsParentSegmentStatusActive = 1 ,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820447005
update pss set pss.IsParentSegmentStatusActive = 1, pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820447006
update pss set pss.IsParentSegmentStatusActive = 1 ,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820447007
update pss set pss.IsParentSegmentStatusActive = 1 ,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820447008
update pss set pss.IsParentSegmentStatusActive = 1 ,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820447009
update pss set pss.IsParentSegmentStatusActive = 1 ,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820447010
update pss set pss.IsParentSegmentStatusActive = 1 ,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820447011
update pss set pss.IsParentSegmentStatusActive = 1 ,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820447013
update pss set pss.IsParentSegmentStatusActive = 1, pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId = 820447014
update pss set pss.IndentLevel=3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId in( 820448344, 820453874 , 820448346,820448272,820453872,820456256,820453870)
 
 update pss set pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss WITH (NOLOCK)
where pss.SegmentStatusId in (820446698,820454210,820454180,820446987,820454210,820446983,820447012,820446989,820446978,820453960,820446856,820446950,820446951)

update pss set pss.ParentSegmentStatusId = 820446722,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455140	 and pss.SequenceNumber = 157.0000  and pss.IndentLevel = 4
update pss set pss.ParentSegmentStatusId = 820446722,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455142	 and pss.SequenceNumber = 158.0000  and pss.IndentLevel = 4
update pss set pss.ParentSegmentStatusId = 820446722,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455144	 and pss.SequenceNumber = 159.0000  and pss.IndentLevel = 4
update pss set pss.ParentSegmentStatusId = 820446722,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455146	 and pss.SequenceNumber = 160.0000  and pss.IndentLevel = 4
update pss set pss.ParentSegmentStatusId = 820446722,pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455148	 and pss.SequenceNumber = 161.0000  and pss.IndentLevel = 4
update pss set pss.ParentSegmentStatusId = 820446722,pss.IndentLevel = 3, pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId =  820455150 and pss.SequenceNumber = 162.0000  and pss.IndentLevel = 4
update pss set pss.ParentSegmentStatusId = 820446722,pss.IndentLevel = 3 from ProjectSegmentstatus pss  WITH (NOLOCK) where pss.SegmentStatusId =  820455152 and pss.SequenceNumber = 163.0000  and pss.IndentLevel = 4
update pss set pss.ParentSegmentStatusId = 820446722,pss.IndentLevel = 3 from ProjectSegmentstatus pss  WITH (NOLOCK) where pss.SegmentStatusId =  820446950 and pss.SequenceNumber = 164.0000  and pss.IndentLevel = 4
update pss set pss.ParentSegmentStatusId = 820446722,pss.IndentLevel = 3 , pss.IsParentSegmentStatusActive = 1 from ProjectSegmentstatus pss  WITH (NOLOCK) where pss.SegmentStatusId =  820446951	 and pss.SequenceNumber = 165.0000

update pss set  pss.IndentLevel = 3 from ProjectSegmentStatus pss WITH (NOLOCK) where pss.SegmentStatusId in ( 820455818, 820446865)
update pss set  pss.IndentLevel = 3 from ProjectSegmentStatus pss where pss.SegmentStatusId in (820453870, 820447006 , 820447012)
Update pss set  pss.ParentSegmentStatusId = 820446758, pss.IndentLevel = 3 from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId in( 820455844 , 820455846  , 820455848)
update pss set  pss.ParentSegmentStatusId = 820446720  from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId in( 820453782, 820453784 , 820453786 , 820453788 , 820453790 )
update pss set  pss.ParentSegmentStatusId = 820453792  from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId in( 820453870,820447006, 820453872 ,820448344, 820453874, 820448346 )
update pss set  pss.ParentSegmentStatusId = 820453794  from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId in( 820448272)
update pss set  pss.ParentSegmentStatusId = 820446720  from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId in( 820453796,820453798,820446961)
update pss set  pss.ParentSegmentStatusId = 820446961  from ProjectSegmentstatus pss WITH (NOLOCK) where pss.SegmentStatusId in( 820447007,820447008,820447009, 820447010,820447011,820447012,820447013, 820447014 )




 , 

