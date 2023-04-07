
--Database:[SLCProject_SqlSlcOp004]
--76313-SLC: Unable To Locate Imported Document
--Records affected: As per data on production DB
--Project Name: Ramsey Water Treatment Plant
--Customer ID: 62061
--Admin ID: 2853

--Query
	
	UPDATE ProjectSection SET IsLastLevel=0 WHERE ProjectId=26959 AND SourceTag LIKE '%0000' AND IsLastLevel=1
