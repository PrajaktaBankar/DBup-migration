/*
Customer Support 71645: Duplicate Sections and Duplicate Text within Sections - 57117/1191
Execute on Server 3
*/
Update X Set IsDeleted = 1
FROM (SELECT
	    SectionId
	   ,SegmentStatusId
	   ,ParentSegmentStatusId
	   ,mSegmentStatusId
	   ,mSegmentId
	   ,SegmentSource
	   ,ProjectId 
	   ,IsDeleted 
	   ,ROW_NUMBER() OVER (PARTITION BY SectionId, mSegmentStatusId, mSegmentId, SegmentSource, ProjectId ORDER BY SegmentStatusId ASC) AS Rowno
	FROM ProjectSegmentStatus PSS with (NOLOCK)
	WHERE PSS.ProjectId = 16687
	AND PSS.SectionId = 19201596) AS X
WHERE x.Rowno > 1
--------------------------------------------------------------------------------------------------------------
Update X Set IsDeleted = 1
FROM (SELECT
	    SectionId
	   ,SegmentStatusId
	   ,ParentSegmentStatusId
	   ,mSegmentStatusId
	   ,mSegmentId
	   ,SegmentSource
	   ,ProjectId 
	   ,IsDeleted 
	   ,ROW_NUMBER() OVER (PARTITION BY SectionId, mSegmentStatusId, mSegmentId, SegmentSource, ProjectId ORDER BY SegmentStatusId ASC) AS Rowno
	FROM ProjectSegmentStatus PSS with (NOLOCK)
	WHERE PSS.ProjectId = 16687
	AND PSS.SectionId = 19201642) AS X
WHERE x.Rowno > 1

---------------------------------------------------------------------------------------------------------------

UPDATE PSS set  PSS.ParentSegmentStatusId=1129341306  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348206,1129339724,1129339847,1129341315)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339847  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341307)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129341307  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339816,1129339705,1129348207,1129348209,1129339727
,1129339728,1129348211,1129339729,1129339852,1129341312,1129348212,1129341519,1129339730,1129339853,1129341313,1129348213,1129351453,1129339854,1129341314,1129348214)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339705  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341520,1129341288,1129339817,1129339706)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348207  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339725,1129339848,1129341308,1129348208,1129339726,1129339849,1129341309)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339727  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339850,1129341310,1129348210)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339728  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339851,1129341311)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339854  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341289,1129339818)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348214  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339707,1129341518)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129341315  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348215,1129339857,1129341290,1129339859,1129339861,1129341327)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348215  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129351455,1129339856,1129341316,1129348216,1129351456)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339857  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341317,1129348217,1129351457,1129339858,1129341318,1129348218,1129351458)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129341290  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339819,1129339708,1129341517)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339859  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341291,1129339820,1129341319,1129348219,1129351459, 1129339860,1129341320)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129341320  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348220,1129351460)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339861  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341321,1129348221,1129351461,1129339862,1129341322,1129339709,1129348222,1129351462,1129339863,1129341323,1129348223,
1129351463,1129339864,1129341324,1129348224,1129351464,1129339865,1129341325,1129348225,1129351465,1129339866,1129341326,1129348226,1129351466,1129339867,1129341516,1129341292,1129339821,1129339710,1129341515)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129341327  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348227,1129351467,1129339869,1129341330,1129348231,1129351471,1129339872,1129339733,1129339736,1129341341,1129339882,1129351482)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129351467  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339868,1129341328,1129348228,1129351468)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339869  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341329,1129348229,1129351469,1129339870)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129341330 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348230,1129351470,1129339871,1129341331)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339872 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341332)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129341332 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348232,1129351472,1129339873,1129339731,1129348233,1129348091,1129339874,1129339732,1129348234,1129348092)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339872 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339875)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339733  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348235)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348235 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129348093,1129339876,1129339734,1129348236,1129348094,1129339877,1129339735,1129348237,1129348095,1129339878)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339736  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348238)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348238 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348096,1129339879,1129339737,1129348239,1129348097,1129339880,1129341340,1129348240,1129351480,1129339881)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341341 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348241,1129351481)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339882 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341342,1129348242)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129351482 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129339883,1129341343)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341315  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348243,1129348244,1129341345,1129341347,1129348247)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129348243 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129351483,1129339884,1129341344)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129348244 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129351484,1129339885)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341345 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348245,1129341346,1129339887)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348245 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129351485,1129339886)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129341346 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129348246,1129351486)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348247  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129351487,1129351488,1129341217)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129351487 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339888)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339888 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341348,1129348248)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129351488 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129341293,1129339822,1129339711,1129341513,1129339889,1129351489,1129351490,1129351491,1129348252,1129351495,1129339738)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339711 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341514,1129341294)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341294 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in  (1129339823,1129339712)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339889 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in  (1129341349,1129348249)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129351489 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in  (1129339890,1129341350,1129348250)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129351490 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339891,1129341351,1129348251)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129351491 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in  (1129339892,1129341352)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129348252 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129351492,1129348254)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129351492 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in  (1129339893,1129341353,1129348253,1129351493,1129339894,1129341354)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348254 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in  (1129351494,1129341215,1129341355,1129351355)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129351495 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341216,1129341356,1129351356)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129341217 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341295,1129341357,1129339824,1129351357,1129339825,1129339739,1129339714,1129341218,1129339826,1129341358,1129339715,1129351358
,1129339716,1129339760,1129341509,1129339741,1129341299,1129341220,1129341508,1129339742,1129341300,1129341221,1129339762,1129339743,1129341301,1129339830,1129341222)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339824 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339713,1129341512,1129341296)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339714 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341511,1129341297)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339715 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341510,1129341298,1129339827)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129351358 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129339740,1129341219,1129341359)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341299 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339828,1129339717)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341220 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341360,1129339761)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341300 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339829,1129339718)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341221 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341361,1129339762)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348247 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341362,1129341235,1129339655,1129341400,1129339783,1129339663)

