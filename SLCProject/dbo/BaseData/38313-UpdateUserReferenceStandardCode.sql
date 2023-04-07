/*
Customer Support 38313: SLC - User-added RS being replaced by BSD RS - 67273
Server :5

------for reference-----------------------------------
this customer have 4 user reference stanadard.
i update RefStdCode because before refstdcode is not unique.
now i update unique RefStdCode which are not present in slcmaster..ReferenceStandard table

select * from  ReferenceStandard where CustomerId=2439
select * from ReferenceStandardEdition where CustomerId=2439
*/


update RS set RS.RefStdCode=3003673 from ReferenceStandard RS with (nolock) where  RS.RefStdId=276 and RS.CustomerId=2439
update RS set RS.RefStdCode=3003674 from ReferenceStandard RS with (nolock) where  RS.RefStdId=277 and RS.CustomerId=2439
update RS set RS.RefStdCode=3003675 from ReferenceStandard RS with (nolock) where  RS.RefStdId=278 and RS.CustomerId=2439
update RS set RS.RefStdCode=3003676 from ReferenceStandard RS with (nolock) where  RS.RefStdId=279 and RS.CustomerId=2439