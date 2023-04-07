CREATE PROCEDURE [dbo].[usp_GetMaxCodeCommon]
@operator varchar(50) , 
 @maxSegmentChoiceCode bigint out
as
begin
	DECLARE @Poperator varchar(50) = @operator;

SET NOCOUNT ON;

if(@Poperator ='GetMaxChoiceCode')
Begin
SET @maxSegmentChoiceCode = (SELECT
		MAX(SegmentChoiceCode) AS maxSegmentChoiceCode
	FROM ProjectSegmentChoice(NOLOCK));
End
else if(@Poperator ='GetMaxChoiceOptionCode')
begin
SET @maxSegmentChoiceCode = (SELECT
		MAX(ChoiceOptionCode) AS maxChoiceOptionCode
	FROM ProjectChoiceOption(NOLOCK));
End
else if(@Poperator ='GetMaxSegmentCode')
begin
SET @maxSegmentChoiceCode = (SELECT
		MAX(SegmentCode) AS maxSegmentCode
	FROM ProjectSegment(NOLOCK));
End
else if(@Poperator ='GetMaxSegmentStatusCode')
begin
SET @maxSegmentChoiceCode = (SELECT
		MAX(SegmentStatusCode) AS maxSegmentStatusCode
	FROM ProjectSegmentStatus(NOLOCK));
End

if(@maxSegmentChoiceCode >= 10000000) 
begin
  return @maxSegmentChoiceCode
  end
 else
 begin
  return '10000000';
  end
End;
GO


