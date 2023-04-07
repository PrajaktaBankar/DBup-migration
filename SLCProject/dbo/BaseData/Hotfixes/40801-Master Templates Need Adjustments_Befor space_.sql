/*
 server name : All Server
 Customer Support 40801: SLC Master Templates Need Adjustments So Output Matches SLE(Change space before settings)

 ---For references-----

*/

--For CSI Templete----

UPDATE S SET S.TopDistance=6221 from Style S WITH (NOLOCK)
WHERE S.StyleId IN(1,2,3,4)

UPDATE S SET S.TopDistance=1037 from Style S WITH (NOLOCK)
WHERE S.StyleId IN(5,6,7,8,9)
---------------------------

--For Block Templete----

UPDATE S SET S.TopDistance=6221 from Style S WITH (NOLOCK)
WHERE S.StyleId IN(19,20,21,22)

UPDATE S SET S.TopDistance=1037 from Style S WITH (NOLOCK)
WHERE S.StyleId IN(23,24,25,26,27)
--------------------------

--For AIA Templete----

UPDATE S SET S.TopDistance=37325 from Style S WITH (NOLOCK)
WHERE S.StyleId IN(37)

UPDATE S SET S.TopDistance=13479 from Style S WITH (NOLOCK)
WHERE S.StyleId IN(40)

UPDATE S SET S.TopDistance=1037 from Style S WITH (NOLOCK)
WHERE S.StyleId IN(41,42,43,44,45)

---------------------------

--For Military Format----

UPDATE S SET S.TopDistance=6221 from Style S WITH (NOLOCK)
WHERE S.StyleId IN(10,11,12,13)

UPDATE S SET S.TopDistance=1037 from Style S WITH (NOLOCK)
WHERE S.StyleId IN(14,15,16,17,18)


-------------

--For Sequential Numbering Format----

UPDATE S SET S.TopDistance=6221 from Style S WITH (NOLOCK)
WHERE S.StyleId IN(28,29,30,31)

UPDATE S SET S.TopDistance=1037 FROM Style S WITH (NOLOCK)
WHERE S.StyleId IN(32,33,34,35,36)





 




 