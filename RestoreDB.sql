DECLARE @BackupFolder NVARCHAR(255) = N'REPLACEWITHTHEPATH'; -- add a leading slash
DECLARE @FileName NVARCHAR(255);
DECLARE @FilePath NVARCHAR(500);
DECLARE @DatabaseName NVARCHAR(255);
DECLARE @SQL NVARCHAR(MAX);


-- Create a table to store the list of .bak files
IF OBJECT_ID('tempdb..#BackupFiles') IS NOT NULL
    DROP TABLE #BackupFiles;

CREATE TABLE #BackupFiles (
    BackupFile NVARCHAR(255)
);

-- powershell list files. ensure @backupFolder has a leading slash
DECLARE @ListfileCMD NVARCHAR(255) = 'dir /B ' + @BackupFolder + '*.bak' ;

INSERT INTO #BackupFiles (BackupFile)
EXEC xp_cmdshell @ListfileCMD; 

-- Loop through each file and restore it
DECLARE BackupCursor CURSOR FOR
SELECT BackupFile
FROM #BackupFiles
WHERE BackupFile IS NOT NULL;

OPEN BackupCursor;
FETCH NEXT FROM BackupCursor INTO @FileName;

WHILE @@FETCH_STATUS = 0
BEGIN

    SET @DatabaseName = left(@FileName, CHARINDEX('_backup', @FileName) - 1);
    SET @FilePath = @BackupFolder + '\' + @FileName;


    -- Build the RESTORE DATABASE command
    SET @SQL = N'RESTORE DATABASE [' + @DatabaseName + N'] 
        FROM DISK = N''' + @FilePath + N''' 
        WITH REPLACE, 
        MOVE N''' + @DatabaseName + N''' TO N''C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Data\' + @DatabaseName + N'.mdf'', 
        MOVE N''' + @DatabaseName + N'_log'' TO N''C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Data\' + @DatabaseName + N'.ldf'';';

    -- Execute the restore command
    PRINT 'Restoring database: ' + @DatabaseName + ' from backup: ' + @FileName;
    EXEC sp_executesql @SQL;

    FETCH NEXT FROM BackupCursor INTO @FileName;
END

CLOSE BackupCursor;
DEALLOCATE BackupCursor;

-- Clean up
DROP TABLE #BackupFiles;
