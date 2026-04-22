--Returns True if the result is likely true, False otherwise
SELECT session_abstract, azure_ai.is_true('These are abstracts for conference sessions' || session_abstract, 'gpt-4.1-mini') sessionresult
FROM conference_sessions;

--PII Extraction
SELECT azure_ai.extract('Steve was busy meeting with John in Seattle last Friday.', 
                       ARRAY['Person', 'Location', 'Date'],
                       'gpt-4.1-mini') AS extraction_result;



