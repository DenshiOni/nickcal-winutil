# NickCal Windows Utility
# Run with: irm https://nickcal.com/win | iex

$Host.UI.RawUI.WindowTitle = "NickCal Windows Utility"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Require-Admin {
    $admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator"
    )

    if (-not $admin) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please run PowerShell as Administrator.",
            "NickCal Windows Utility",
            "OK",
            "Error"
        )
        exit
    }
}

function Install-App {
    param (
        [string]$Id,
        [string]$Name
    )

    Write-Host "Installing $Name..." -ForegroundColor Cyan

    winget install --id $Id -e `
        --accept-source-agreements `
        --accept-package-agreements
}

function Remove-BloatApps {
    Write-Host "Removing common Windows junk apps..." -ForegroundColor Yellow

    $apps = @(
        "Microsoft.BingNews",
        "Microsoft.BingWeather",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.People",
        "Microsoft.Todos",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.XboxApp",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "MicrosoftTeams",
        "Microsoft.YourPhone"
    )

    foreach ($app in $apps) {
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
}

function Apply-PrivacyTweaks {
    Write-Host "Applying privacy and ad settings..." -ForegroundColor Yellow

    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSyncProviderNotifications /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f
}

function Apply-ExplorerTweaks {
    Write-Host "Applying File Explorer tweaks..." -ForegroundColor Yellow

    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f

    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
}

function Disable-WidgetsAndChat {
    Write-Host "Disabling Widgets and Chat..." -ForegroundColor Yellow

    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f
}

Require-Admin

$form = New-Object System.Windows.Forms.Form
$form.Text = "NickCal Windows Utility"
$form.Size = New-Object System.Drawing.Size(430, 520)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

$title = New-Object System.Windows.Forms.Label
$title.Text = "NickCal Windows Utility"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Choose what you want to install or change."
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(22, 55)
$form.Controls.Add($subtitle)

$checks = @{}

$options = @(
    "Install Firefox",
    "Install 1Password",
    "Install Google Chrome",
    "Install VLC",
    "Install Everything Search",
    "Install 7-Zip",
    "Remove common Windows junk apps",
    "Apply privacy and ad tweaks",
    "Apply File Explorer tweaks",
    "Disable Widgets and Chat"
)

$y = 95

foreach ($option in $options) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $option
    $cb.AutoSize = $true
    $cb.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $cb.Location = New-Object System.Drawing.Point(25, $y)
    $form.Controls.Add($cb)
    $checks[$option] = $cb
    $y += 32
}

$selectAll = New-Object System.Windows.Forms.Button
$selectAll.Text = "Select Recommended"
$selectAll.Size = New-Object System.Drawing.Size(160, 35)
$selectAll.Location = New-Object System.Drawing.Point(25, 420)
$selectAll.Add_Click({
    foreach ($option in $options) {
        $checks[$option].Checked = $true
    }
})
$form.Controls.Add($selectAll)

$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run Selected"
$runButton.Size = New-Object System.Drawing.Size(120, 35)
$runButton.Location = New-Object System.Drawing.Point(200, 420)
$runButton.Add_Click({
    $form.Tag = "Run"
    $form.Close()
})
$form.Controls.Add($runButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Size = New-Object System.Drawing.Size(80, 35)
$cancelButton.Location = New-Object System.Drawing.Point(330, 420)
$cancelButton.Add_Click({
    $form.Tag = "Cancel"
    $form.Close()
})
$form.Controls.Add($cancelButton)

$form.ShowDialog() | Out-Null

if ($form.Tag -ne "Run") {
    Write-Host "Canceled."
    exit
}

if ($checks["Install Firefox"].Checked) {
    Install-App "Mozilla.Firefox" "Firefox"
}

if ($checks["Install 1Password"].Checked) {
    Install-App "AgileBits.1Password" "1Password"
}

if ($checks["Install Google Chrome"].Checked) {
    Install-App "Google.Chrome" "Google Chrome"
}

if ($checks["Install VLC"].Checked) {
    Install-App "VideoLAN.VLC" "VLC"
}

if ($checks["Install Everything Search"].Checked) {
    Install-App "voidtools.Everything" "Everything Search"
}

if ($checks["Install 7-Zip"].Checked) {
    Install-App "7zip.7zip" "7-Zip"
}

if ($checks["Remove common Windows junk apps"].Checked) {
    Remove-BloatApps
}

if ($checks["Apply privacy and ad tweaks"].Checked) {
    Apply-PrivacyTweaks
}

if ($checks["Apply File Explorer tweaks"].Checked) {
    Apply-ExplorerTweaks
}

if ($checks["Disable Widgets and Chat"].Checked) {
    Disable-WidgetsAndChat
}

Write-Host ""
Write-Host "NickCal setup complete. Restart your PC when ready." -ForegroundColor Green

[System.Windows.Forms.MessageBox]::Show(
    "NickCal setup complete. Restart your PC when ready.",
    "NickCal Windows Utility",
    "OK",
    "Information"
)
