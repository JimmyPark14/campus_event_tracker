param (
    [switch]$Major,
    [switch]$Minor,
    [switch]$Patch
)

$ErrorActionPreference = "Stop"

$pubspecPath = "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath
$versionLine = $pubspecContent | Where-Object { $_ -match "^version:\s*(.+)$" }

if (-not $versionLine) {
    Write-Error "Could not find version line in pubspec.yaml"
    exit
}

$currentVersion = $matches[1]
Write-Host "Current version: $currentVersion" -ForegroundColor Cyan

if ($currentVersion -match "^(\d+)\.(\d+)\.(\d+)\+(\d+)$") {
    $majorVer = [int]$matches[1]
    $minorVer = [int]$matches[2]
    $patchVer = [int]$matches[3]
    $buildNum = [int]$matches[4]

    if ($Major) {
        $majorVer++
        $minorVer = 0
        $patchVer = 0
    } elseif ($Minor) {
        $minorVer++
        $patchVer = 0
    } else {
        # Default is patch
        $patchVer++
    }
    
    $buildNum++
    $newVersion = "$majorVer.$minorVer.$patchVer+$buildNum"
    Write-Host "New version: $newVersion" -ForegroundColor Green

    # Update pubspec.yaml
    (Get-Content $pubspecPath) -replace "^version:\s*.+$", "version: $newVersion" | Set-Content $pubspecPath

    Write-Host "Building release APK..." -ForegroundColor Cyan
    flutter build apk --release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Flutter build failed. Aborting release."
        # Rollback version bump
        (Get-Content $pubspecPath) -replace "^version:\s*.+$", "version: $currentVersion" | Set-Content $pubspecPath
        exit
    }

    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkPath) {
        $renamedApkPath = "build\app\outputs\flutter-apk\cet_${newVersion}.apk"
        Rename-Item -Path $apkPath -NewName "cet_${newVersion}.apk" -Force

        Write-Host "Committing version bump to git..." -ForegroundColor Cyan
        git add pubspec.yaml
        git commit -m "chore: bump version to $newVersion"
        
        Write-Host "Creating and pushing tag v$newVersion..." -ForegroundColor Cyan
        git tag "v$newVersion"
        git push origin HEAD
        git push origin "v$newVersion"

        Write-Host "Creating GitHub Release..." -ForegroundColor Cyan
        gh release create "v$newVersion" $renamedApkPath --title "Release v$newVersion" --generate-notes
        
        Write-Host "Release created successfully! 🎉" -ForegroundColor Green
        Write-Host "Check it out at: https://github.com/JimmyPark14/campus_event_tracker/releases" -ForegroundColor Cyan
    } else {
        Write-Error "APK not found at $apkPath. Aborting release."
    }
} else {
    Write-Error "Could not parse version. Ensure it is in format X.Y.Z+B (e.g. 1.0.0+1)"
}

<#
Usage Examples:
.\release.ps1         # Increments Patch (1.0.1 -> 1.0.2)
.\release.ps1 -Minor  # Increments Minor (1.0.1 -> 1.1.0)
.\release.ps1 -Major  # Increments Major (1.1.0 -> 2.0.0)
#>