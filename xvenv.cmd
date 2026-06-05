<# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@echo off&chcp 65001>nul&set "xvenv_launch=%~dp0.xvenv\launch.cmd"
powershell -nop -ep bypass -c "&{&([scriptblock]::create([IO.File]::ReadAllText('%~f0')))@args}" %*&&call "%xvenv_launch%"&exit/b
#>$ipc_sb=[Text.StringBuilder]::new();$env_cmd_sb=[Text.StringBuilder]::new();$env_ps1_sb=[Text.StringBuilder]::new()
function bat_add([string]$c){[void]$ipc_sb.AppendLine($c)}
function env_cmd_add([string]$c){[void]$env_cmd_sb.AppendLine($c)}
function env_ps1_add([string]$c){[void]$env_ps1_sb.AppendLine($c)}
function ps_escape([string]$v){if($null -eq $v){return ""};$v.Replace("'","''")}
function env_set([string]$n,[string]$v){env_cmd_add "set `"$n=$v`""; env_ps1_add "`$env:$n = '$((ps_escape $v))'"}
function env_path_prepend([string[]]$p){$j=($p|?{-not [string]::IsNullOrWhiteSpace($_)}) -join ';'; if($j){env_cmd_add "set `"PATH=$j;%PATH%`""; env_ps1_add "`$env:PATH = '$((ps_escape "$j;"))' + `$env:PATH"}}
function bat_save{[IO.File]::WriteAllText($env:xvenv_launch,$ipc_sb.ToString(),[Text.UTF8Encoding]::new($false))}
function env_save{[IO.File]::WriteAllText("$XVENV_HOME\env.cmd",$env_cmd_sb.ToString(),[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText("$XVENV_HOME\env.ps1",$env_ps1_sb.ToString(),[Text.UTF8Encoding]::new($false))}
#> :::::by xvenv.com::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

# Configuration
# =============================
$XVENV_SITE                = "https://xvenv.com"
$XVENV_PROJECT_HOME        = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetDirectoryName($env:xvenv_launch))
$XVENV_HOME                = "$XVENV_PROJECT_HOME\.xvenv"
$UV_PROJECT_ENVIRONMENT    = "$XVENV_HOME\python\.venv"

# Git Config
$GIT_CONFIG_GLOBAL         = "$XVENV_HOME\.gitconfig"
$GIT_SSH_COMMAND           = "ssh -i '$env:USERPROFILE\.ssh\id_ed25519_swaw' -o IdentitiesOnly=yes" # e.g., "ssh -i '$env:USERPROFILE\.ssh\id_ed25519_swaw' -o IdentitiesOnly=yes"
$GIT_AUTHOR_NAME           = "SwawHQ"
$GIT_AUTHOR_EMAIL          = "swawhq@gmail.com"

# It is recommended to set $_xvenv_download_dir externally, such as $env:USERPROFILE\Downloads\xvenv_cache, to share the download cache:
$_xvenv_download_dir       = "$env:USERPROFILE\Downloads\xvenv_cache"
#$_xvenv_download_dir       = "$XVENV_HOME\downloads"
$_xvenv_modules            = @( #"uv"            # uv package manager (install + PATH)
                                #"uv_python"     # (depends on uv) config python venv variables
                                #"uv_sync"       # (depends on uv + uv_python) create/sync venv via uv
                                "vscode_config" # auto-generate .vscode/settings.json
                                "bun"           # Bun JavaScript runtime (install + PATH)
                                #"hugo"          # Hugo static site generator (install + PATH)
                                #"env_load"      # load .env into current session
                                #"msvc"          # portable MSVC compiler + Windows SDK (Refer To https://gist.github.com/mmozeiko/7f3162ec2988e81e56d5c4e22cde9977)
                                #"rust"          # (depends on msvc) Rust toolchain via rustup
                                #"go"            # Go programming language (install + PATH)
                                #"git"           # MinGit for Windows (install + PATH)
                                "git_config"    # Git environment isolation (config, ssh, author)
                                "pwsh"          # PowerShell 7 (install + PATH)
                                "run_vscode"         # Execute VSCode (code) after setup
                                #"run_cursor"         # Execute Cursor IDE (cursor) after setup
                                #"run_windsurf"       # Execute Windsurf IDE (windsurf) after setup
                                #"run_antigravity"    # Execute Antigravity IDE (antigravity) after setup
                                #"run_zed"            # Execute Zed IDE (zed) after setup
                                #"run_cmd"            # Execute cmd.exe and keep it open
                                "run_pwsh"           # Execute pwsh.exe and keep it open
                              )
$_xvenv_uv_url             = "https://github.com/astral-sh/uv/releases/download/0.10.2/uv-x86_64-pc-windows-msvc.zip"
$_xvenv_uv_python_version  = "3.13"
$_xvenv_bun_url            = "https://github.com/oven-sh/bun/releases/download/bun-v1.2.15/bun-windows-x64.zip"
$_xvenv_hugo_url           = "https://github.com/gohugoio/hugo/releases/download/v0.157.0/hugo_extended_withdeploy_0.157.0_windows-amd64.zip"
$_xvenv_pwsh_url           = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.2/PowerShell-7.5.2-win-x64.zip"
$_xvenv_msvc_channel_url   = "https://aka.ms/vs/17/release/channel"
$_xvenv_rust_version       = "stable"
$_xvenv_rust_profile       = "minimal"
$_xvenv_rustup_url         = "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe"
$_xvenv_go_url             = "https://go.dev/dl/go1.22.4.windows-amd64.zip"
$_xvenv_git_url            = "https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/MinGit-2.45.2-64-bit.zip"


# Parse Arguments
# =============================
if ($args.Count -gt 0) {
    $argPath = $args[0].Trim('"')
    if (Test-Path $argPath) {
        $GitDir = $null
        if ($argPath -match '(?i)[\\/]?\.git[\\/]?$') {
            $GitDir = $argPath
        } elseif (Test-Path "$argPath\.git") {
            $GitDir = "$argPath\.git"
        }
        
        if ($null -ne $GitDir) {
            $RepoDir = [System.IO.Path]::GetDirectoryName($GitDir)
            $GitExe = "git.exe"
            if ($_xvenv_modules -contains 'git' -and (Test-Path "$XVENV_HOME\git\cmd\git.exe")) {
                $GitExe = "$XVENV_HOME\git\cmd\git.exe"
            }
            if (-not (Get-Command $GitExe -ErrorAction SilentlyContinue) -and -not (Test-Path $GitExe)) {
                Write-Host "Git is not available. Please run xvenv.cmd setup first, or install Git globally." -Fore Red
                Read-Host "Press Enter to exit"
            } else {
                Write-Host "`n[xvenv] Git Repository Detected: $RepoDir" -Fore Cyan
                Push-Location $RepoDir
                $Remotes = & $GitExe remote -v
                if (-not $Remotes) {
                    Write-Host "No remotes found in this repository." -Fore Yellow
                } else {
                    $OriginPush = $Remotes | Select-String -Pattern "^origin\s+(.*)\s+\(push\)$"
                    if ($OriginPush) {
                        $CurrentUrl = $OriginPush.Matches[0].Groups[1].Value
                        Write-Host "Current Remote 'origin' URL: $CurrentUrl" -Fore Green
                        
                        $NewUrl = $null
                        $Proto = ""
                        if ($CurrentUrl -match "(?i)^https?://") {
                            $NewUrl = $CurrentUrl -replace "(?i)^https?://([^/]+)/", "git@`$1:"
                            $Proto = "SSH"
                        } elseif ($CurrentUrl -match "(?i)^git@") {
                            $NewUrl = $CurrentUrl -replace "(?i)^git@([^:]+):", "https://`$1/"
                            $Proto = "HTTPS"
                        }
                        
                        if ($NewUrl) {
                            $Choice = Read-Host "`nSwitch to $Proto protocol ($NewUrl)? (y/n)"
                            if ($Choice -match "(?i)^y(es)?$") {
                                Write-Host "`nSwitching to: $NewUrl" -Fore Cyan
                                & $GitExe remote set-url origin $NewUrl
                                Write-Host "Done." -Fore Green
                            } else { Write-Host "`nNo changes made." }
                        } else {
                            Write-Host "Unrecognized protocol... no quick switch available."
                        }
                    } else {
                        Write-Host "Remote 'origin' not found. Remotes:"
                        Write-Host $Remotes
                    }
                }
                Pop-Location
                Read-Host "`nPress Enter to exit"
            }
            [IO.File]::WriteAllText($env:xvenv_launch, "@echo off`r`n")
            exit 0
        }
    }
}


