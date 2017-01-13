<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2014 v4.1.75
	 Created on:   	1/15/2015 1:36 PM
	 Created by:   	David Bayer
	 Organization: 	
	 Filename:     	PSMySQL.psm1
	-------------------------------------------------------------------------
	 Module Name: PSMySQL
	===========================================================================
#>

<#
	.SYNOPSIS
		Query a MySQL database and return a single value.  If the MySQL query returns more than a single value an error is returned.
	
	.DESCRIPTION
		Query a MySQL database and return a single value.  If the MySQL query returns more than a single value an error is returned.
	
	.PARAMETER ComputerName
		Hostname or IP address of the MySQL server.  Default value is localhost.
	
	.PARAMETER Port
		Network TCP port for the MySQL server.  Default value is 3306.
	
	.PARAMETER DatabaseName
		Name of the database to query.
	
	.PARAMETER Credential
		PowerShell Credential object containing credentials for the Mysql server
	
	.PARAMETER DefaultTimeout
		Timeout value in seconds.  Default value is 30.
	
	.PARAMETER Query
		SQL statement that returns a single value
	
	.EXAMPLE
		PS C:\> Get-MySQLValue -ComputerName 'localhost' -DatabaseName mydb
	
	.NOTES
		Additional information about the function.
#>
function Get-MysqlValue {
	[CmdletBinding()]
	param
	(
		[string]$ComputerName = 'localhost',
		[int]$Port = 3306,
		[string]$DatabaseName,
		[pscredential]$Credential = $(Get-Credential -Message "Enter credentials for Mysql"),
		[int]$DefaultTimeout = 30,
		[Parameter(Mandatory = $true)][string]$Query
	)
	
	$connString = "host=$ComputerName;port=$Port;user=$($Credential.UserName);password=$($Credential.GetNetworkCredential().Password);default command timeout=$DefaultTimeout"
	if ($DatabaseName) { $connString += ";database=$DatabaseName" }
	Write-Debug "Get-MySQLValue: $connString"
	
	$mysqlConn = New-MySQLConnection -ConnectionString "$connString" -LoadMysqlDriver
	$mysqlCommand = New-MysqlCommand -CommandText "$Query"
	$mysqlCommand.Connection = $mysqlConn
	
	try {
		$mysqlConn.Open()
		$value = $mysqlCommand.ExecuteScalar()
	} catch {
		Write-Error $Error[0].ToString
	}
	
	$mysqlConn.Close()
	return $value
}


<#
	.SYNOPSIS
		Insert data into a Mysql table
	
	.DESCRIPTION
		Insert data into a Mysql table.  Note that data values must be specified in the same order as the field names.
	
	.PARAMETER ComputerName
		Mysql server hostname or IP address.  Default value is 'localhost'.
	
	.PARAMETER Port
		TCP port that Mysql is listening on.  Default value is 3306.
	
	.PARAMETER DatabaseName
		The name of the database.  If omitted, the database name must be specified in the INSERT query.
	
	.PARAMETER Credential
		PowerShell Credential object containing Mysql credentials.
	
	.PARAMETER DefaultTimeout
		Default command timeout in seconds for Mysql query execution.  Default value is 30.
	
	.PARAMETER Table
		Name of the MySQL table to insert data into.
	
	.PARAMETER Fields
		One or more field names to insert data into.
	
	.PARAMETER Values
		One or more data values to insert into the specified fields.  Note that the number of values must match the number of fields and be listed in the same order as the field names.
	
	.EXAMPLE
		PS C:\> Add-MysqlData -DatabaseName mydb -Fields field1,field2 -Values value1,value2

#>
function Add-MysqlData {
	[CmdletBinding()]
	param
	(
		[string]$ComputerName = 'localhost',
		[int]$Port = 3306,
		[string]$DatabaseName,
		[pscredential]$Credential = $(Get-Credential -Message "Enter MySQL credentials"),
		[int]$DefaultTimeout = 30,
		[Parameter(Mandatory = $true)][string]$Table,
		[Parameter(Mandatory = $true)][string[]]$Fields,
		[Parameter(Mandatory = $true)][string[]]$Values
	)
	
	for ($i = 0; $i -lt $Fields.Count; $i++) {
		$Fields[$i] = "``$($Fields[$i])``"
	}
	for ($i = 0; $i -lt $Values.Count; $i++) {
		$Values[$i] = "'$($Values[$i])'"
	}
	
	$connString = "host=$ComputerName;port=$Port;user=$($Credential.UserName);password=$($Credential.GetNetworkCredential().Password);default command timeout=$DefaultTimeout"
	if ($DatabaseName) { $connString += ";database=$DatabaseName;" }
	$query = "INSERT INTO $Table ($($Fields -join ',')) VALUES ($($Values -join ','))"
	
	Write-Debug "`n$connString`n`n$query"
	
	$mysqlConn = New-MySQLConnection -ConnectionString "$connString" -LoadMysqlDriver
	$mysqlCommand = New-MysqlCommand -CommandText "$query"
	$mysqlCommand.Connection = $mysqlConn
	
	Write-Debug "Created connection & command objects"
	
	try {
		$mysqlConn.Open()
		$return = $mysqlCommand.ExecuteNonQuery()
		Write-Debug "Inserted $insertCount rows."
	} catch {
		$errorMessage = $Error[0].Exception
		$errorMessage += "`n$($Error[0].InvocationInfo.PositionMessage)"
		#$errorMessage += "`nMysql Connection string: $connString"
		$errorMessage += "`nMysql query: $query"
		$return = $Error[0]
	} finally {
		$mysqlConn.Close()
	}
	
	return $return
	
}



