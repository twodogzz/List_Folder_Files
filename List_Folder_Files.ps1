'''
    How this works:
    You pick a folder with a GUI dialog.
    You answer prompts in the console:
    Recursive? (Y/N)
    Listing type: Files & folders list (1) or Tree view (2)
    The script then outputs the listing accordingly.
    The result is shown on screen and saved as a .txt file inside the selected folder.
'''

# Load WinForms (required for FolderBrowserDialog)
Add-Type -AssemblyName System.Windows.Forms

# Function to show tree view
function Show-Tree {
    param (
        [string]$Path,
        [string]$Indent = ""
    )

    $items = Get-ChildItem -Path $Path

    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            Write-Output "$Indent|-- $($item.Name)\"
            Show-Tree -Path $item.FullName -Indent ("$Indent|   ")
        } else {
            Write-Output "$Indent|-- $($item.Name)"
        }
    }
}

# Prompt user for recursive option
function Get-YesNoInput($message) {
    while ($true) {
        $userInput = Read-Host "$message (Y/N)"
        if ($userInput -match '^[Yy]$') { return $true }
        elseif ($userInput -match '^[Nn]$') { return $false }
        else { Write-Host "Please enter Y or N." }
    }
}

# Prompt user for listing type
function Get-ListingType {
    while ($true) {
        $userInput = Read-Host "Choose listing type: 1 = Files & Folders list, 2 = Tree view"
        if ($userInput -eq '1') { return 'list' }
        elseif ($userInput -eq '2') { return 'tree' }
        else { Write-Host "Please enter 1 or 2." }
    }
}

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

# Ask user for options
$recursive = Get-YesNoInput "List items recursively?"
$listingType = Get-ListingType

$outputLines = @()

if ($listingType -eq 'list') {
    # List files and folders
    $items = if ($recursive) {
        Get-ChildItem -Path $sourceFolder -Recurse
    } else {
        Get-ChildItem -Path $sourceFolder
    }

    if ($items.Count -eq 0) {
        Write-Host "No files or folders found."
        return
    }

    Write-Host "Items found:`n"

    foreach ($item in $items) {
        $type = if ($item.PSIsContainer) { "DIR " } else { "FILE" }
        $isoDate = $item.LastWriteTime.ToString("yyyy-MM-dd")
        $line = "{0}`t{1}`t{2}" -f $type, $item.FullName, $isoDate
        Write-Host $line
        $outputLines += $line
    }

    $outputFile = Join-Path $sourceFolder "FileFolderList.txt"
    $outputLines | Out-File -FilePath $outputFile -Encoding UTF8

    Write-Host "`nList exported to $outputFile"
}
else {
    # Tree view (recursive only makes sense here)
    if (-not $recursive) {
        Write-Host "Tree view requires recursive listing. Enabling recursive mode."
        $recursive = $true
    }

    Write-Host "Tree view of ${sourceFolder}:`n"
    $treeOutput = Show-Tree -Path $sourceFolder
    $treeOutput | ForEach-Object { Write-Host $_ }
    $outputFile = Join-Path $sourceFolder "TreeView.txt"
    $treeOutput | Out-File -FilePath $outputFile -Encoding UTF8

    Write-Host "`nTree view exported to $outputFile"
}
