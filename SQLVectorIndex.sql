--CREATE CLUSTERED INDEX IXID_AliceTrueVectorsIndexed ON dbo.AliceTrueVectorsIndexed (ID)
--CREATE VECTOR INDEX vec_idx ON dbo.AliceTrueVectorsIndexed (Embeddings) WITH (METRIC = 'cosine', TYPE = 'diskann');

SELECT TOP 10 * FROM AliceTrueVectorsIndexed

GO
SET SHOWPLAN_XML ON
GO

SET NOCOUNT ON
DECLARE @inputText Varchar(500) = 'Is the cat nice?'
DECLARE @NumResults INT = 4
declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max) = json_object('input': @inputText);
DECLARE @headers nvarchar(150) = (SELECT TOP 1 '{"api-key":"' + skey + '"}' FROM OpenAIKeySSUS)
DECLARE @query_vector Vector(1536)

exec @retval = sp_invoke_external_rest_endpoint
    @url = 'https://southcentralOpenAIral.openai.azure.com/openai/deployments/textembeddingada002v2/embeddings?api-version=2023-03-15-preview',
    @method = 'POST',
    @headers = @headers,
    @payload = @payload,
    @response = @response output;

SELECT @query_vector = JSON_QUERY(@response, '$.result.data[0].embedding')


-- Run a vector search immediately - the deleted row won't appear
SELECT TOP (4) WITH APPROXIMATE
   *
FROM VECTOR_SEARCH(
    TABLE = AliceTrueVectorsIndexed AS t,
    COLUMN = Embeddings,
    SIMILAR_TO = @query_vector,
    METRIC = 'cosine'
) AS s
ORDER BY s.distance;

GO
SET SHOWPLAN_XML OFF
GO