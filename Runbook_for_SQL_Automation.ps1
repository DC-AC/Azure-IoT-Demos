<# 
.SYNOPSIS 
    Outputs the number of records in the specified SQL Server database table. 
 
.DESCRIPTION 
    This runbook demonstrates how to communicate with a SQL Server. Specifically, this runbook 
    outputs the number of records in the specified SQL Server database table. 
 
    In order for this runbook to work, the SQL Server must be accessible from the runbook worker 
    running this runbook. Make sure the SQL Server allows incoming connections from Azure services 
    by selecting 'Allow Windows Azure Services' on the SQL Server configuration page in Azure. 
 
    This runbook also requires an Automation Credential asset be created before the runbook is 
    run, which stores the username and password of an account with access to the SQL Server. 
    That credential should be referenced for the SqlCredential parameter of this runbook. 
 

#> 
 
# Replace the server with the name of the logical server hosting your SQL Data Warehouse and the database with the name of your Data Warehouse. 

 $port = 1433
 $server = "<your_SQL_DW_Server>.database.windows.net"
 $database = "<Your_SQL_DW>" 
      
 
 
 $cred = get-automationPSCredential -Name 'sqldw'
 # Get the username and password from the SQL Credential 
 $SqlUsername = $cred.GetNetworkCredential().UserName 
 $SqlPass = $cred.GetNetworkCredential().Password 
     
 
 # Define the connection to the SQL Database 
 $Conn = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$server,$port;Database=$Database;User ID=$SqlUsername;Password=$SqlPass;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;") 
        
 # Open the SQL connection 
 $Conn.Open() 
 
 # Define the SQL command to run. In this case we are getting the number of rows in the table 
 $Cmd=new-object system.Data.SqlClient.SqlCommand("exec load_IoT_Data", $Conn) 
 $Cmd.CommandTimeout=120 
 
 # Execute the SQL command 
 $Ds=New-Object system.Data.DataSet 
 $Da=New-Object system.Data.SqlClient.SqlDataAdapter($Cmd) 
 [void]$Da.fill($Ds) 
 
 # Output the count 
 $Ds.Tables.Column1 
 
 # Close the SQL connection 
 $Conn.Close() 
  
