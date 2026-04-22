--CREATE EXTENSION vector;

-- Drop the table if it exists
DROP TABLE IF EXISTS tblvector;

CREATE TABLE tblvector(
    id bigserial PRIMARY KEY,
    embedding vector(3)
    );

INSERT INTO tblvector (id, embedding) VALUES (1, '[1,2,3]'), (2, '[1,2,4]'), (3, '[4,5,6]'), (4, '[5,4,6]'), (5, '[3,5,7]'), (6, '[7,8,9]');

/*
    An HNSW index creates a multilayer graph (HNSW index creates a multilayer graph)

    Hierarchical Navigable Small World - Graph-based ANN
    
    High speed and Accuracy/recall

*/
CREATE INDEX ON tblvector USING hnsw (embedding vector_cosine_ops);
--CREATE INDEX ON tblvector USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);


-- The "<->" operator, which is the Euclidean distance
SELECT * FROM tblvector 
ORDER BY embedding <-> '[3,1,2]' 
LIMIT 3;

-- The "<=>" operator, which is the cosine distance
SELECT * FROM tblvector 
ORDER BY embedding <=> '[7,8,9]' 
LIMIT 3;

-- Calculate the cosine distance between all pairs of vectors in the table
SELECT a.embedding, b.embedding, cosine_distance(a.embedding, b.embedding) AS cosine_dist
FROM tblvector AS A
CROSS JOIN tblvector AS B
LIMIT 5;

-- Calculate the Euclidean distance between all pairs of vectors in the table
SELECT a.embedding, b.embedding, l2_distance(a.embedding, b.embedding) AS Euclidean_distance
FROM tblvector AS A
CROSS JOIN tblvector AS B
LIMIT 5;


SELECT vector_dims(embedding) FROM tblvector 
LIMIT 3;


--If the "embedding" column contains word embeddings for a language model, then the average value of these embeddings could be used to represent the entire sentence or document
SELECT AVG(embedding) FROM tblvector;


