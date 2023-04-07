--Execute it on All Server

UPDATE f 
SET  f.defaultFooter = REPLACE(f.defaultFooter,'text-decoration-thickness: initial;',''),
f.FirstPageFooter=  REPLACE(f.FirstPageFooter,'text-decoration-thickness: initial;',''),
f.OddpageFooter  =  REPLACE(f.OddpageFooter,'text-decoration-thickness: initial;',''),
f.EvenPageFooter =  REPLACE(f.EvenPageFooter,'text-decoration-thickness: initial;','')
FROM Footer f  WITH(NOLOCK)
WHERE f.defaultFooter like '%text-decoration-thickness%'
OR f.FirstPageFooter like '%text-decoration-thickness%'
OR f.OddpageFooter like '%text-decoration-thickness%'
OR f.EvenPageFooter like '%text-decoration-thickness%'





UPDATE h 
SET  h.DefaultHeader = REPLACE(h.DefaultHeader,'text-decoration-thickness: initial;',''),
h.FirstPageHeader  = REPLACE(h.FirstPageHeader,'text-decoration-thickness: initial;',''),
h.OddpageHeader= REPLACE(h.OddpageHeader,'text-decoration-thickness: initial;',''),
h.EvenPageHeader = REPLACE(h.EvenPageHeader,'text-decoration-thickness: initial;','')
FROM Header h  WITH(NOLOCK)
WHERE
h.DefaultHeader like '%text-decoration-thickness%'
OR h.FirstPageHeader like '%text-decoration-thickness%'
OR h.OddpageHeader	  like '%text-decoration-thickness%'
OR h.EvenPageHeader  like '%text-decoration-thickness%'

