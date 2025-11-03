
SELECT COUNT(*) FROM WaP;

--vector dimension cannot be larger than 2000 dimensions for diskann index.
--CREATE INDEX ON WaP USING diskann (embedding vector_cosine_ops);
--CREATE INDEX ON WaP USING diskann (embedding1536 vector_cosine_ops);

/* Update the embeddings index with 1536 dimension embeddings
ALTER TABLE WaP ADD COLUMN IF NOT EXISTS embedding1536 vector(1536);

DECLARE
  _batch_size integer := 200; -- tune as appropriate
BEGIN
  LOOP
    -- Lock a batch of unprocessed rows
    WITH to_embed AS (
      SELECT id, COALESCE(section, '') AS section
      FROM WaP
      WHERE embedding1536 IS NULL
      FOR UPDATE SKIP LOCKED
      LIMIT _batch_size
    )
    UPDATE WaP w
       SET embedding1536 = azure_openai.create_embeddings('text-embedding-3-small', t.section)
      FROM to_embed t
     WHERE w.id = t.id;

    -- Exit when no more rows were updated in this iteration
    IF NOT FOUND THEN
      EXIT;
    END IF;
  END LOOP;
END
$$ LANGUAGE plpgsql;
*/

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT ID, section
FROM WaP
WHERE embedding1536 <=> azure_openai.create_embeddings('text-embedding-3-small', 'Who will get married?')::vector < 0.2
ORDER BY embedding1536 <=> azure_openai.create_embeddings('text-embedding-3-small', 'Who will get married?')::vector
LIMIT 1;

--Limit  (cost=359.20..359.77 rows=1 width=278) (actual time=126.527..126.528 rows=0 loops=1)
--  ->  Index Scan using wap_embedding1536_idx on public.wap  (cost=359.20..2587.57 rows=3924 width=278) (actual time=126.525..126.526 rows=0 loops=1)

SELECT '';

CREATE OR REPLACE FUNCTION top_sections_for_q_json(qtext text, numrows int)
RETURNS jsonb LANGUAGE sql AS
$$
WITH emb AS (
  SELECT azure_openai.create_embeddings('text-embedding-3-small', qtext)::vector AS v
)
SELECT jsonb_agg(section)
FROM (
  SELECT w.section
  FROM WaP w, emb
  ORDER BY w.embedding1536 <=> emb.v
  LIMIT numrows
) t;
$$;


SELECT azure_ai.generate(
         'Question: Who gets married - list of names?
Context: ' || top_sections_for_q_json('Who gets married?', 40)::text, 'gpt-4.1-mini'
       ) AS res;


/*
The people who get married are: Berg and Véra; Natásha and her husband (name not specified); Prince Andrew (implied to marry); and Hélène is considering marriage with one of two men (a prince and a magnate), but it is not explicitly stated whom she marries.
*/