# System & Constants & Helpers
# =============================
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Fetch-File ($Url, $Dest) {
    if (Test-Path $Dest) { return }
    
    Write-Host "[DL] $([IO.Path]::GetFileName($Url))" -Fore DarkGray
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $tmpDest = "$Dest.tmp"
    try { 
        try {
            # Attempt BITS first for significantly faster downloads
            Import-Module BitsTransfer -ErrorAction Stop
            Start-BitsTransfer -Source $Url -Destination $tmpDest -ErrorAction Stop
        } catch {
            # Fallback to Invoke-WebRequest if BITS is not available or fails
            Invoke-WebRequest $Url -OutFile $tmpDest -UseBasicParsing 
        }
        Move-Item $tmpDest $Dest -Force
    }
    catch { 
        Write-Host "[ERR] Download failed: $_" -Fore Red
        if (Test-Path $tmpDest) { Remove-Item $tmpDest -Force -ErrorAction SilentlyContinue }
        exit 1 
    }
}

function Extract-Zip ($ZipPath, $Dest, $SubDir=$null) {
    Write-Host "[EXT] $([IO.Path]::GetFileName($ZipPath))" -Fore DarkGray
    
    # Check zip integrity
    try { $null=[IO.Compression.ZipFile]::OpenRead($ZipPath).Dispose() } 
    catch { 
        Write-Host "[WARN] Corrupted ZIP, re-downloading..." -Fore Yellow
        Remove-Item $ZipPath -Force; return $false 
    }

    $tmp = Join-Path $_xvenv_download_dir "tmp_$([Guid]::NewGuid())"
    try { 
        # Fast native .NET extraction (avoids Expand-Archive PS pipeline overhead)
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $tmp) 
    }
    catch { 
        Write-Host "[ERR] Extraction failed: $_" -Fore Red
        Remove-Item $ZipPath -Force; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        exit 1 
    }

    $src = if ($SubDir -and (Test-Path "$tmp\$SubDir")) { "$tmp\$SubDir" } else { $tmp }
    
    # Extremely fast O(1) move instead of copying 10,000+ files
    if ((Test-Path $Dest) -and @(Get-ChildItem -Path $Dest -Force).Count -eq 0) { Remove-Item $Dest -Force }
    if (-not (Test-Path $Dest)) {
        Move-Item $src $Dest -Force
    } else {
        Get-ChildItem $src -Force | Copy-Item -Destination $Dest -Recurse -Force
    }
    
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    return $true
}

function Install-Msi ($MsiPath, $TargetDir) {
    Write-Host "[INS] $([IO.Path]::GetFileName($MsiPath))" -Fore DarkGray
    $proc = Start-Process 'msiexec' "/a `"$MsiPath`" /quiet /qn TARGETDIR=`"$TargetDir`"" -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -ne 0) { 
        Write-Host "[ERR] MSI Install failed (ExitCode $($proc.ExitCode)). Removing cached file..." -Fore Red
        if (Test-Path $MsiPath) { Remove-Item $MsiPath -Force -ErrorAction SilentlyContinue }
        exit 1 
    }
}

