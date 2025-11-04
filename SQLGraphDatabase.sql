/*
https://github.com/Azure-Samples/sql-ai-embeddings-workshop/blob/main/docs/7-graphrag-and-azure-sql.md
*/

-- DROP TABLE Tires
-- DROP TABLE Accessory
-- DROP TABLE BikeTires
-- DROP TABLE BikeFrame
-- DROP TABLE BikeAccessory
-- GO


CREATE TABLE BikeTires
(
    ID INTEGER not null identity primary key,
    product_id int,
    category_id int,
    embeddings VECTOR(1536)
) AS NODE;

CREATE TABLE BikeFrame
(
    ID INTEGER not null identity primary key,
    product_id int,
    category_id int,
    embeddings VECTOR(1536)
) AS NODE;

CREATE TABLE BikeAccessory
(
    ID INTEGER not null identity primary key,
    product_id int,
    category_id int,
    embeddings VECTOR(1536)
) AS NODE;

CREATE TABLE Tires AS EDGE;
CREATE TABLE Accessory AS EDGE;

GO

SET NOCOUNT ON
DROP TABLE IF EXISTS #MYTEMP 
DECLARE @ProductID int
DECLARE @CategoryID int
declare @text nvarchar(max);
declare @vector vector(1536);
SELECT * INTO #MYTEMP FROM [SalesLT].Product where ProductCategoryID IN (16,18,20);
SELECT @ProductID = ProductID FROM #MYTEMP
SELECT TOP(1) @ProductID = ProductID FROM #MYTEMP
WHILE @@ROWCOUNT <> 0
BEGIN
    SELECT TOP(1) @CategoryID = ProductCategoryID FROM #MYTEMP;
    set @text = (SELECT p.Name + ' '+ ISNULL(p.Color,'No Color') + ' '+  c.Name + ' '+  m.Name + ' '+  ISNULL(d.Description,'')
                    FROM 
                    [SalesLT].[ProductCategory] c,
                    [SalesLT].[ProductModel] m,
                    [SalesLT].[Product] p
                    LEFT OUTER JOIN
                    [SalesLT].[vProductAndDescription] d
                    on p.ProductID = d.ProductID
                    and d.Culture = 'en'
                    where p.ProductCategoryID = c.ProductCategoryID
                    and p.ProductModelID = m.ProductModelID
                    and p.ProductID = @ProductID);
    exec dbo.create_embeddings @text, @vector output;
    insert into BikeFrame (product_id, category_id, embeddings) values (@ProductID,@CategoryID, @vector);
    DELETE FROM #MYTEMP WHERE ProductID = @ProductID
    SELECT TOP(1) @ProductID = ProductID FROM #MYTEMP
END

GO

SET NOCOUNT ON
DROP TABLE IF EXISTS #MYTEMP 
DECLARE @ProductID int
DECLARE @CategoryID int
declare @text nvarchar(max);
declare @vector vector(1536);
SELECT * INTO #MYTEMP FROM [SalesLT].Product where ProductCategoryID IN (21,41);
SELECT @ProductID = ProductID FROM #MYTEMP
SELECT TOP(1) @ProductID = ProductID FROM #MYTEMP
WHILE @@ROWCOUNT <> 0
BEGIN
    SELECT TOP(1) @CategoryID = ProductCategoryID FROM #MYTEMP;
    set @text = (SELECT p.Name + ' '+ ISNULL(p.Color,'No Color') + ' '+  c.Name + ' '+  m.Name + ' '+  ISNULL(d.Description,'')
                    FROM 
                    [SalesLT].[ProductCategory] c,
                    [SalesLT].[ProductModel] m,
                    [SalesLT].[Product] p
                    LEFT OUTER JOIN
                    [SalesLT].[vProductAndDescription] d
                    on p.ProductID = d.ProductID
                    and d.Culture = 'en'
                    where p.ProductCategoryID = c.ProductCategoryID
                    and p.ProductModelID = m.ProductModelID
                    and p.ProductID = @ProductID);
    exec dbo.create_embeddings @text, @vector output;
    insert into BikeTires (product_id, category_id, embeddings) values (@ProductID,@CategoryID, @vector);
    DELETE FROM #MYTEMP WHERE ProductID = @ProductID
    SELECT TOP(1) @ProductID = ProductID FROM #MYTEMP
