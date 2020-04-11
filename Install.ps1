Add-Type -AssemblyName 'System.Windows.Forms'

function Main {
	$script:MagicENB = Get-ChildItem 'MagicENB'

	$choice = [Windows.Forms.MessageBox]::Show(
		"Welcome to the MagicENB installer!`n`n" +
		"Yes: install`n" +
		"No: uninstall`n" +
		"Cancel: cancel installation",
		"MagicENB Installation",
		[Windows.Forms.MessageBoxButtons]::YesNoCancel)

	if ($choice -eq [Windows.Forms.DialogResult]::Cancel) {
		return
	}

	$path = GetInstallPath
	if ($null -eq $path) {
		return
	}

	if ($choice -eq [Windows.Forms.DialogResult]::Yes) {
		Install $path
	} elseif ($choice -eq [Windows.Forms.DialogResult]::No) {
		Uninstall $path
	} else {
		throw 'Unexpected dialog result'
	}
}

function GetInstallPath {
	$fileBrowser = [Windows.Forms.OpenFileDialog]::new()
	$fileBrowser.Filter = 'Skyrim SE (SkyrimSE.exe)|SkyrimSE.exe'

	if ($fileBrowser.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) {
		return $null
	}

	return Split-Path $fileBrowser.FileName -Parent
}

function Install($path) {
	foreach ($item in $script:MagicENB) {
		New-Item `
			-ItemType SymbolicLink `
			-Path "$path\$($item.Name)" `
			-Value $item.FullName `
			-Force `
			-ErrorAction SilentlyContinue `
			-ErrorVariable errorVar `
			| Out-Null
	
		if ($errorVar.Count -gt 0) {
			throw $errorVar[0]
		}
	}
	
	[void][Windows.Forms.MessageBox]::Show(
		"MagicENB installation successful!",
		"Success",
		[Windows.Forms.MessageBoxButtons]::OK)
}

function Uninstall($path) {
	foreach ($item in $script:MagicENB) {
		$filePath = "$path\$($item.Name)"
		
		if (Test-Path $filePath) {
			[void](Get-Item $filePath).Delete()
		}
	}

	[void][Windows.Forms.MessageBox]::Show(
		"MagicENB uninstallation successful!",
		"Success",
		[Windows.Forms.MessageBoxButtons]::OK)
}

try {
	Main
} catch {
	[void][Windows.Forms.MessageBox]::Show(
		"Fatal Error:`n`n$_",
		"Fatal Error",
		[Windows.Forms.MessageBoxButtons]::OK,
		[Windows.Forms.MessageBoxIcon]::Error)
}