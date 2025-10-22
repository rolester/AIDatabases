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

	drop table if exists #results;

	select	top(25)
			v2.PID, 
			sum(v1.[AliceVectors] * v2.[AliceVectors]) / 
				(
					sqrt(sum(v1.[AliceVectors] * v1.[AliceVectors])) 
					* 
					sqrt(sum(v2.[AliceVectors] * v2.[AliceVectors]))
				) as cosine_distance
	INTO		#results
	FROM		#t v1
				INNER JOIN [dbo].[AliceVectors] v2 on v1.vector_value_id = v2.vector_value_id
	GROUP BY	v2.PID
	ORDER BY	cosine_distance desc;

	DECLARE @ResultString Varchar(MAX) = ''

	SELECT TOP (@NumResults) @ResultString = [Column 0] + CHAR(10) + @ResultString
	FROM #results AS R
		INNER JOIN Alice2 AS A ON R.PID = A.ID
	--WHERE [Column 0] LIKE '%cat %'
	ORDER BY cosine_distance DESC

	SELECT * FROM STRING_SPLIT(@ResultString, ',')
	
	SET @payload = 
	N'{' +
	N'"messages": [' +
	N'  { "role": "system", "content": "You are a helpful assistant." },' +
	N'  { "role": "user", "content": "Answer this question - ' 
		+ STRING_ESCAPE(@inputText, 'json') 
		+ N' - based on the following: \n' 
		+ STRING_ESCAPE(@ResultString, 'json') 
		+ N'?" }' +
	N'],' +
	N'"temperature": 0.1,' +
	N'"max_tokens": 4000' +
	N'}';

	exec @retval = sp_invoke_external_rest_endpoint
		@url = 'https://southcentralopenairal.cognitiveservices.azure.com/openai/deployments/gpt4om/chat/completions?api-version=2025-01-01-preview',
		@method = 'POST',
		@headers = @headers,
		@payload = @payload,
		@response = @response output;

	SELECT JSON_VALUE(@response, '$.result.choices[0].message.content') AS message_content;