function Download-Extract ($Url, $Dest, $SubDir=$null, $Cleanup=$false) {
    $hash = [BitConverter]::ToString([Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Url))).Replace("-","").Substring(0,12)
    $name = [IO.Path]::GetFileNameWithoutExtension($Url)
    $cacheExt = "$_xvenv_download_dir\ext_$( $name )_$hash"
    
    if (-not (Test-Path $cacheExt)) {
        $zip = Join-Path $_xvenv_download_dir ([IO.Path]::GetFileName($Url))
        Fetch-File $Url $zip
        $tmp = Join-Path $_xvenv_download_dir "tmp_$([Guid]::NewGuid())"
        if (-not (Extract-Zip $zip $tmp $SubDir)) {
            Fetch-File $Url $zip
            $null = Extract-Zip $zip $tmp $SubDir
        }
        Move-Item $tmp $cacheExt -Force
        if ($Cleanup) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
    } else {
        Write-Host "  [CACHE] Hit extracted cache for $name" -Fore DarkGray
    }
    
    Write-Host "[CPY] Cloning $name to environment..." -Fore DarkGray
    $tmpDest = "$Dest`_tmp_$([Guid]::NewGuid())"
    New-Item -ItemType Directory -Path $tmpDest -Force | Out-Null
    Get-ChildItem $cacheExt -Force | Copy-Item -Destination $tmpDest -Recurse -Force
    Move-Item $tmpDest $Dest -Force
}

function Extract-Vsix ($VsixPath, $Dest) {
    if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Path $Dest -Force | Out-Null }
    
    # Check integrity first
    try { $null=[IO.Compression.ZipFile]::OpenRead($VsixPath).Dispose() } 
    catch { 
        Write-Host "[WARN] Corrupted VSIX archive..." -Fore Yellow
        return $false 
    }

    try {
        $z=[IO.Compression.ZipFile]::OpenRead($VsixPath)
        try {
            $createdDirs = @{}
            foreach($e in $z.Entries) {
                if($e.FullName.StartsWith('Contents/')) {
                    $d=Join-Path $Dest ([Uri]::UnescapeDataString($e.FullName.Substring(9)))
                    if(!($d.EndsWith('/'))) {
                        $dir = [IO.Path]::GetDirectoryName($d)
                        if (-not $createdDirs.ContainsKey($dir)) {
                            [void][IO.Directory]::CreateDirectory($dir)
                            $createdDirs[$dir] = $true
                        }
                        $destStream = [IO.File]::Create($d); $e.Open().CopyTo($destStream); $destStream.Dispose()
                    }
                }
            }
        } finally {
            $z.Dispose()
        }
        return $true
    } catch { 
        Write-Host "[WARN] VSIX Extraction failed: $_" -Fore Yellow; return $false 
    }
}


# Main Logic
# =============================
Write-Host "by $XVENV_SITE" -Fore Cyan
if (-not (Test-Path $XVENV_HOME)) { New-Item -ItemType Directory -Path $XVENV_HOME -Force | Out-Null }
if (-not (Test-Path $_xvenv_download_dir)) { New-Item -ItemType Directory -Path $_xvenv_download_dir -Force | Out-Null }
env_cmd_add "@echo off"
env_cmd_add "rem Generated by xvenv.cmd. Pure environment for cmd.exe."
env_ps1_add "# Generated by xvenv.cmd. Dot-source this file to load the xvenv environment."
bat_add "@echo off"
bat_add "set `"COL_RED=$([char]27)[31m`""
bat_add "set `"COL_GREEN=$([char]27)[32m`""
bat_add "set `"COL_YELLOW=$([char]27)[33m`""
bat_add "set `"COL_RESET=$([char]27)[0m`""
bat_add "call `"%~dp0env.cmd`""
env_set "XVENV_SITE" $XVENV_SITE; env_set "XVENV_PROJECT_HOME" $XVENV_PROJECT_HOME; env_set "XVENV_HOME" $XVENV_HOME
env_path_prepend @($XVENV_HOME, "$XVENV_HOME\bin")

# 1. uv
# ---------------------------
if ($_xvenv_modules -contains 'uv') {
    $H = "$XVENV_HOME\uv"; $Exe = "$H\uv.exe"
    if (-not (Test-Path $Exe)) { Write-Host "[STEP] Installing uv..." -Fore Cyan; Download-Extract $_xvenv_uv_url $H $null $false }
    env_set "XVENV_UV_HOME" $H
    env_path_prepend $H
    bat_add "call :CheckCmd `"uv`" `"uv`" `"$Exe`""
}

# 2. uv_python
# ---------------------------
if ($_xvenv_modules -contains 'uv_python'-and $_xvenv_modules -contains 'uv') {
    env_set "UV_PROJECT_ENVIRONMENT" $UV_PROJECT_ENVIRONMENT; $Env:UV_PROJECT_ENVIRONMENT=$UV_PROJECT_ENVIRONMENT
    $Uv = "$XVENV_HOME\uv\uv.exe"
    if (-not (Test-Path $UV_PROJECT_ENVIRONMENT)) {
        Write-Host "[STEP] Creating venv (Python $_xvenv_uv_python_version)..." -Fore Cyan
        Push-Location $XVENV_PROJECT_HOME; & $Uv venv $UV_PROJECT_ENVIRONMENT --python $_xvenv_uv_python_version | Out-Null; Pop-Location
    }
    env_path_prepend "$UV_PROJECT_ENVIRONMENT\Scripts"
    bat_add "call :CheckCmd `"uv_python`" `"python`" `"$UV_PROJECT_ENVIRONMENT\Scripts\python.exe`""
}

# 3. uv_sync
# ---------------------------
if ($_xvenv_modules -contains 'uv_sync' -and $_xvenv_modules -contains 'uv_python') {
    $Uv = "$XVENV_HOME\uv\uv.exe"
    if (Test-Path "$XVENV_PROJECT_HOME\pyproject.toml") {
        Write-Host "[STEP] Syncing venv..." -Fore Cyan
        Push-Location $XVENV_PROJECT_HOME; & $Uv sync --python $_xvenv_uv_python_version | Out-Null; Pop-Location
    }
    bat_add "call :CheckPath `"uv_sync`" `"$XVENV_PROJECT_HOME\.pyproject.toml`" `"uv sync --check`""
}

# 4. bun
# ---------------------------
if ($_xvenv_modules -contains 'bun') {
    $H = "$XVENV_HOME\bun"; $Exe = "$H\bun.exe"
    if (-not (Test-Path $Exe)) {
        Write-Host "[STEP] Setting up bun..." -Fore Cyan; Download-Extract $_xvenv_bun_url $H "bun-windows-x64" $false
        [IO.File]::WriteAllText("$H\bunx.cmd", "@echo off`r`n`"%~dp0bun.exe`" x %*")
    }
    env_set "XVENV_BUN_HOME" $H
    env_path_prepend $H
    bat_add "call :CheckCmd `"bun`" `"bun`" `"$Exe`""
}