END

GO

SET NOCOUNT ON
DROP TABLE IF EXISTS #MYTEMP 
DECLARE @ProductID int
DECLARE @CategoryID int
declare @text nvarchar(max);
declare @vector vector(1536);
SELECT * INTO #MYTEMP FROM [SalesLT].Product where ProductCategoryID IN (32,19,17,8);
SELECT @ProductID = ProductID FROM #MYTEMP
SELECT TOP(1) @ProductID = ProductID FROM #MYTEMP
WHILE @@ROWCOUNT <> 0
BEGIN
    SELECT TOP(1) @CategoryID = ProductCategoryID FROM #MYTEMP;
    set @text = (SELECT p.Name + ' '+ ISNULL(p.Color,'No Color') + ' '+  c.Name + ' '+  m.Name + ' '+  ISNULL(d.Description,'')
                    FROM 
                    [SalesLT].[ProductCategory] c,
                    [SalesLT].[ProductModel] m,
                    [SalesLT].[Product] p
                    LEFT OUTER JOIN
                    [SalesLT].[vProductAndDescription] d
                    on p.ProductID = d.ProductID
                    and d.Culture = 'en'
                    where p.ProductCategoryID = c.ProductCategoryID
                    and p.ProductModelID = m.ProductModelID
                    and p.ProductID = @ProductID);
    exec dbo.create_embeddings @text, @vector output;
    insert into BikeAccessory (product_id, category_id, embeddings) values (@ProductID,@CategoryID, @vector);
    DELETE FROM #MYTEMP WHERE ProductID = @ProductID
    SELECT TOP(1) @ProductID = ProductID FROM #MYTEMP
END

GO

with cte (frame_node, tire_node) as (
    select distinct B.$node_id, 
                    T.$node_id 
    from BikeFrame B, 
        BikeTires T
    where T.product_id in (815, 816, 817, 823, 824, 825, 928, 929, 930, 921, 873)
    and B.category_id = 16)
insert into Tires 
select frame_node,tire_node from cte;

with cte (frame_node, tire_node) as (
    select distinct B.$node_id, 
                    T.$node_id 
    from BikeFrame B, 
        BikeTires T
    where T.product_id in (818, 826, 931, 932, 933, 922, 873)
    and B.category_id = 18)
insert into Tires 
select frame_node,tire_node from cte;

with cte (frame_node, tire_node) as (
    select distinct B.$node_id, 
                    T.$node_id 
    from BikeFrame B, 
        BikeTires T
    where T.product_id in (829, 821, 934, 923, 873)
    and B.category_id = 20)
insert into Tires
select frame_node,tire_node from cte;

GO


with cte (frame_node, accessory_node) as (
    select distinct B.$node_id, 
                    T.$node_id 
    from BikeFrame B, 
        BikeAccessory T
    where T.product_id in (908, 909, 910, 871, 935, 936, 937, 808, 809, 810)
    and B.category_id = 16)
insert into Accessory 
select frame_node, accessory_node from cte;

with cte (frame_node, accessory_node) as (
    select distinct B.$node_id, 
                    T.$node_id 
    from BikeFrame B, 
        BikeAccessory T
    where T.product_id in (911, 912, 913, 872, 938, 939, 940, 811, 812, 813)
    and B.category_id = 18)
insert into Accessory 
select frame_node, accessory_node from cte;

with cte (frame_node, accessory_node) as (
    select distinct B.$node_id, 
                    T.$node_id 
    from BikeFrame B, 
        BikeAccessory T
    where T.product_id in (914, 915, 916, 870, 941, 946, 947)
    and B.category_id = 20)
insert into Accessory
select frame_node, accessory_node from cte;

