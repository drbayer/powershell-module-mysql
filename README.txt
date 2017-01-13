MySQL Module for PowerShell

This is a PowerShell module for working with MySQL databases.

To install, put PSMySQL.psm1 and PSMySQL.psd1 in folder
C:\Program Files\WindowsPowerShell\Modules\PSMySQL

Included cmdlets:

	Add-MysqlData
		Inserts data into a Mysql database.

	Get-MySQLValue
		Returns the results of a MySQL query with a single-value
		result set.  If the query returns more than 1 result an
		error will be thrown.

	Initialize-MySQLDriver
		Loads the MySQL .NET driver into memory for this 
		PowerShell session only.

	New-MysqlCommand
		Creates a MysqlCommand object containing a query to execute.

	New-MysqlConnectoin
		Creates a MysqlConnection object to be used for
		query execution.