# 4.5. hugo
# ---------------------------
if ($_xvenv_modules -contains 'hugo') {
    $H = "$XVENV_HOME\hugo"; $Exe = "$H\hugo.exe"
    if (-not (Test-Path $Exe)) {
        Write-Host "[STEP] Setting up Hugo..." -Fore Cyan; Download-Extract $_xvenv_hugo_url $H $null $false
    }
    env_set "XVENV_HUGO_HOME" $H
    env_path_prepend $H
    bat_add "call :CheckCmd `"hugo`" `"hugo`" `"$Exe`""
}

# 5. msvc
# ---------------------------
if ($_xvenv_modules -contains 'msvc') {
    $H_Real = "$XVENV_HOME\msvc"; $Bat = "$H_Real\setup_x64.bat"
    if (-not (Test-Path $Bat)) {
        Write-Host "[STEP] Setting up MSVC..." -Fore Cyan
        try {
            $mv = $null
            $channelHash = [BitConverter]::ToString([Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($_xvenv_msvc_channel_url))).Replace("-","").Substring(0,12)
            
            $cachedMsvc = Get-ChildItem -Path $_xvenv_download_dir -Filter "ext_msvc_*_$channelHash" -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path "$($_.FullName)\setup_x64.bat" } | Sort-Object Name -Descending | Select-Object -First 1
            
            if ($cachedMsvc) {
                $mv = $cachedMsvc.Name -replace '^ext_msvc_([^_]+)_.*', '$1'
                $msvcCache = $cachedMsvc.FullName
                Write-Host "  [CACHE] Hit MSVC extracted cache ($mv)" -Fore DarkGray
                # Dummy vars so it proceeds cleanly
                $pkgs = @{}; $sv = "offline"; $mp = $null; $sp = $null 
            } else {
                try {
                    # Fetch manifest
                    $chan = Invoke-RestMethod -Uri $_xvenv_msvc_channel_url -ErrorAction Stop
                    $manUrl = ($chan.channelItems | ?{$_.id -eq 'Microsoft.VisualStudio.Manifests.VisualStudio'}).payloads[0].url
                    $man = Invoke-RestMethod -Uri $manUrl -ErrorAction Stop
                    
                    # Map packages
                    $pkgs = @{}
                    foreach($p in $man.packages){ 
                        $id = $p.id.ToLower()
                        if(-not $pkgs[$id]){ $pkgs[$id] = @() } 
                        $pkgs[$id] += $p 
                    }
                    
                    # Find latest versions
                    $mv="0.0.0.0"; $sv="0"; $mp=$null; $sp=$null
                    foreach($k in $pkgs.Keys){
                        if($k -match '^microsoft\.vc\.(\d+\.\d+\.\d+\.\d+)\.tools\.hostx64\.targetx64\.base$'){ 
                            if([version]$Matches[1] -gt [version]$mv){ $mv=$Matches[1]; $mp=$k } 
                        }
                        if($k -match '^microsoft\.visualstudio\.component\.windows1[01]sdk\.(\d+)$'){ 
                            if([int]$Matches[1] -gt [int]$sv){ $sv=$Matches[1]; $sp=$k } 
                        }
                    }
                    
                    $msvcCache = "$_xvenv_download_dir\ext_msvc_$($mv)_$channelHash"
                    Write-Host "[INFO] MSVC v$mv, SDK v$sv" -Fore Gray
                } catch {
                    throw "Network request failed and no offline MSVC cache found. Cannot setup MSVC. Error: $_"
                }
            }

            if (-not (Test-Path "$msvcCache\setup_x64.bat")) {
                Write-Host "  [CACHE] Building MSVC extracted cache..." -Fore DarkGray
                $H = "$_xvenv_download_dir\tmp_msvc_$([Guid]::NewGuid())"
                New-Item -ItemType Directory -Path $H -Force | Out-Null
                $Tmp = "$_xvenv_download_dir\msvc_cache"
                if (-not (Test-Path $Tmp)) { New-Item -ItemType Directory -Path $Tmp -Force | Out-Null }

                # Download & Extract MSVC components
            $list = @(
                "microsoft.vc.$mv.crt.headers.base",
                "microsoft.vc.$mv.crt.source.base",
                "microsoft.vc.$mv.tools.hostx64.targetx64.base",
                "microsoft.vc.$mv.tools.hostx64.targetx64.res.base",
                "microsoft.vc.$mv.crt.x64.desktop.base",
                "microsoft.vc.$mv.crt.x64.store.base",
                "microsoft.visualcpp.dia.sdk"
            )
            foreach($id in $list){ 
                if($pkgs[$id]){ foreach($pl in $pkgs[$id][0].payloads){
                    $f="$Tmp\$($pl.fileName)"; Fetch-File $pl.url $f
                    if (-not (Extract-Vsix $f $H)) {
                        Write-Host "[WARN] Retrying VSIX extraction for $($pl.fileName)..." -Fore Yellow
                        Remove-Item $f -Force -ErrorAction SilentlyContinue
                        Fetch-File $pl.url $f
                        $null = Extract-Vsix $f $H
                    }
                }}
            }

            # Install SDK wrappers
            $s0 = $pkgs[$sp][0]
            $sdkDep = ($s0.dependencies.PSObject.Properties.Name | select -first 1).ToLower()
            $sDat = $pkgs[$sdkDep][0]

            $msis = @(
                'Windows SDK for Windows Store Apps Tools-x86_en-us.msi',
                'Windows SDK for Windows Store Apps Headers-x86_en-us.msi',
                'Windows SDK for Windows Store Apps Headers OnecoreUap-x86_en-us.msi',
                'Windows SDK for Windows Store Apps Libs-x86_en-us.msi',
                'Universal CRT Headers Libraries and Sources-x86_en-us.msi',
                "Windows SDK Desktop Headers x64-x86_en-us.msi",
                "Windows SDK OnecoreUap Headers x64-x86_en-us.msi",
                "Windows SDK Desktop Libs x64-x86_en-us.msi"
            )

            # 1. Download MSIs and scan for .cab dependencies
            $cabs = [Collections.ArrayList]::new()
            foreach($m in $msis){ 
                $pl = $sDat.payloads | ?{$_.fileName -eq "Installers\$m"} | select -first 1
                if($pl){ 
                    $f="$Tmp\$m" 
                    Fetch-File $pl.url $f
                    
                    # Scan MSI for .cab references
                    try {
                        $bytes = [IO.File]::ReadAllBytes($f); $pat = [Text.Encoding]::ASCII.GetBytes('.cab')
                        for($i=0; $i -lt $bytes.Length-4; $i++){
                            if($bytes[$i] -eq $pat[0] -and $bytes[$i+1] -eq $pat[1] -and $bytes[$i+2] -eq $pat[2] -and $bytes[$i+3] -eq $pat[3]){
                                $s = [Math]::Max(0, $i-32); $cn = [Text.Encoding]::ASCII.GetString($bytes, $s, $i-$s+4) -replace '[^\x20-\x7E]',''
                                if($cn -match '(\S+\.cab)$'){ [void]$cabs.Add($Matches[1]) }
                            }
                        }
                    } catch { Write-Host "  [WARN] Failed to scan $m for CABs" -Fore Yellow }
                } 
            }
            
            # 2. Download detected CABs
            foreach($cab in ($cabs | select -Unique)){
                $pl = $sDat.payloads | ?{$_.fileName -eq "Installers\$cab"} | select -first 1
                if($pl){
                    $f="$Tmp\$cab"
                    Fetch-File $pl.url $f
                }
            }

            # 3. Install MSIs (now that CABs are present)
            foreach($m in $msis){ 
                $f="$Tmp\$m"
                if(Test-Path $f){ 
                    Install-Msi $f $H
                    if(Test-Path "$H\$m"){ Remove-Item "$H\$m" -Force }
                } 
            }
            
            # Post-install fixups
            $mvDir=(gci "$H\VC\Tools\MSVC" -Dir|select -first 1).Name
            $svDir=(gci "$H\Windows Kits\10\bin" -Dir|?{$_.Name -match '^\d'}|select -first 1).Name
            if(Test-Path "$H\DIA SDK\bin\amd64\msdia140.dll"){ 
                $dest = "$H\VC\Tools\MSVC\$mvDir\bin\Hostx64\x64"
                if(!(Test-Path $dest)){ md $dest -Force | Out-Null }
                Move-Item "$H\DIA SDK\bin\amd64\msdia140.dll" $dest -Force 
            }

            # Cleanup: Telemetry
            if(Test-Path "$H\VC\Tools\MSVC\$mvDir\bin\Hostx64\x64\vctip.exe"){ Remove-Item "$H\VC\Tools\MSVC\$mvDir\bin\Hostx64\x64\vctip.exe" -Force }

            # Cleanup: Unused dirs (to save space)
            foreach($d in @("Common7", "Catalogs", "DesignTime", "Windows Kits\10\Catalogs", "Windows Kits\10\DesignTime")){
                if(Test-Path "$H\$d"){ Remove-Item "$H\$d" -Recurse -Force -ErrorAction SilentlyContinue }
            }
            # Remove non-x64/host architectures
            foreach($a in @("x86", "arm", "arm64")){
                foreach($d in @("VC\Tools\MSVC\$mvDir\bin\Host$a", "Windows Kits\10\bin\$svDir\$a", "Windows Kits\10\Lib\$svDir\ucrt\$a", "Windows Kits\10\Lib\$svDir\um\$a")){
                    if(Test-Path "$H\$d"){ Remove-Item "$H\$d" -Recurse -Force -ErrorAction SilentlyContinue }
                }
            }

            # CUDA/NVCC Compatibility
            $bld="$H\VC\Auxiliary\Build"; if(!(Test-Path $bld)){ md $bld -Force | Out-Null }
            [IO.File]::WriteAllText("$bld\vcvarsall.bat", "rem both bat files are here only for nvcc, do not call them manually")
            [IO.File]::WriteAllText("$bld\vcvars64.bat", "")
            
            # Generate setup batch
            $bc = @"
@echo off
set VSCMD_ARG_HOST_ARCH=x64
set VSCMD_ARG_TGT_ARCH=x64
set VCToolsVersion=$mvDir
set WindowsSDKVersion=$svDir\
set VCToolsInstallDir=%~dp0VC\Tools\MSVC\$mvDir\
set WindowsSdkBinPath=%~dp0Windows Kits\10\bin\
set PATH=%~dp0VC\Tools\MSVC\$mvDir\bin\Hostx64\x64;%~dp0Windows Kits\10\bin\$svDir\x64;%~dp0Windows Kits\10\bin\$svDir\x64\ucrt;%PATH%
set INCLUDE=%~dp0VC\Tools\MSVC\$mvDir\include;%~dp0Windows Kits\10\Include\$svDir\ucrt;%~dp0Windows Kits\10\Include\$svDir\shared;%~dp0Windows Kits\10\Include\$svDir\um;%~dp0Windows Kits\10\Include\$svDir\winrt;%~dp0Windows Kits\10\Include\$svDir\cppwinrt
set LIB=%~dp0VC\Tools\MSVC\$mvDir\lib\x64;%~dp0Windows Kits\10\Lib\$svDir\ucrt\x64;%~dp0Windows Kits\10\Lib\$svDir\um\x64
"@
                [IO.File]::WriteAllText("$H\setup_x64.bat", $bc)
                Move-Item $H $msvcCache -Force
            } else {
                Write-Host "  [CACHE] Hit MSVC extracted cache" -Fore DarkGray
            }
            
            Write-Host "[CPY] Cloning MSVC to environment..." -Fore DarkGray
            $tmpDest = "$H_Real`_tmp_$([Guid]::NewGuid())"
            New-Item -ItemType Directory -Path $tmpDest -Force | Out-Null
            Get-ChildItem $msvcCache -Force | Copy-Item -Destination $tmpDest -Recurse -Force
            Move-Item $tmpDest $H_Real -Force
        } catch { 
            Write-Host "[FATAL] MSVC Install Failed: $_" -Fore Red
            if ($null -ne $H -and (Test-Path $H)) { Remove-Item $H -Recurse -Force -ErrorAction SilentlyContinue }
            throw 
        }
    }
    
    $MsvcToolDir = Get-ChildItem "$H_Real\VC\Tools\MSVC" -Directory | Sort-Object Name -Descending | Select-Object -First 1
    $SdkBinDir = Get-ChildItem "$H_Real\Windows Kits\10\bin" -Directory | Where-Object { $_.Name -match '^\d' } | Sort-Object Name -Descending | Select-Object -First 1
    $mvDir = $MsvcToolDir.Name
    $svDir = $SdkBinDir.Name
    $MsvcRoot = "$H_Real\VC\Tools\MSVC\$mvDir"
    $SdkRoot = "$H_Real\Windows Kits\10"
    $ClExe = "$MsvcRoot\bin\Hostx64\x64\cl.exe"
    env_set "XVENV_MSVC_HOME" $H_Real
    env_set "VSCMD_ARG_HOST_ARCH" "x64"
    env_set "VSCMD_ARG_TGT_ARCH" "x64"
    env_set "VCToolsVersion" $mvDir
    env_set "WindowsSDKVersion" "$svDir\"
    env_set "VCToolsInstallDir" "$MsvcRoot\"
    env_set "WindowsSdkBinPath" "$SdkRoot\bin\"
    env_path_prepend @("$MsvcRoot\bin\Hostx64\x64", "$SdkRoot\bin\$svDir\x64", "$SdkRoot\bin\$svDir\x64\ucrt")
    env_set "INCLUDE" "$MsvcRoot\include;$SdkRoot\Include\$svDir\ucrt;$SdkRoot\Include\$svDir\shared;$SdkRoot\Include\$svDir\um;$SdkRoot\Include\$svDir\winrt;$SdkRoot\Include\$svDir\cppwinrt"
    env_set "LIB" "$MsvcRoot\lib\x64;$SdkRoot\Lib\$svDir\ucrt\x64;$SdkRoot\Lib\$svDir\um\x64"
    bat_add "call :CheckCmd `"msvc`" `"cl`" `"$ClExe`""
}

