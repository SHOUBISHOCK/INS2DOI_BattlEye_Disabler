# Load required assemblies for GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the Form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Game Manager"
$Form.Size = New-Object System.Drawing.Size(500,470)
$Form.StartPosition = "CenterScreen"

# Label for detected games
$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Detected Games:"
$Label.Location = New-Object System.Drawing.Point(20,20)
$Label.Size = New-Object System.Drawing.Size(440,20)
$Form.Controls.Add($Label)

# Textbox for output
$TextBox = New-Object System.Windows.Forms.RichTextBox
$TextBox.Multiline = $true
$TextBox.ScrollBars = "Vertical"
$TextBox.Size = New-Object System.Drawing.Size(440,200)
$TextBox.Location = New-Object System.Drawing.Point(20,50)
$Form.Controls.Add($TextBox)

# Progress Bar
$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(20,260)
$ProgressBar.Size = New-Object System.Drawing.Size(440,20)
$ProgressBar.Minimum = 0
$ProgressBar.Maximum = 100
$Form.Controls.Add($ProgressBar)

# Button to scan and fix games
$Button = New-Object System.Windows.Forms.Button
$Button.Text = "Scan & Fix Games"
$Button.Location = New-Object System.Drawing.Point(150,290)
$Button.Size = New-Object System.Drawing.Size(200,30)
$Form.Controls.Add($Button)

# Label for powered by
$PoweredByLabel = New-Object System.Windows.Forms.Label
$PoweredByLabel.Text = "Powered by ChatGPT!"
$PoweredByLabel.Location = New-Object System.Drawing.Point(20,330)
$PoweredByLabel.Size = New-Object System.Drawing.Size(440,20)
$PoweredByLabel.TextAlign = "MiddleCenter"
$Form.Controls.Add($PoweredByLabel)

# Function to append text in green color
function Append-GreenText {
    param ([string]$message)
    $TextBox.SelectionStart = $TextBox.TextLength
    $TextBox.SelectionLength = 0
    $TextBox.SelectionColor = 'Green'
    $TextBox.AppendText($message + "`r`n")
    $TextBox.SelectionColor = $TextBox.ForeColor
}

# Define Steam App IDs and executable names
$games = @{ 
    "Day of Infamy" = @{ AppID = "447820"; Exe = "dayofinfamy_x64.exe"; Folder = "dayofinfamy" }
    "Insurgency" = @{ AppID = "222880"; Exe = "insurgency_x64.exe"; Folder = "insurgency2" }
}

# Function to run detection and modification
$Button.Add_Click({
    $TextBox.Clear()
    $ProgressBar.Value = 10
    
    Append-GreenText "Scanning for games..."
    
    # Get Steam installation path from registry
    $steamRegPath = "HKCU:\\Software\\Valve\\Steam"
    $steamPath = $null
    
    if (Test-Path $steamRegPath) {
        $steamPath = (Get-ItemProperty -Path $steamRegPath -Name "SteamPath" -ErrorAction SilentlyContinue).SteamPath
    }
    
    if (-not $steamPath) {
        Append-GreenText "Steam installation not found."
        return
    }
    $ProgressBar.Value = 20

    # Load Steam library folders dynamically
    $libraryFolders = @($steamPath, "D:\\SteamLibrary")
    
    Append-GreenText "Detected Steam library folders:"
    $libraryFolders | ForEach-Object { Append-GreenText " - $_" }
    
    # Process each game
    foreach ($game in $games.GetEnumerator()) {
        $appID = $game.Value.AppID
        $exeName = $game.Value.Exe
        $folderName = $game.Value.Folder
        $gamePath = $null
        
        Append-GreenText "Checking for $($game.Key) path in detected libraries:"
        foreach ($lib in $libraryFolders) {
            $possiblePath = "$lib\\steamapps\\common\\$folderName"
            Append-GreenText " - Checking $possiblePath"
            if (Test-Path "$possiblePath") {
                $gamePath = $possiblePath
                Append-GreenText "Found $($game.Key) in library: $gamePath"
                break
            }
        }
        
        $ProgressBar.Value = 50

        if ($gamePath) {
            Append-GreenText "Processing $($game.Key)..."
            
            $exeFiles = Get-ChildItem -Path "$gamePath" -Filter "$exeName" -ErrorAction SilentlyContinue

            if ($exeFiles.Count -eq 0) {
                Append-GreenText "Error: No executable found in $gamePath"
            } else {
                $sourceExe = "$gamePath\\$exeName"
                $destExe = $sourceExe -replace '_x64', '_BE'
                $disabledExe = $sourceExe -replace '_x64', '_BE_disabled'
                
                if (Test-Path "$destExe") {
                    if (-not (Test-Path "$disabledExe")) {
                        Rename-Item -Path "$destExe" -NewName "$disabledExe" -Force
                        Append-GreenText "Backed up: $destExe -> $disabledExe"
                    } else {
                        Remove-Item -Path "$destExe" -Force
                        Append-GreenText "Removed existing BE file: $destExe"
                    }
                }
                
                Copy-Item -Path "$sourceExe" -Destination "$destExe" -Force
                Append-GreenText "Replaced BE with: $sourceExe -> $destExe"
            }
            Append-GreenText "Processing completed for $($game.Key)."
        } else {
            Append-GreenText "$($game.Key) is NOT installed."
        }
    }
    $ProgressBar.Value = 100
    
    $Button.Text = "Exit"
    $Button.Add_Click({ 
        Start-Process "https://mygamingedge.online/"
        $Form.Close() 
    })
})

# Show Form
[void]$Form.ShowDialog()
