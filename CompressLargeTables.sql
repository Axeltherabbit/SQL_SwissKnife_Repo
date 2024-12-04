-- Compress any table larger than a GB in the DB

DECLARE @SchemaName NVARCHAR(MAX);
DECLARE @TableName NVARCHAR(MAX);
DECLARE @SQL NVARCHAR(MAX);

-- Loop over each table that is part of the view
DECLARE table_cursor CURSOR FOR
SELECT 
    s.name AS SchemaName, 
    o.name AS ObjectName
FROM sys.dm_db_partition_stats AS ps
INNER JOIN sys.objects AS o
    ON ps.object_id = o.object_id
INNER JOIN sys.schemas AS s
    ON o.schema_id = s.schema_id
GROUP BY s.name, o.name
having SUM(reserved_page_count) * 8.0 / 1024 / 1024 > 1;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Build the dynamic SQL for each table
    SET @SQL = 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] REBUILD PARTITION = ALL
                WITH (DATA_COMPRESSION = PAGE)';
    
    -- Execute the dynamic SQL
    EXEC sp_executesql @SQL;

    -- Fetch next table name
    FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;
END;

-- Clean up the cursor
CLOSE table_cursor;
DEALLOCATE table_cursor;

