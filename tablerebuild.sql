
USE ODS

SELECT
	dbschemas.[name] [schema], 
	dbtables.[name] [table], 
	dbindexes.[name] [index],
	indexstats.alloc_unit_type_desc,
	indexstats.avg_fragmentation_in_percent,
	indexstats.page_count
INTO #before
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID()
AND dbtables.[name] LIKE ('%tableName%')
ORDER BY indexstats.avg_fragmentation_in_percent DESC

select * 
from #before
where Tabela like '%tableName%'
order by 2

ALTER TABLE tableName REBUILD

-- "After":
SELECT
	dbschemas.[name] [schema], 
	dbtables.[name] [table], 
	dbindexes.[name] [index],
	indexstats.alloc_unit_type_desc,
	indexstats.avg_fragmentation_in_percent,
	indexstats.page_count
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID()
AND dbtables.[name] LIKE ('%tableName%')
ORDER BY 2

-- Compare them!

-- If necessary:
/*
ALTER TABLE [dbo].[tableName]
DROP COLUMN table_sk_column

ALTER TABLE [dbo].[tableName]
ADD table_sk_column BIGINT IDENTITY PRIMARY KEY NOT NULL
*/