GO

declare @search_text nvarchar(max) = 'I am looking for a mountain bike configuration for the trail riding';
declare @search_vector vector(1536);
DROP TABLE #MYTEMPGRAPH;
exec dbo.create_embeddings @search_text, @search_vector output;
declare @frame_id INT = (SELECT TOP(1) p.product_id
    FROM BikeFrame p
    ORDER BY vector_distance('cosine', @search_vector, p.embeddings) );

-- add the frame details
SELECT 
        p.Name as product_name,
        ISNULL(p.Color,'No Color') as product_color,
        c.Name as category_name,
        m.Name as model_name,
        d.Description as product_description,
        p.ListPrice as list_price,
        p.weight as product_weight,
        vector_distance('cosine', @search_vector, p.embeddings) AS distance
        INTO #MYTEMPGRAPH
FROM
    [SalesLT].[ProductCategory] c,
    [SalesLT].[ProductModel] m,
    [SalesLT].[Product] p
    LEFT OUTER JOIN
    [SalesLT].[vProductAndDescription] d
    on p.ProductID = d.ProductID
    and d.Culture = 'en'  
where p.ProductCategoryID = c.ProductCategoryID
and p.ProductModelID = m.ProductModelID
and p.ProductID = @frame_id;

-- get top X tires
with tireCTE (product_id) as (select top(4) BikeTires.product_id
from BikeFrame, Tires, BikeTires
where MATCH(BikeFrame-(Tires)->BikeTires)
and BikeFrame.product_id = @frame_id
ORDER BY vector_distance('cosine', @search_vector, BikeTires.embeddings))
INSERT INTO #MYTEMPGRAPH
SELECT 
        p.Name as product_name,
        ISNULL(p.Color,'No Color') as product_color,
        c.Name as category_name,
        m.Name as model_name,
        d.Description as product_description,
        p.ListPrice as list_price,
        p.weight as product_weight,
        vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM
    [SalesLT].[ProductCategory] c,
    [SalesLT].[ProductModel] m,
    tireCTE tireCTE,
    [SalesLT].[Product] p
    LEFT OUTER JOIN
    [SalesLT].[vProductAndDescription] d
    on p.ProductID = d.ProductID
    and d.Culture = 'en'    
where p.ProductCategoryID = c.ProductCategoryID
and p.ProductModelID = m.ProductModelID
and tireCTE.product_id = p.ProductID;


-- get top X accessories

with accCTE (product_id) as (select top(10) BikeAccessory.product_id
from BikeFrame, Accessory, BikeAccessory
where MATCH(BikeFrame-(Accessory)->BikeAccessory)
and BikeFrame.product_id = @frame_id
ORDER BY vector_distance('cosine', @search_vector, BikeAccessory.embeddings))
INSERT INTO #MYTEMPGRAPH
SELECT 
        p.Name as product_name,
        ISNULL(p.Color,'No Color') as product_color,
        c.Name as category_name,
        m.Name as model_name,
        d.Description as product_description,
        p.ListPrice as list_price,
        p.weight as product_weight,
        vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM
    [SalesLT].[ProductCategory] c,
    [SalesLT].[ProductModel] m,
    accCTE accCTE,
    [SalesLT].[Product] p
    LEFT OUTER JOIN
    [SalesLT].[vProductAndDescription] d
    on p.ProductID = d.ProductID
    and d.Culture = 'en'    
where p.ProductCategoryID = c.ProductCategoryID
and p.ProductModelID = m.ProductModelID
and accCTE.product_id = p.ProductID;

WITH RankedItems AS (
    select * ,
        ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY distance) AS rn
    FROM 
        #MYTEMPGRAPH
)
SELECT 
    *
FROM 
    RankedItems
WHERE 
    rn <= 4
order by category_name, distance;

GO