<#
	.SYNOPSIS
		Deletes data from a MySQL Database
	
	.DESCRIPTION
		A detailed description of the Remove-MysqlData function.

		WARNING:  With great power comes great responsibility.
	
	.PARAMETER ComputerName
		Host name or IP address of the MySQL server.  Default value is localhost.
	
	.PARAMETER Port
		TCP port that the MySQL server is listening on.  Default value is 3306.
	
	.PARAMETER DatabaseName
		Name of the database to operate on.  If database is omitted it must be specified as part of the table name.
	
	.PARAMETER Credential
		MySQL server credentials.
	
	.PARAMETER DefaultTimeout
		The default command timeout in seconds for the MySQL query.  Default value is 30.
	
	.PARAMETER Table
		The name of the table to operate on.
	
	.PARAMETER Query
		The query to limit the records deleted.  Equivalent to the contents of the "where" clause in a MySQL SELECT or DELETE query.
	
	.EXAMPLE
		PS C:\> Remove-MysqlData -DatabaseName mydb -Table mytable -Query "id = 23"

		This is the equivalent of the SQL statement
		DELETE FROM mydb.mytable WHERE id = 23;
	
#>
function Remove-MysqlData {
	[CmdletBinding()]
	param
	(
		[string]$ComputerName = 'localhost',
		[int]$Port = 3306,
		[string]$DatabaseName,
		[pscredential]$Credential = $(Get-Credential -Message "Enter MySQL credentials"),
		[int]$DefaultTimeout = 30,
		[Parameter(Mandatory = $true)][string]$Table,
		[string]$Query
	)
	
	# Build the connection string
	$connString = "host=$ComputerName;port=$Port;user=$($Credential.UserName);password=$($Credential.GetNetworkCredential().Password);default command timeout=$DefaultTimeout"
	if ($DatabaseName) { $connString += ";database=$DatabaseName" }
	Write-Debug "Get-MySQLValue: $connString"
	
	# Build the query to delete data
	$deleteQuery = "DELETE FROM $Table WHERE $Query"
	
	# Create MySQL connection & command objects
	$mysqlConn = New-MySQLConnection -ConnectionString "$connString" -LoadMysqlDriver
	$mysqlCommand = New-MysqlCommand -CommandText "$deleteQuery"
	$mysqlCommand.Connection = $mysqlConn
	
	# Try to open database and execute command
	try {
		$mysqlConn.Open()
		$value = $mysqlCommand.ExecuteNonQuery()	# set $value to number of records deleted
	} catch {
		$value = $Error[0]			# if failed, set $value to the error object
	}
	
	# always close connections.  Return results of what happened above.
	$mysqlConn.Close()
	return $value
	
}


function Initialize-MysqlDriver {
	<#
		.SYNOPSIS
			Load the MySQL Driver into memory.
		
		.DESCRIPTION
			Loads the MySQL driver into memory for the current session.
			
			Possible return codes:
			0	Success
			1	Driver file not found
			2	Error loading driver
	#>
	[CmdletBinding()]
	
	$exitCode = 0
	
	$mysqlDriver = "$PSScriptRoot\mysql.data.dll"
	
	if (Test-Path -Path $mysqlDriver) {
		try {
			Add-Type -Path $mysqlDriver
		} catch {
			Write-Error "Error loading MySQL driver file $mysqlDriver."
			$exitCode = 2
		}
	} else {
		Write-Error "MySQL driver not found at $mysqlDriver."
		$exitCode = 1
	}
	
	return $exitCode
}


<#
	.SYNOPSIS
		Create a MySQL connection object
	
	.DESCRIPTION
		Create a MySQL connection object.
	
	.PARAMETER ConnectionString
		The connection string to use to connect to the database.
	
	.PARAMETER LoadMysqlDriver
		Loads Mysql driver into memory if specified.
	
	.EXAMPLE
		PS C:\> New-MySQLConnection -ConnectionString 'host=localhost;user=me;password=secret;database=mydb'
	
	.NOTES
		Additional information about the function.
#>
function New-MysqlConnection {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][string]$ConnectionString,
		[switch]$LoadMysqlDriver
	)
	
	if ($LoadMysqlDriver) {
		$driverStatus = Initialize-MySQLDriver
		if ($driverStatus -ne 0) { return }
	}
	
	Write-Debug "New-MySQLConnection: $ConnectionString"
	$conn = New-Object MySql.Data.MySqlClient.MySqlConnection
	$conn.ConnectionString = "$ConnectionString"
	
	return $conn
}


<#
	.SYNOPSIS
		Creates a MysqlCommand object
	
	.DESCRIPTION
		Creates a MysqlCommand object
	
	.PARAMETER CommandText
		An SQL query to be executed.
	
	.EXAMPLE
		PS C:\> New-MysqlCommand -CommandText 'SELECT COUNT(*) FROM mytable'
	
#>
function New-MysqlCommand {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][string]$CommandText
	)
	
	$cmd = New-Object Mysql.Data.MysqlClient.MysqlCommand
	$cmd.CommandText = "$CommandText"
	
	return $cmd
}

Export-ModuleMember -Function Add-MysqlData, Get-MysqlValue, Initialize-MysqlDriver, New-MysqlCommand, `
					New-MysqlConnection, Remove-MysqlData