UPDATE PSS set  PSS. ParentSegmentStatusId=1129341362 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339763,1129341363,1129351509)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339763 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339719,1129339744,1129341223)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339744 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341506)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341363 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129339764,1129341364,1129339765,1129339746,1129341366,1129341228,1129341369,1129339770)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339764 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339745,1129341224)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339746 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341225,1129341365,1129339766,1129339747,1129341226)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341366 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339767,1129351506,1129341227,1129341367,1129339768,1129351507)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341228 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341368,1129339769,1129351508,1129341229)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129351509 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129341230,1129351510,1129341231,1129341371,1129339772,1129339775)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341230 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129341370,1129339771)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339772 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129351511,1129341232,1129341407,1129339650,1129339773,1129341233,1129341406,1129339651,1129339774,1129341234,1129341405,1129339652)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341235 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341404,1129339777)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341404 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129339653,1129339776,1129341236,1129341403,1129339654)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339777  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341237,1129341402)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339655 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339778,1129341239)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339778 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341238,1129341401,1129339656,1129339779)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341400 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339657,1129339781,1129341242,1129341397,1129339660)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339657 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129339780,1129341240,1129341399,1129339658)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339781 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341241,1129341398,1129339659,1129339782)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339783 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341243,1129339785,1129341245,1129341394)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341243 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341396,1129339661,1129339784,1129341244,1129341395,1129339662)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339663 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339748)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339748 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129341246,1129348108,1129339664,1129339749,1129341247,1129348109)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348247  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339665,1129341248,1129339797,1129348157,1129339798,1129339676,1129339677,1129341267,1129348204,1129339810,1129339814)

UPDATE PSS set  PSS. ParentSegmentStatusId=1129339665 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129339750)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341248 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348110,1129341249,1129339668,1129348113,1129341252,1129341255,1129339796)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129348110 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339666,1129339751)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341249 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348111,1129339667,1129339752,1129341250,1129348112)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339668 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339753,1129341251)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129348113 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339669,1129339754)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341252 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348114,1129341253,1129339794)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129348114 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339670,1129339755)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341253 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348153,1129339671)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339794 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341254,1129348154,1129339672,1129339795)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341255 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348155,1129339673)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339796 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341256,1129348156,1129339674)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339797 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129341257)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348157 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339675)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339798 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341258,1129348158)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339676 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129339799)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339799 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341259,1129348159)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339677 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341302,1129339800,1129341260,1129339801,1129339679,1129339802,1129339803,1129341303,1129339844,1129348164,1129339682,1129339807)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341260 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348160,1129339678)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339801 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129341261,1129348161)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339802 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129341262,1129348162,1129339680)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339803 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129341263,1129348163,1129339681,1129339804,1129341264,1129339831)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339831 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339720,1129339843)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341303 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348203,1129339721)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339844 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341304)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339682 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339805,1129339683,1129339806,1129339684)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339805 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129341265,1129348165)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339806 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129341266,1129348166)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341267 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348167,1129341268,1129339809,1129339687)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348167 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339685,1129339808)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341268 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348168,1129339686)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339809 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341269,1129348169)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129348204 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339722)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339722 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339845,1129341305,1129348205,1129339723)

UPDATE PSS set  PSS. ParentSegmentStatusId=1129339810 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129341270,1129348170,1129348171,1129339689)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129348170 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339688,1129339811,1129341271)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339689 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339812,1129341273)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339812 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341272,1129348172,1129339690,1129339813)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341273 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348173,1129339691)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129339814 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341274,1129348116,1129339695,1129339758)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341274 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348174,1129339692,1129339815,1129341275,1129348115,1129339693,1129339756,1129341276)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129348116 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339694,1129339757,1129341277,1129348117)


UPDATE PSS set  PSS. ParentSegmentStatusId=1129348247  from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341278,1129348195,1129339703)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341278 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348118,1129339698,1129339836,1129341282)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129348118 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339696,1129339759,1129341279,1129348119,1129339697,1129339838,1129341280,1129348197)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339698 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339837,1129341281,1129348196,1129339699)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129348195 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129339700,1129341285,1129348192)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339700 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in(1129339835,1129341283,1129348194,1129339702,1129339833,1129339846)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129348194 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339701,1129339834,1129341284,1129348193)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129339703 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129339832,1129341286,1129341521)
UPDATE PSS set  PSS.ParentSegmentStatusId=1129341286 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129348191,1129339704)
UPDATE PSS set  PSS. ParentSegmentStatusId=1129341306 from projectsegmentStatus as PSS where PSS.projectid=16687 and PSS.sectionId=19201596 and SegmentStatusId in (1129341287)




