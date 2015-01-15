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
		Load the MySQL Driver into memory.
	
	.DESCRIPTION
		Loads the MySQL driver into memory for the current session.
		
		Possible return codes:
		0	Success
		1	Driver file not found
		2	Error loading driver
#>
function Initialize-MySQLDriver {
	[CmdletBinding()]
	[OutputType([int])]
	
	$exitCode = 0
	
	$scriptDir = Get-ScriptDirectory
	$mysqlDriver = "$scriptDir\mysql.data.dll"
	
	if (Test-Path -Path $mysqlDriver) {
		try {
			Add-Type -Path $mysqlDriver
		} catch {
			$exitCode = 2
		}
	} else {
		$exitCode = 1
	}
	
	return $exitCode
}
	
	
<#
	.SYNOPSIS
		Returns the directory of the script file.
	
	.DESCRIPTION
		Returns the directory of the script file.
#>
function Get-ScriptDirectory {
	[CmdletBinding()]
	[OutputType([string])]
	
	$scriptdir = $script:MyInvocation.MyCommand.Path
	return $scriptdir
}

