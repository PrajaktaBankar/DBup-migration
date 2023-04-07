

--Script to fix duplicate RefStdCode for RefStandardId 2234 and 3087

DECLARE @LastRefStdCode AS BIGINT
SELECT TOP 1 @LastRefStdCode = RefStdCode FROM ReferenceStandard WITH (NOLOCK) ORDER BY RefStdCode DESC

UPDATE ReferenceStandard SET RefStdCode = @LastRefStdCode + 1 WHERE CustomerId = 1375 AND RefStdId = 3087

UPDATE A SET A.IsDeleted = 1
FROM ProjectSegmentReferenceStandard A
WHERE A.CustomerId = 1375 AND A.RefStdCode = 10004677 AND A.RefStandardId = 3087 AND ISNULL(A.IsDeleted, 0) = 0

UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 5773 AND SectionId = 6925736 AND SegmentId = 46869778
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 7817 AND SectionId = 9406588 AND SegmentId = 69254410
UPDATE ProjectSegment SET SegmentDescription = 'Bacteria Resistance:  Resistant to bacteria, fungi, and micro-organism activity when tested in accordance with {RS#10004677}' WHERE ProjectId = 7838 AND SectionId = 9434614 AND SegmentId = 69664864
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 8358 AND SectionId = 10030754 AND SegmentId = 75812176
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 8454 AND SectionId = 10136001 AND SegmentId = 76704052
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 8458 AND SectionId = 10140773 AND SegmentId = 76767096
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 8459 AND SectionId = 10142152 AND SegmentId = 76809331
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 10273 AND SectionId = 12376201 AND SegmentId = 97594079
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 10356 AND SectionId = 12485945 AND SegmentId = 98745844
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 10734 AND SectionId = 12960991 AND SegmentId = 102918339
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 11058 AND SectionId = 13390333 AND SegmentId = 106936500
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 11092 AND SectionId = 13436297 AND SegmentId = 107390187
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 11349 AND SectionId = 13769242 AND SegmentId = 109587224
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 12421 AND SectionId = 15151485 AND SegmentId = 123315688
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 12722 AND SectionId = 15566398 AND SegmentId = 128638119
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 12746 AND SectionId = 15595924 AND SegmentId = 128995964
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 12873 AND SectionId = 15767479 AND SegmentId = 130673300
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 12952 AND SectionId = 15876231 AND SegmentId = 131930173
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 13135 AND SectionId = 16122271 AND SegmentId = 133818825
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 13541 AND SectionId = 16666637 AND SegmentId = 137795616
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 13600 AND SectionId = 16747503 AND SegmentId = 138474284
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 14025 AND SectionId = 17331305 AND SegmentId = 143832021
UPDATE ProjectSegment SET SegmentDescription = '{RSTEMP#10004677} ' WHERE ProjectId = 14025 AND SectionId = 17331651 AND SegmentId = 150300229
UPDATE ProjectSegment SET SegmentDescription = 'Resistance to Mold/Mildew:  Passes - No More Than Slight Change ({RS#1236}&nbsp;/&nbsp;E2180{RS#10004677}&nbsp;&nbsp;&nbsp;) ' WHERE ProjectId = 14025 AND SectionId = 17331651 AND SegmentId = 149550862
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 14140 AND SectionId = 17489173 AND SegmentId = 145452816
UPDATE ProjectSegment SET SegmentDescription = '{RS#10004677}, "Standard Test Method for Determining the Activity of Incorporated Antimicrobial Agent(s) In Polymeric or Hydrophobic Materials"' WHERE ProjectId = 14641 AND SectionId = 18175711 AND SegmentId = 152886848


