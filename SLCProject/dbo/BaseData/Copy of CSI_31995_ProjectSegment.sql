--Customer Support 31995: Jumbled words in SLC
--execute Script for all server

--USE SLCProject_SqlSlcOp001
--go
--1
--update record 2

--USE SLCProject_SqlSlcOp002
--go
--1
--update record 259
--2 
--update record 26
--3
--update record 4


--USE SLCProject_SqlSlcOp003
--go
--1
--update record 259
--2
--update record 40


--USE SLCProject_SqlSlcOp004
--go
--1
--update record 32
--2
--update record 4

--1
UPDATE PS SET PS.SegmentDescription=REPLACE(PS.SegmentDescription,'\chshdng0\chcfpat0\rtlch\af1\afs20\alang0\ab\ltrch\f1\fs20\lang0\langnp0\langfe0\langfenp0','') from ProjectSegment PS WITH(NOLOCK) where PS.SegmentDescription LIKE '\chshdng0\chcfpat0\rtlch\af1\afs20\alang0\ab\ltrch\f1\fs20\lang0\langnp0\langfe0\langfenp0%'
--2
UPDATE PS SET PS.SegmentDescription=REPLACE(PS.SegmentDescription,'\chshdng0\chcfpat0\rtlch\af1\afs20\alang0\acf6\ltrch\f1\fs20\lang0\langnp0\langfe0\langfenp0','') from ProjectSegment PS WITH(NOLOCK) where PS.SegmentDescription LIKE '\chshdng0\chcfpat0\rtlch\af1\afs20\alang0\acf6\ltrch\f1\fs20\lang0\langnp0\langfe0\langfenp0%'
--3
UPDATE PS SET PS.SegmentDescription=REPLACE(PS.SegmentDescription,'\chshdng0\chcfpat0\rtlch\af1\afs20\alang0\ab\acf1\ltrch\f1\fs20\lang0\langnp0\langfe0\langfenp0','') from ProjectSegment PS WITH(NOLOCK) where PS.SegmentDescription LIKE '\chshdng0\chcfpat0\rtlch\af1\afs20\alang0\ab\acf1\ltrch\f1\fs20\lang0\langnp0\langfe0\langfenp0%'