# 6. rust
# ---------------------------
if ($_xvenv_modules -contains 'rust') {
    $H = "$XVENV_HOME\cargo"; $Rustup = "$XVENV_HOME\rustup"
    if (-not (Test-Path "$H\bin\cargo.exe")) {
        Write-Host "[STEP] Setting up Rust..." -Fore Cyan
        $rustUrlHash = [BitConverter]::ToString([Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($_xvenv_rustup_url))).Replace("-","").Substring(0,12)
        $rustHash = "$($_xvenv_rust_version)_$($_xvenv_rust_profile)_$rustUrlHash"
        $rustCache = "$_xvenv_download_dir\ext_rust_$rustHash"
        
        if (-not (Test-Path "$rustCache\cargo\bin\cargo.exe")) {
            Write-Host "  [CACHE] Building Rust extracted cache..." -Fore DarkGray
            $tmpC = "$_xvenv_download_dir\tmp_rust_$([Guid]::NewGuid())"
            New-Item -ItemType Directory -Path "$tmpC\cargo" -Force | Out-Null
            New-Item -ItemType Directory -Path "$tmpC\rustup" -Force | Out-Null

            $RustInst="$_xvenv_download_dir\rustup-init.exe"
            if(!(Test-Path $RustInst)){ Fetch-File $_xvenv_rustup_url $RustInst }
            
            $env:RUSTUP_HOME = "$tmpC\rustup"; $env:CARGO_HOME = "$tmpC\cargo"
            $proc = Start-Process $RustInst "-y --default-host x86_64-pc-windows-msvc --no-modify-path --profile $($_xvenv_rust_profile) --default-toolchain $($_xvenv_rust_version)" -Wait -PassThru -NoNewWindow
            if ($proc.ExitCode -ne 0) { throw "Rust install failed." }
            
            Move-Item $tmpC $rustCache -Force
        } else {
            Write-Host "  [CACHE] Hit Rust extracted cache" -Fore DarkGray
        }

        Write-Host "[CPY] Cloning Rust to environment..." -Fore DarkGray
        
        $tmpCargo = "$H`_tmp_$([Guid]::NewGuid())"
        $tmpRustup = "$Rustup`_tmp_$([Guid]::NewGuid())"
        
        New-Item -ItemType Directory -Path $tmpCargo -Force | Out-Null
        New-Item -ItemType Directory -Path $tmpRustup -Force | Out-Null
        
        Get-ChildItem "$rustCache\cargo" -Force | Copy-Item -Destination $tmpCargo -Recurse -Force
        Get-ChildItem "$rustCache\rustup" -Force | Copy-Item -Destination $tmpRustup -Recurse -Force
        
        Move-Item $tmpCargo $H -Force
        Move-Item $tmpRustup $Rustup -Force
    }
    env_set "RUSTUP_HOME" $Rustup; env_set "CARGO_HOME" $H; env_path_prepend "$H\bin"
    bat_add "call :CheckCmd `"rust`" `"cargo`" `"$H\bin\cargo.exe`""
}

