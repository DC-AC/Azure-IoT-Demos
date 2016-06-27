

CREATE MASTER KEY;

CREATE DATABASE SCOPED CREDENTIAL IoTDemo 
with IDENTITY = '<storage_account_name>', SECRET = '<your_SAS_token_here>'

CREATE EXTERNAL DATA SOURCE IoTDemoBlob
WITH (    TYPE = HADOOP,
    LOCATION = 'wasbs://<container_name>@<storage_account>.blob.core.windows.net/',
    CREDENTIAL = IoTDemo
);


CREATE EXTERNAL FILE FORMAT TextFile
WITH (
    FORMAT_TYPE = DelimitedText,
    FORMAT_OPTIONS (FIELD_TERMINATOR = ',')
);


CREATE TABLE IoTDemo
    (
      deviceid VARCHAR(13) ,
      windspeed NUMERIC(18, 10) ,
      eventprocessedUTCtime DATETIMEOFFSET(7) ,
      partitionid SMALLINT ,
      EventEnqueuedUtcTime DATETIMEOFFSET(7) ,
      IoTHub VARCHAR(6)
    )
	WITH (CLUSTERED COLUMNSTORE INDEX,
		  DISTRIBUTION = ROUND_ROBIN
		 )

GO 

CREATE PROCEDURE load_IoT_Data
AS
    DECLARE @hour VARCHAR(2) = DATEPART(hh,
                                        ( DATEADD(HOUR, -1, GETUTCDATE()) ))
    DECLARE @month VARCHAR(2) = DATEPART(mm,
                                         ( DATEADD(HOUR, -1, GETUTCDATE()) ))
    DECLARE @day VARCHAR(2) = DATEPART(dd, ( DATEADD(HOUR, -1, GETUTCDATE()) ))
    DECLARE @year VARCHAR(4)  = DATEPART(yyyy,
                                         ( DATEADD(HOUR, -1, GETUTCDATE()) ));
    DECLARE @path NVARCHAR(1000)
    DECLARE @sql NVARCHAR(MAX)

BEGIN 

    SET @month = CASE WHEN CONVERT(INT, @month) < 10 THEN '0' + @month
                      ELSE @month
                 END   
			
    SET @path = '/logs/' + @year + '/' + @month + '/' + @day + '/' + @hour;

    SET @sql = 'create external table tempload (deviceid nvarchar(13), windspeed nvarchar(20), eventprocessedUTCtime nvarchar(50), partitionid smallint, EventEnqueuedUtcTime nvarchar(50), IoTHub varchar(6)) WITH ( LOCATION = '''
        + @path
        + ''',DATA_SOURCE=IoTDemoBlob,FILE_FORMAT=TextFile, REJECT_TYPE = VALUE, REJECT_VALUE= 1)';

    EXEC sp_executesql @stmt = @sql;

    INSERT  INTO IoTDemo
            SELECT  deviceid ,
                    windspeed ,
                    eventprocessedUTCtime ,
                    partitionid ,
                    EventEnqueuedUtcTime ,
                    IoTHub
            FROM    tempload;

DROP EXTERNAL TABLE  tempload;

END;

GO


