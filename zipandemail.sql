-- Step 1: Export data to CSV using bcp
DECLARE @Path NVARCHAR(255) = 'REPLACEWITHPATH';  -- I use %TEMP%

DECLARE @csvPath NVARCHAR(255) = @Path+'file.csv';
DECLARE @zipPath NVARCHAR(255) = @Path+'file.zip';

DECLARE @cmd NVARCHAR(1000) = 'bcp "SELECT * from YOURVIEW" queryout "' + @csvPath +'" -c -t, -T -S localhost';


EXEC xp_cmdshell @cmd;

-- Step 2: Zip and password-protect the file using PowerShell
DECLARE @psScript NVARCHAR(1000) = 'powershell.exe -Command "& ''C:\Program Files\7-Zip\7z.exe'' a -tzip '''+@zipPath+''' '''+@csvPath+''' -ptest123"';
EXEC xp_cmdshell @psScript;

-- Step 3: Send email with the zip file attached
EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'REPLACENAME',
    @recipients = 'REPLACERECIPIENTS',
    @subject = 'REPLACE',
    @body = 'REPLACE',
    @file_attachments = @zipPath;