# 7. go
# ---------------------------
if ($_xvenv_modules -contains 'go') {
    $H = "$XVENV_HOME\go"; $Exe = "$H\bin\go.exe"
    if (-not (Test-Path $Exe)) {
        Write-Host "[STEP] Setting up Go..." -Fore Cyan; Download-Extract $_xvenv_go_url $H "go" $false
    }
    env_set "XVENV_GO_HOME" $H
    env_set "GOROOT" $H
    env_set "GOPATH" "$XVENV_PROJECT_HOME\.xvenv\gopath"
    env_set "GOCACHE" "$XVENV_PROJECT_HOME\.xvenv\gocache"
    env_path_prepend "$H\bin"
    bat_add "call :CheckCmd `"go`" `"go`" `"$Exe`""
}

# 8. git
# ---------------------------
if ($_xvenv_modules -contains 'git') {
    $H = "$XVENV_HOME\git"; $Exe = "$H\cmd\git.exe"
    if (-not (Test-Path $Exe)) {
        Write-Host "[STEP] Setting up Git..." -Fore Cyan; Download-Extract $_xvenv_git_url $H $null $false
    }
    env_set "XVENV_GIT_HOME" $H
    env_path_prepend "$H\cmd"
    bat_add "call :CheckCmd `"git`" `"git`" `"$Exe`""
}

