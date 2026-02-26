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

# Keep console window open until user presses a key
function Wait-ForAnyKey {
    Write-Host ""
    try {
        # Use host key-reading when available (console hosts and VS Code terminal).
        Write-Host "Press any key to exit..."
        [void]$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        # Fallback for hosts like Windows PowerShell ISE.
        [void](Read-Host "Press Enter to exit")
    }
}

# Prompt user to select source folder
function Select-SourceFolder {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select a folder to list its files"
    $folderBrowser.ShowNewFolderButton = $false

    $dialogResult = $folderBrowser.ShowDialog()
    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }

    return $null
}

# Prompt user to select output folder
function Select-OutputFolder {
    param([string]$DefaultPath)

    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select output folder for exported file(s)"
    $folderBrowser.ShowNewFolderButton = $false
    if (-not [string]::IsNullOrWhiteSpace($DefaultPath)) {
        $folderBrowser.SelectedPath = $DefaultPath
    }

    $dialogResult = $folderBrowser.ShowDialog()
    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }

    return $null
}

$sourceFolder = Select-SourceFolder
if ($null -eq $sourceFolder) {
    Write-Host "No folder selected. Exiting."
    Wait-ForAnyKey
    return
}

Write-Host "Selected folder: $sourceFolder"
Write-Host ""

$outputFolder = Select-OutputFolder -DefaultPath $sourceFolder
if ($null -eq $outputFolder) {
    $outputFolder = $sourceFolder
    Write-Host "No output folder selected. Using source folder for output."
}
else {
    Write-Host "Output folder: $outputFolder"
}
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
        Wait-ForAnyKey
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

    $outputFile = Join-Path $outputFolder "FileFolderList.txt"
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
    $outputFile = Join-Path $outputFolder "TreeView.txt"
    $treeOutput | Out-File -FilePath $outputFile -Encoding UTF8

    Write-Host "`nTree view exported to $outputFile"
}

Wait-ForAnyKey