create or alter procedure [dbo].[find_products]
@text nvarchar(max),
@top int = 15,
@min_similarity decimal(19,16) = 0.70
as
if (@text is null) return;
declare @retval int, @search_vector vector(1536);
DROP TABLE IF EXISTS #MYTEMPPROC;
exec @retval = dbo.create_embeddings @text, @search_vector output;
if (@retval != 0) return;
declare @frame_id INT = (SELECT TOP(1) p.product_id
    FROM BikeFrame p
    ORDER BY vector_distance('cosine', @search_vector, p.embeddings));
SELECT 
        p.Name as product_name,
        ISNULL(p.Color,'No Color') as product_color,
        c.Name as category_name,
        m.Name as model_name,
        d.Description as product_description,
        p.ListPrice as list_price,
        p.weight as product_weight,
        vector_distance('cosine', @search_vector, p.embeddings) AS distance
        INTO #MYTEMPPROC
FROM
    [SalesLT].[ProductCategory] c,
    [SalesLT].[ProductModel] m,
    [SalesLT].[Product] p
    LEFT OUTER JOIN
    [SalesLT].[vProductAndDescription] d
    on p.ProductID = d.ProductID
    and d.Culture = 'en'   
where p.ProductCategoryID = c.ProductCategoryID
and p.ProductModelID = m.ProductModelID
and p.ProductID = @frame_id;

-- get top X tires
with tireCTE (product_id) as (select top(4) BikeTires.product_id
from BikeFrame, Tires, BikeTires
where MATCH(BikeFrame-(Tires)->BikeTires)
and BikeFrame.product_id = @frame_id
ORDER BY vector_distance('cosine', @search_vector, BikeTires.embeddings))
INSERT INTO #MYTEMPPROC
SELECT 
        p.Name as product_name,
        ISNULL(p.Color,'No Color') as product_color,
        c.Name as category_name,
        m.Name as model_name,
        d.Description as product_description,
        p.ListPrice as list_price,
        p.weight as product_weight,
        vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM
    [SalesLT].[ProductCategory] c,
    [SalesLT].[ProductModel] m,
    tireCTE tireCTE,
    [SalesLT].[Product] p
    LEFT OUTER JOIN
    [SalesLT].[vProductAndDescription] d
    on p.ProductID = d.ProductID
    and d.Culture = 'en'    
where p.ProductCategoryID = c.ProductCategoryID
and p.ProductModelID = m.ProductModelID
and tireCTE.product_id = p.ProductID;


-- get top X accessories

with accCTE (product_id) as (select top(10) BikeAccessory.product_id
from BikeFrame, Accessory, BikeAccessory
where MATCH(BikeFrame-(Accessory)->BikeAccessory)
and BikeFrame.product_id = @frame_id
ORDER BY vector_distance('cosine', @search_vector, BikeAccessory.embeddings))
INSERT INTO #MYTEMPPROC
SELECT 
        p.Name as product_name,
        ISNULL(p.Color,'No Color') as product_color,
        c.Name as category_name,
        m.Name as model_name,
        d.Description as product_description,
        p.ListPrice as list_price,
        p.weight as product_weight,
        vector_distance('cosine', @search_vector, p.embeddings) AS distance
FROM
    [SalesLT].[ProductCategory] c,
    [SalesLT].[ProductModel] m,
    accCTE accCTE,
    [SalesLT].[Product] p
    LEFT OUTER JOIN
    [SalesLT].[vProductAndDescription] d
    on p.ProductID = d.ProductID
    and d.Culture = 'en'    
where p.ProductCategoryID = c.ProductCategoryID
and p.ProductModelID = m.ProductModelID
and accCTE.product_id = p.ProductID;
with vector_results as (

    select * ,
        ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY category_name, distance) AS rn
    FROM 
        #MYTEMPPROC
)
select TOP(@top) product_name, product_color, category_name, model_name, product_description, list_price, product_weight, distance
from vector_results
where (1-distance) > @min_similarity
and rn <= 4
order by    
    distance asc;
GO

GO

find_products 'I am looking for a touring bike configuration for casual riding. I want a yellow bike'

find_products 'I am looking for a mountain bike configuration for trail riding'