# 9. git_config
# ---------------------------
if ($_xvenv_modules -contains 'git_config') {
    if (-not [string]::IsNullOrWhiteSpace($GIT_CONFIG_GLOBAL)) { 
        if (-not (Test-Path $GIT_CONFIG_GLOBAL)) { New-Item -ItemType File -Path $GIT_CONFIG_GLOBAL -Force | Out-Null }
        env_set "GIT_CONFIG_GLOBAL" $GIT_CONFIG_GLOBAL
        bat_add "call :CheckPath `"git_config`" `"$GIT_CONFIG_GLOBAL`""
    }
    if (-not [string]::IsNullOrWhiteSpace($GIT_SSH_COMMAND)) { env_set "GIT_SSH_COMMAND" $GIT_SSH_COMMAND }
    if (-not [string]::IsNullOrWhiteSpace($GIT_AUTHOR_NAME)) { 
        env_set "GIT_AUTHOR_NAME" $GIT_AUTHOR_NAME
        env_set "GIT_COMMITTER_NAME" $GIT_AUTHOR_NAME
    }
    if (-not [string]::IsNullOrWhiteSpace($GIT_AUTHOR_EMAIL)) { 
        env_set "GIT_AUTHOR_EMAIL" $GIT_AUTHOR_EMAIL
        env_set "GIT_COMMITTER_EMAIL" $GIT_AUTHOR_EMAIL
    }

    $Ig = "$XVENV_PROJECT_HOME\.gitignore"
    if (-not (Test-Path $Ig)) {
        [IO.File]::WriteAllText($Ig, "`n.xvenv/`n.env`n")
    } else {
        $IgContent = Get-Content $Ig -Raw
        if ($IgContent -notmatch "(?m)^\.xvenv/\s") { Add-Content $Ig "`n.xvenv/" }
        if ($IgContent -notmatch "(?m)^\.env\s")    { Add-Content $Ig "`n.env" }
    }

    if (-not (Test-Path "$XVENV_PROJECT_HOME\.git")) {
        bat_add "echo    [STEP] Initializing Git Repository..."
        bat_add "git init >nul 2>&1"
    }
}

# 10. pwsh
# ---------------------------
if ($_xvenv_modules -contains 'pwsh') {
    $H = "$XVENV_HOME\pwsh"; $Exe = "$H\pwsh.exe"
    if (-not (Test-Path $Exe)) { Write-Host "[STEP] Installing pwsh..." -Fore Cyan; Download-Extract $_xvenv_pwsh_url $H $null $false }
    env_set "XVENV_PWSH_HOME" $H
    env_path_prepend $H
    bat_add "call :CheckCmd `"pwsh`" `"pwsh`" `"$Exe`""
}

