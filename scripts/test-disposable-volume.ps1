param(
	[string]$Dotnet = 'dotnet',
	[string]$SessionDirectory,
	[switch]$Preflight
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$resultsRoot = [IO.Path]::GetFullPath((Join-Path $repo 'Keysharp.Tests\TestResults'))
if (!$SessionDirectory) {
	$SessionDirectory = Join-Path $resultsRoot ('disposable-volume-' + [Guid]::NewGuid().ToString('N'))
}
$session = [IO.Path]::GetFullPath($SessionDirectory)
if (!$session.StartsWith($resultsRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
	throw 'The session directory must be inside Keysharp.Tests\TestResults.'
}
$image = Join-Path $session 'keysharp-test.vhd'
if (Test-Path -LiteralPath $image) { throw 'The test image must not already exist.' }
$dotnetPath = (Get-Command $Dotnet -CommandType Application).Source
$assembly = Join-Path $repo 'bin\Release\net10.0-windows\Keysharp.Tests.dll'
if (!(Test-Path -LiteralPath $assembly)) { throw 'Build the Release test assembly first.' }
foreach ($command in 'Mount-DiskImage', 'Get-DiskImage', 'Get-Disk', 'Initialize-Disk', 'New-Partition', 'Format-Volume', 'Dismount-DiskImage', 'diskpart.exe') {
	$null = Get-Command $command
}
$filter = 'FullyQualifiedName=Keysharp.Tests.DriveTests.DriveGetSetLabel|FullyQualifiedName=Keysharp.Tests.FileAndDirTests.FileRecycleEmpty'
$state = [ordered]@{
	status = 'preflight'; session = $session; image = $image; capacity_mib = 256
	test_assembly = $assembly; assembly_sha256 = (Get-FileHash -LiteralPath $assembly -Algorithm SHA256).Hash
	filter = $filter; requires_administrator = $true; root = $null; disk_number = $null
	tests_passed = $false; detached = $false; image_removed = $false; error = $null; cleanup_error = $null
}
if ($Preflight) { $state | ConvertTo-Json; return }
$principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	throw 'Run this script from an elevated PowerShell process; it does not request elevation itself.'
}
if (Test-Path -LiteralPath $session) { throw 'Use a new session directory.' }
$null = New-Item -ItemType Directory -Path $session
$encoding = [Text.UTF8Encoding]::new($false)
$statePath = Join-Path $session 'result.json'
function Save-State {
	[IO.File]::WriteAllText($statePath, ($state | ConvertTo-Json -Depth 6), $encoding)
}
function Get-TestDisk {
	$disks = @(Get-DiskImage -ImagePath $image | Get-Disk)
	if ($disks.Count -ne 1) { throw 'The new image must map to exactly one disk.' }
	$disk = $disks[0]
	if ($disk.IsBoot -or $disk.IsSystem -or $disk.Size -ne 256MB) {
		throw 'Refusing to modify a boot/system disk or an image of unexpected size.'
	}
	if ($null -ne $state.disk_number -and $disk.Number -ne $state.disk_number) {
		throw 'The image disk number changed.'
	}
	return $disk
}
$priorVolume = $env:KEYSHARP_TEST_VOLUME
$priorDaemon = $env:KEYSHARP_DAEMON
$mountAttempted = $false
$resultCode = 1
try {
	$state.status = 'creating-image'; Save-State
	$diskpartScript = Join-Path $session 'create-vhd.txt'
	[IO.File]::WriteAllText($diskpartScript, "create vdisk file=`"$image`" maximum=256 type=expandable`r`nexit`r`n", $encoding)
	$diskpart = Start-Process -FilePath "$env:SystemRoot\System32\diskpart.exe" -ArgumentList @('/s', "`"$diskpartScript`"") -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $session 'diskpart.log') -RedirectStandardError (Join-Path $session 'diskpart-error.log')
	if ($diskpart.ExitCode -ne 0 -or !(Test-Path -LiteralPath $image)) { throw 'Failed to create the new VHD.' }
	$state.status = 'mounting-image'; Save-State
	$mountAttempted = $true
	$null = Mount-DiskImage -ImagePath $image -Access ReadWrite -NoDriveLetter -PassThru
	$disk = Get-TestDisk
	if ($disk.PartitionStyle -ne 'RAW') { throw 'The new disk must be uninitialized.' }
	$state.disk_number = $disk.Number
	if ($disk.IsOffline) { $disk | Set-Disk -IsOffline $false }
	$null = $disk | Initialize-Disk -PartitionStyle MBR -Confirm:$false
	$disk = Get-TestDisk
	$partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter
	$null = Get-TestDisk
	if ($partition.DiskNumber -ne $state.disk_number) { throw 'Unexpected partition disk number.' }
	$root = [string]$partition.DriveLetter + ':\'
	if ($root -eq [IO.Path]::GetPathRoot($env:SystemRoot) -or $root -notmatch '^[A-Za-z]:\\$') {
		throw 'The disposable volume must have a non-system drive letter.'
	}
	$state.root = $root
	$state.status = 'formatting-new-image'; Save-State
	$null = Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel KEYSHARP_TEST -Confirm:$false -Force
	[IO.File]::WriteAllText((Join-Path $root '.keysharp-disposable-test-volume'), 'Keysharp disposable test volume', $encoding)
	$env:KEYSHARP_TEST_VOLUME = $root
	$env:KEYSHARP_DAEMON = '0'
	$state.status = 'running-tests'; Save-State
	Push-Location $repo
	try {
		& $dotnetPath test Keysharp.Tests\Keysharp.Tests.csproj -c Release -p:PublishReadyToRun=false --no-build --no-restore --nologo --filter $filter --results-directory $session --logger 'trx;LogFileName=disposable-volume.trx' --blame-hang --blame-hang-timeout 45s --blame-hang-dump-type mini -- NUnit.NumberOfTestWorkers=1 *> (Join-Path $session 'tests.log')
		$testExit = $LASTEXITCODE
	} finally { Pop-Location }
	[xml]$trx = [IO.File]::ReadAllText((Join-Path $session 'disposable-volume.trx'))
	$cases = @($trx.SelectNodes("//*[local-name()='UnitTestResult']"))
	if ($testExit -ne 0 -or $cases.Count -ne 2 -or @($cases | Where-Object outcome -ne Passed).Count -ne 0) {
		throw 'The two disposable-volume tests did not both pass; see tests.log and the TRX.'
	}
	$state.tests_passed = $true
	$state.status = 'passed'
	$resultCode = 0
} catch {
	$state.status = 'failed'
	$state.error = $_.Exception.Message
	[Console]::Error.WriteLine($_.ToString())
} finally {
	$env:KEYSHARP_TEST_VOLUME = $priorVolume
	$env:KEYSHARP_DAEMON = $priorDaemon
	try {
		if ($mountAttempted) {
			if ((Get-DiskImage -ImagePath $image).Attached) { Dismount-DiskImage -ImagePath $image }
			$state.detached = !(Get-DiskImage -ImagePath $image).Attached
		}
		if ($state.tests_passed -and $state.detached) {
			$target = (Get-Item -LiteralPath $image).FullName
			if ($target -ne (Join-Path $session 'keysharp-test.vhd') -or !$target.StartsWith($resultsRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
				throw 'Unexpected image cleanup path.'
			}
			Remove-Item -LiteralPath $target
			$state.image_removed = $true
		}
	} catch {
		$state.cleanup_error = $_.Exception.Message
		$state.status = 'failed'
		$resultCode = 1
	}
	Save-State
}
exit $resultCode
