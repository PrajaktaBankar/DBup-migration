/*--Execute this on Server 2	*/DECLARE @ProjectId INT = 5450;DECLARE @CustomerId INT = 2452;DECLARE @SectionId INT = 6529141;UPDATE psrt SET IsDeleted = 1 from ProjectSegmentRequirementTag psrt WITH(NOLOCK) WHERE ProjectId = @ProjectId and SectionId = @SectionId and CustomerId = @CustomerId and
SegmentStatusId in (269284328,269284332,269284330,269284335,269284339,269284344,269284349,269284352,269284357,269284362,269284380,269284385,269284389,269284395,269284399,269284404,269284409,269284415,269284419,269284425,269284430,269284437,269284442,269284429,269284453,269284458,269284466,269284472,269284478,269284484
,269284489,269284495,269284497,269284506,269284510,269284522,269284504,269284533,269284514,269284543,269284526,269284555,269284560,269284566,269284571,269284577,269284582,269284587,269284598,269284604,269284610,269284592,269284622,269284627,269284632,269284643,269284649,269284655,269284661,269284666
,269284671,269284677,269284683,269284694,269284700,269284706,269284714,269284720,269284724,269284703,269284735,269284716,269284747,269284753,269284759,269284764,269284770,269284775,269284781,269284792,269284798,269284806,269284812,269284816,269284822,269284833,269284839,269284845,269284851,269284857
,269284863,269284869,269284875,269284881,269284868,269284898,269284904,269284910,269284914,269284920,269284927,269284932,269284938,269284944,269284949,269284955,269284937,269284966,269284972,269284978,269284986,269284988,269284994,269285000,269285006,269285010,269285016,269285022,269285014,269285033
,269285039,269285045,269285037,269285057,269285050,269285068,269285079,269285085,269285091,269285097,269285103,269285109,269285115,269285106,269285126,269285119,269285138,269285130,269285149,269285142,269285160,269285166,269285164,269285182,269285174,269285194,269285185,269285205,269285196,269285216
,269285222,269285228,269285218,269285239,269285230,269285250,269285241,269285261,269285272,269285278,269285284,269285290,269285292,269285298,269285304,269285309,269285307,269285320,269285327,269285331,269285335,269285341,269285347,269285353,269285363,269285369,269285374,269285380,269285386,269285392
,269285398,269285403,269285409,269285417,269285423,269285429,269285434,269285440,269285446,269285452,269285460,269285465,269285473,269285480,269285486,269285492,269285497,269285503,269285506,269285512,269285517,269285523,269285529,269285536,269285542,269285548,269285557,269285563,269285568,269285574
,269285580,269285586,269285592,269285601,269285607,269285612,269285618,269285624,269285630,269285636,269285642,269285647,269285653,269284638,269284516)GOUPDATE pss SET IsDeleted = 1 from ProjectSegmentStatus pss WITH(NOLOCK) WHERE ProjectId = @ProjectId and SectionId = @SectionId and CustomerId = @CustomerId and
SegmentStatusId in (269284328,269284332,269284330,269284335,269284339,269284344,269284349,269284352,269284357,269284362,269284380,269284385,269284389,269284395,269284399,269284404,269284409,269284415,269284419,269284425,269284430,269284437,269284442,269284429,269284453,269284458,269284466,269284472,269284478,269284484
,269284489,269284495,269284497,269284506,269284510,269284522,269284504,269284533,269284514,269284543,269284526,269284555,269284560,269284566,269284571,269284577,269284582,269284587,269284598,269284604,269284610,269284592,269284622,269284627,269284632,269284643,269284649,269284655,269284661,269284666
,269284671,269284677,269284683,269284694,269284700,269284706,269284714,269284720,269284724,269284703,269284735,269284716,269284747,269284753,269284759,269284764,269284770,269284775,269284781,269284792,269284798,269284806,269284812,269284816,269284822,269284833,269284839,269284845,269284851,269284857
,269284863,269284869,269284875,269284881,269284868,269284898,269284904,269284910,269284914,269284920,269284927,269284932,269284938,269284944,269284949,269284955,269284937,269284966,269284972,269284978,269284986,269284988,269284994,269285000,269285006,269285010,269285016,269285022,269285014,269285033
,269285039,269285045,269285037,269285057,269285050,269285068,269285079,269285085,269285091,269285097,269285103,269285109,269285115,269285106,269285126,269285119,269285138,269285130,269285149,269285142,269285160,269285166,269285164,269285182,269285174,269285194,269285185,269285205,269285196,269285216
,269285222,269285228,269285218,269285239,269285230,269285250,269285241,269285261,269285272,269285278,269285284,269285290,269285292,269285298,269285304,269285309,269285307,269285320,269285327,269285331,269285335,269285341,269285347,269285353,269285363,269285369,269285374,269285380,269285386,269285392
,269285398,269285403,269285409,269285417,269285423,269285429,269285434,269285440,269285446,269285452,269285460,269285465,269285473,269285480,269285486,269285492,269285497,269285503,269285506,269285512,269285517,269285523,269285529,269285536,269285542,269285548,269285557,269285563,269285568,269285574
,269285580,269285586,269285592,269285601,269285607,269285612,269285618,269285624,269285630,269285636,269285642,269285647,269285653,269284638,269284516)

GO

delete from ProjectSegmentStatus WHERE SegmentStatusId = 269284328 and ProjectId = @ProjectId and SectionId = @SectionId and CustomerId = @CustomerId;
