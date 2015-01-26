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

function Initialize-MySQLDriver {
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
	
	$scriptDir = Get-ScriptDirectory
	$mysqlDriver = "$scriptDir\mysql.data.dll"
	
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


function Get-ScriptDirectory {
	<#
		.SYNOPSIS
			Returns the directory of the script file.
		
		.DESCRIPTION
			Returns the directory of the script file.
	#>
	[CmdletBinding()]
	[OutputType([string])]
	
	$scriptdir = Split-Path $script:MyInvocation.MyCommand.Path
	return $scriptdir
}


function Get-MySQLValue {
	<#
		.SYNOPSIS
			Query a MySQL database and return a single value.  If the MySQL query returns more than a single value an error is returned.
		
		.DESCRIPTION
			Query a MySQL database and return a single value.  If the MySQL query returns more than a single value an error is returned.
		
		.PARAMETER ComputerName
			Hostname or IP address of the MySQL server.  Default value is localhost.
		
		.PARAMETER Port
			Network TCP port for the MySQL server.  Default value is 3306.
		
		.PARAMETER User
			MySQL user with adequate permissions for the query.
		
		.PARAMETER Password
			MySQL password
		
		.PARAMETER DatabaseName
			Name of the database to query.
		
		.PARAMETER DefaultTimeout
			Timeout value in seconds.  Default value is 30.
		
		.PARAMETER Query
			SQL statement that returns a single value
		
		.EXAMPLE
			PS C:\> Get-MySQLValue -ComputerName 'Value1' -User 'Value2'
		
		.NOTES
			Additional information about the function.
	#>
	[CmdletBinding()]
	param
	(
		[string]$ComputerName = 'localhost',
		[int]$Port = 3306,
		[Parameter(Mandatory = $true)][string]$User,
		[string]$Password,
		[string]$DatabaseName,
		[int]$DefaultTimeout = 30,
		[Parameter(Mandatory = $true)][string]$Query
	)
	
	#TODO: get password securely; allow no password
	$driverStatus = Initialize-MySQLDriver
	if ($driverStatus -ne 0) { return }
	
	$connString = "host=$ComputerName;port=$Port;user=$User;password=$Password;default command timeout=$DefaultTimeout"
	$mysqlConn = New-MySQLConnection -ConnectionString $connString
	
}


function New-MySQLConnection {
	<#
		.SYNOPSIS
			Create a MySQL connection object
		
		.DESCRIPTION
			Create a MySQL connection object.
		
		.PARAMETER ConnectionString
			The connection string to use to connect to the database.
		
		.EXAMPLE
					PS C:\> New-MySQLConnection -ConnectionString 'Value1'
		
		.NOTES
			Additional information about the function.
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][string]$ConnectionString
	)
	
	$driverStatus = Initialize-MySQLDriver
	if ($driverStatus -ne 0) { return }
	
	$conn = New-Object MySql.Data.MySqlClient.MySqlConnection
	$conn.ConnectionString = $ConnectionString
	
	return $conn
}


function Get-Password {

    $pw = Read-Host -AsSecureString "Enter password"
    $Creds.Password = (New-Object System.Management.Automation.PSCredential($Creds.Username,$Creds.Password)).GetNetworkCredential().Password

    Write-Output $Creds
}

