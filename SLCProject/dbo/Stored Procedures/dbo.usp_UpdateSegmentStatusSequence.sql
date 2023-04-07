CREATE PROCEDURE [dbo].[usp_UpdateSegmentStatusSequence]    
@statusIds NVARCHAR (MAX) NULL    
AS    
BEGIN
    
	DECLARE @PstatusIds NVARCHAR (max) = @statusIds;

	WITH cte
	AS
	(SELECT
			[Key] AS [Sequence]
		   ,[Value] AS SegmentStatusId
		FROM OPENJSON(@PstatusIds))
	UPDATE PSS
	SET PSS.SequenceNumber = cte.Sequence
	FROM cte WITH (NOLOCK)
	INNER JOIN ProjectSegmentStatus AS PSS WITH (NOLOCK)
		ON cte.SegmentStatusId = PSS.SegmentStatusId;

END

GO
