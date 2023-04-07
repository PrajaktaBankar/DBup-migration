--Execute on Server 2
--Resolved Customer Support 55035: SLC Choice and RS corruption in section
UPDATE pco SET IsDeleted =0 FROM ProjectSegmentChoice pco WITH (NOLOCK) WHERE pco.SegmentChoiceId IN (43476046,43476047)
UPDATE pco SET IsDeleted =0 FROM projectchoiceoption pco WITH (NOLOCK) WHERE pco.SegmentChoiceId IN (43476046)
UPDATE pco SET IsDeleted =0 FROM selectedchoiceoption pco WITH (NOLOCK) WHERE pco.SegmentChoiceCode IN (284351) and projectid=12059 and sectionid=14915887
UPDATE pco SET segmentid =null FROM projectsegmentstatus pco WITH (NOLOCK) WHERE pco.segmentstatusid IN (717190509) and projectid=12059 and sectionid=14915887
--Script for RS 
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12059,3971,'U',NULL,5516,0,10004773,'2016-05-16 08:29:23.1433333',14671421,429,0)
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12059,3971,'U',NULL,5516,0,10004773,'2016-05-16 08:29:23.1433333',14915887,429,0)
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (8548,3971,'U',NULL,5516,0,10004773,'2016-05-16 08:29:23.1433333',10260023,429,0)
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12699,3971,'U',NULL,5516,0,10004773,'2016-05-16 08:29:23.1433333',15535753,429,0)
-----------------------
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12699,3969,'U',NULL,5513,0,10004771,'2016-05-16 08:29:23.1433333',14671324,429,0)
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12699,3969,'U',NULL,5513,0,10004771,'2016-05-16 08:29:23.1433333',15534614,429,0)
-------------------------------------------
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12911,3970,'U',NULL,5514,0,10004772,'2016-05-16 08:29:23.1433333',15820761,429,0)
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12059,3970,'U',NULL,5514,0,10004772,'2016-05-16 08:29:23.1433333',15820859,429,0)
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (6418,3970,'U',NULL,5514,0,10004772,'2016-05-16 08:29:23.1433333',13150116,429,0)
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12635,3970,'U',NULL,5514,0,10004772,'2016-05-16 08:29:23.1433333',15448250,429,0)
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12646,3970,'U',NULL,5514,0,10004772,'2016-05-16 08:29:23.1433333',15462734,429,0)
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12835,3970,'U',NULL,5514,0,10004772,'2016-05-16 08:29:23.1433333',15715189,429,0)
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12836,3970,'U',NULL,5514,0,10004772,'2016-05-16 08:29:23.1433333',15716616,429,0)
--------------------------
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12059,4016,'U',NULL,5562,0,10004778,'2016-05-16 08:29:23.1433333',14671421,429,0)
---------------------------
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12059,4017,'U',NULL,5563,0,10004779,'2016-05-16 08:29:23.1433333',14671421,429,0)
---------------
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12059,4015,'U',NULL,5561,0,10004777,'2016-05-16 08:29:23.1433333',14917287,429,0)
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12059,4015,'U',NULL,5561,0,10004777,'2016-05-16 08:29:23.1433333',14671421,429,0)
-----------------
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId,RefStdEditionId,
IsObsolete,RefStdCode,PublicationDate,SectionId,CustomerId,IsDeleted)
VALUES (12059,4018,'U',NULL,5566,0,10004780,'2016-05-16 08:29:23.1433333',14671421,429,0)