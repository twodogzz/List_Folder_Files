# Load WinForms (required for FolderBrowserDialog)
Add-Type -AssemblyName System.Windows.Forms

# Create and configure the folder browser dialog
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Select a folder to list its files"
$folderBrowser.ShowNewFolderButton = $false

# Show the dialog
$dialogResult = $folderBrowser.ShowDialog()

# Handle cancel
if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "No folder selected. Exiting."
    return
}

# Get selected folder
$sourceFolder = $folderBrowser.SelectedPath
Write-Host "Selected folder: $sourceFolder"
Write-Host ""

# Retrieve file list
$files = Get-ChildItem -Path $sourceFolder #-File

if ($files.Count -eq 0) {
    Write-Host "No files found in this folder."
    return
}

# Display file names
Write-Host "Files found:`n"
foreach ($file in $files) {
    $isoDate = $file.LastWriteTime.ToString("yyyy-MM-dd")
    Write-Host $file.Name "`t" $isoDate
}

# Export the same data to a text file
$outputLines = @()
$outputLines += "Files found:`n"
foreach ($file in $files) {
    $isoDate = $file.LastWriteTime.ToString("yyyy-MM-dd")
    $outputLines += "$($file.Name)`t$isoDate"
}

$outputLines | Out-File -FilePath "$sourceFolder\FileList.txt" -Encoding UTF8

Write-Host "`nFile list exported to FileList.txt"