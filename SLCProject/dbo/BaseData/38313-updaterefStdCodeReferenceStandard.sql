/*
Customer Support 38313: SLC - User-added RS being replaced by BSD RS - 67273
Server :5

------for reference-----------------------------------
this customer have 2 user reference stanadard.
i update RefStdCode because before refstdcode is not unique.
now i update unique RefStdCode which are not present in slcmaster..ReferenceStandard table
i given fix for existing user reference standard.

select * from  ReferenceStandard where CustomerId=2439
select * from ReferenceStandardEdition where CustomerId=2439
*/


update RS set RS.RefStdCode=10000001 from ReferenceStandard RS with (nolock) where  RS.RefStdId=280 and RS.CustomerId=2439
update RS set RS.RefStdCode=10000002 from ReferenceStandard RS with (nolock) where  RS.RefStdId=281 and RS.CustomerId=2439