--View the plan demo

GO
SET SHOWPLAN_XML ON
GO

--SELECT TOP 10 * FROM Alice2

SELECT COUNT(*) FROM AliceVectors

DECLARE @inputText Varchar(500) = 'Is the cat nice?'
DECLARE @NumResults INT = 4

SET NOCOUNT ON

declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max) = json_object('input': @inputText);
DECLARE @headers nvarchar(150) = (SELECT TOP 1 '{"api-key":"' + skey + '"}' FROM OpenAIKeySSUS)

exec @retval = sp_invoke_external_rest_endpoint
    @url = 'https://southcentralOpenAIral.openai.azure.com/openai/deployments/textembeddingada002v2/embeddings?api-version=2023-03-15-preview',
    @method = 'POST',
    @headers = @headers,
    @payload = @payload,
    @response = @response output;

drop table if exists #t;
select 
	cast([key] as int) as [vector_value_id],
	cast([value] as float) as [AliceVectors]
into    
	#t
from 
	openjson(@response, '$.result.data[0].embedding')

select	top(@NumResults)
		v2.PID, 
		sum(v1.[AliceVectors] * v2.[AliceVectors]) / 
			(
				sqrt(sum(v1.[AliceVectors] * v1.[AliceVectors])) 
				* 
				sqrt(sum(v2.[AliceVectors] * v2.[AliceVectors]))
			) as cosine_distance
FROM		#t v1
			INNER JOIN [dbo].[AliceVectors] v2 on v1.vector_value_id = v2.vector_value_id
GROUP BY	v2.PID
ORDER BY	cosine_distance desc;

GO
SET SHOWPLAN_XML OFF
GO