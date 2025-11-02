SELECT azure_ai.generate('Tell me which are the top databases for AI on Azure, including open source', 'gpt-4.1-mini');


SELECT session_abstract, azure_ai.generate('make this more exciting' || session_abstract) new_abstract
FROM conference_sessions;