# 11. vscode_config
# ---------------------------
if ($_xvenv_modules -contains 'vscode_config') {
    if(!(Test-Path "$XVENV_PROJECT_HOME\.vscode")){ md "$XVENV_PROJECT_HOME\.vscode" | Out-Null }
    
    $JContent = [ordered]@{}

    if ($_xvenv_modules -contains 'go') {
        $GoH = "$XVENV_HOME/go".Replace('\','/')
        $JContent["go.gopath"] = "${workspaceFolder}/.xvenv/gopath"
        $JContent["go.goroot"] = $GoH
    }

    if ($_xvenv_modules -contains 'uv_python') {
        $PyPath = "$UV_PROJECT_ENVIRONMENT/Scripts/python.exe".Replace('\','/')
        $JContent["python.defaultInterpreterPath"] = $PyPath
        $JContent["python.terminal.activateEnvironment"] = $true
        $JContent["python.venvPath"] = "${workspaceFolder}/.xvenv/python"
        $JContent["python.venvFolders"] = @(".venv")
    }

    if ($_xvenv_modules -contains 'pwsh') {
        $PwPath = "$XVENV_HOME/pwsh/pwsh.exe".Replace('\','/')
        $JContent["terminal.integrated.defaultProfile.windows"] = "pwsh"
        $JContent["terminal.integrated.profiles.windows"] = @{
            "pwsh"=@{ "path"=$PwPath; "args"=@(); "overrideName"=$true }
        }
    }
    
    if ($JContent.Count -gt 0) {
        $SetJson = "$XVENV_PROJECT_HOME\.vscode\settings.json"
        
        # Merge with existing settings if present
        if (Test-Path $SetJson) {
            try {
                $rawJson = Get-Content $SetJson -Raw -Encoding UTF8
                # Strip simple line comments to help ConvertFrom-Json
                $rawJson = $rawJson -replace '(?m)^\s*//.*$',''
                $Current = $rawJson | ConvertFrom-Json
                foreach($k in $Current.PSObject.Properties.Name) {
                    if (-not $JContent.Contains($k)) { $JContent[$k] = $Current.$k }
                }
            } catch {
                Write-Host "[WARN] Could not parse existing settings.json. Skipping VSCode config update." -Fore Yellow
                $jContent = $null
            }
        }

        if ($null -ne $JContent) {
            $JStr = $JContent | ConvertTo-Json -Depth 5
            [IO.File]::WriteAllText($SetJson, $JStr, [Text.UTF8Encoding]::new($false))
        }
    }
    bat_add "call :CheckPath `"vscode_config`" `"$XVENV_PROJECT_HOME\.vscode\settings.json`""
}

# 12. env_load
# ---------------------------
if ($_xvenv_modules -contains 'env_load') {
    bat_add "call :CheckPath `"env_load`" `"$XVENV_PROJECT_HOME\.env`""
    if (Test-Path "$XVENV_PROJECT_HOME\.env") {
        Get-Content "$XVENV_PROJECT_HOME\.env" | %{ 
            if($_ -match "^([^#=]+)=(.*)$"){ env_set ($Matches[1].Trim()) ($Matches[2].Trim()) } 
        }
    }
}

# 13. Finalize & Validate
# ---------------------------
# Launch IDEs
$LaunchCount = 0
foreach ($ide in @(
    @{ m='run_vscode'; cmd='code'; args='cmd /c code "%XVENV_PROJECT_HOME%"' },
    @{ m='run_cursor'; cmd='cursor'; args='cmd /c cursor "%XVENV_PROJECT_HOME%"' },
    @{ m='run_windsurf'; cmd='windsurf'; args='cmd /c windsurf "%XVENV_PROJECT_HOME%"' },
    @{ m='run_antigravity'; cmd='antigravity'; args='cmd /c antigravity "%XVENV_PROJECT_HOME%"' },
    @{ m='run_zed'; cmd='zed'; args='start "" /b zed "%XVENV_PROJECT_HOME%"' }
)) {
    if ($_xvenv_modules -contains $ide.m) {
        bat_add "call :CheckCmd `"$($ide.m)`" `"$($ide.cmd)`" `"`" `"start`""
        bat_add "if not errorlevel 1 $($ide.args)"
        $LaunchCount++
    }
}


# Launch Shell
$LaunchCmd = $_xvenv_modules -contains 'run_cmd'
$LaunchPwsh = $_xvenv_modules -contains 'run_pwsh'
if ($LaunchCmd -or $LaunchPwsh -or $LaunchCount -eq 0) {
    if ($LaunchCmd) { bat_add "echo    run_cmd         ok start            cmd.exe" }
    if ($LaunchPwsh) { bat_add "echo    run_pwsh        ok start            pwsh.exe" }
    $Launch = "cmd /k"
    # If explicitly asking for pwsh, or if neither is asked but pwsh is installed and backwards compatibility dictates pwsh
    $UsePwsh = $LaunchPwsh -or (-not $LaunchCmd -and $_xvenv_modules -contains 'pwsh' -and $LaunchCount -eq 0)
    if($UsePwsh){ 
        $pwshExe = if($_xvenv_modules -contains 'pwsh') { "`"%XVENV_PWSH_HOME%\pwsh.exe`"" } else { "pwsh.exe" }
        $Launch = "$pwshExe -NoExit -NoLogo"
        if($_xvenv_modules -contains 'uv_python' -and (Test-Path "$UV_PROJECT_ENVIRONMENT\Scripts\Activate.ps1")){ 
            $Launch += " -Command `"& '%UV_PROJECT_ENVIRONMENT%\Scripts\Activate.ps1'`"" 
        } 
    } else { 
        if($_xvenv_modules -contains 'uv_python' -and (Test-Path "$UV_PROJECT_ENVIRONMENT\Scripts\activate.bat")){
            $Launch = "cmd /k `"call %UV_PROJECT_ENVIRONMENT%\Scripts\activate.bat`""
        }
    }
    bat_add $Launch
}
bat_add "goto :eof"

# Batch Helper Functions
# ---------------------------
bat_add ""
bat_add ""
bat_add ""
bat_add ":CheckPath"
bat_add "set `"Name=%~1             `""
bat_add "set `"Name=%Name:~0,15%`""
bat_add "set `"Helper=%~3`""
bat_add "if `"%Helper%`"==`"`" set `"Helper=check path`""
bat_add "set `"Helper=%Helper%                      `""
bat_add "set `"Helper=%Helper:~0,15%`""
bat_add "if not exist `"%~2`" (echo    %Name% %COL_RED%ERR %Helper% not found: %~2%COL_RESET%) else (echo    %Name% ok %Helper% %~2)"
bat_add "exit /b"
bat_add ":CheckCmd"
bat_add "set `"Name=%~1             `""
bat_add "set `"Name=%Name:~0,15%`""
bat_add "set `"Helper=%~4`""
bat_add "if `"%Helper%`"==`"`" set `"Helper=where.exe %~2`""
bat_add "set `"Helper=%Helper%                      `""
bat_add "set `"Helper=%Helper:~0,15%`""
bat_add "where.exe /q `"%~2`""
bat_add "if errorlevel 1 ("
bat_add "    echo    %Name% %COL_RED%ERR %Helper% Not in PATH: %~3%COL_RESET%"
bat_add "    exit /b"
bat_add ")"
bat_add "for /f `"delims=`" %%A in ('where.exe `"%~2`"') do set `"ACTUAL=%%A`" & goto :CheckCmd_Found"
bat_add ":CheckCmd_Found"
bat_add "if `"%~3`"==`"`" ("
bat_add "    echo    %Name% ok %Helper% %ACTUAL%"
bat_add "    exit /b"
bat_add ")"
bat_add "if /i `"%ACTUAL%`"==`"%~3`" ("
bat_add "    echo    %Name% ok %Helper% %ACTUAL%"
bat_add ") else ("
bat_add "    echo    %Name% %COL_YELLOW%WARN %Helper% Shadowed by %ACTUAL%%COL_RESET%"
bat_add ")"
bat_add "exit /b"

env_save
bat_save
