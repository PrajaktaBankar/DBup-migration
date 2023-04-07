
DROP TABLE if EXISTS #ProjectSegmentImage
DROP TABLE if EXISTS #ProjectNoteImage

--For Editor/Header Footer
select distinct  PSI.ImageId,PSI.CustomerId  INTO #ProjectSegmentImage from ProjectImage PM WITH(NOLOCK)
inner join ProjectSegmentImage PSI WITH(NOLOCK) ON PM.ImageId = PSI.ImageId
where PM.CustomerId is NULL and LuImageSourceTypeId in (1,3)

--For Notes
select distinct PSI.ImageId,PSI.CustomerId INTO #ProjectNoteImage from ProjectImage PM WITH(NOLOCK)
inner join ProjectNoteImage PSI WITH(NOLOCK) ON PM.ImageId = PSI.ImageId
where PM.CustomerId is NULL and LuImageSourceTypeId = 2

--Update for Editor/Header Footer
UPDATE PI SET  PI.CustomerId=PSI.CustomerId
FROM  ProjectImage PI WITH(NOLOCK) INNER JOIN #ProjectSegmentImage PSI WITH(NOLOCK)
ON  PI.ImageId=PSI.ImageId

--Update for Notes
UPDATE PI SET  PI.CustomerId=PNI.CustomerId
FROM  ProjectImage PI WITH(NOLOCK) INNER JOIN #ProjectNoteImage PNI WITH(NOLOCK)
ON  PI.ImageId=PNI.ImageId

