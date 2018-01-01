﻿using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-ccminer-2.2.3\ccminer-x64.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.3-tpruvot/ccminer-x64-2.2.3-cuda9.7z"

$Port = 4068

# Custom command to be applied to all algorithms
$CommonCommands = " --submit-stale"

# Uncomment defunct or outpaced algorithms with _ (do not use # to distinguish from default config)
$Commands = [PSCustomObject]@{
    #"bitcore"      = "" # Do not use, peaks and falls back to low earnings
    "blake2s"       = "" # my best values Values for 1080ti/1070/10603G "-i 31,31,31" # beaten by CcminerAlexis78Hsr, do not use Excavator, high rejects
    "blakecoin"     = "" # my best values Values for 1080ti/1070/10603G "-i 31" 
    "c11"           = "" # my best values Values for 1080ti/1070/10603G "-i 21" # Beaten by Ccminer-x11gost
    "cryptonight"   = "" # my best values Values for 1080ti/1070/10603G "-i 10.75,10.75,10 --bfactor=12,8,8"
    "decred"        = ""
    "equihash"      = ""
    "groestl"       = "" # my best values Values for 1080ti/1070/10603G "-i 26.5" # beaten by Ccminer-Klaust814_CUDA9
    "hmq1725"       = ""
    "hsr"           = "" # my best values Values for 1080ti/1070/10603G "-i 21,21,20.25" # beaten by CcminerAlexis78hsr
    "keccak"        = "" # my best values Values for 1080ti/1070/10603G "-i 31,30,30" #BROKEN!
    "keccakc"       = "" # Keccak-256 (CreativeCoin)
    "lbry"          = "" # my best values Values for 1080ti/1070/10603G "-i 29,29,28"
    "lyra2v2"       = "" # beaten by Ccminer-Palgin-Nist5
    "lyra2z"        = "" # my best values Values for 1080ti/1070/10603G "-i 22,21,21" # Lyra2z for ZCash, Beaten by CcminerLyra2Z
    "myr-gr"        = "" # my best values Values for 1080ti/1070/10603G "-i 24" # Beaten by CcminerAlexis78cuda8.0
    "neoscrypt"     = "" # my best values Values for 1080ti/1070/10603G "-i 26" # beaten by Ccminer-Palgin-Nist5
    "nist5"         = "" # my best values Values for 1080ti/1070/10603G "-i 27,26.25,24.75" # Beaten, beaten by CcminerKlaust817_CUDA91
    "penta"         = "" # Pentablake hash (5x Blake 512)
    "phi"           = "" # my best values Values for 1080ti/1070/10603G "-i 25,24,24" # Ccminer 2.2.3 x86 is faster
    "polytimos"     = "" # my best values Values for 1080ti/1070/10603G "-i 26.25,26.25" # polytimos, beaten by CcminerPolytimos
    "sia"           = "" # my best values Values for 1080ti/1070/10603G "-i 31,31,31" #
    "sib"           = "" # my best values Values for 1080ti/1070/10603G "-i 21"
    "skein"         = "" # my best values Values for 1080ti/1070/10603G "-i 30,29,29" # Beaten by Ccminer 2.2.3 x86
    "skunk"         = "" # my best values Values for 1080ti/1070/10603G "-i 25.7,25.2,24.9" # Beaten by Ccminer 2.2.3 x86
    #"timetravel"   = "" # my best values Values for 1080ti/1070/10603G "-i 24"
    "tribus"        = ""
    "vanilla"       = ""
    "veltor"        = "" # my best values Values for 1080ti/1070/10603G "-i 23" # Fastest
    "x11evo"        = "" # my best values Values for 1080ti/1070/10603G "-i 21"
    "x17"           = "" # beaten by CcminerAlexis78hsr
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Type = "NVIDIA"
$Devices = ($GPUs | Where {$Type -contains $_.Type}).Device
$Devices | ForEach-Object {

    $Device = $_

    $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where {$_ -cnotmatch "^_.+" -and $Pools.$(Get-Algorithm($_)).Name -and {$Pools.$(Get-Algorithm($_)).Protocol -eq "stratum+tcp" <#temp fix#>}} | ForEach-Object {

        $Algorithm = Get-Algorithm($_)
        $Command =  $Commands.$_

        if ($Devices.count -gt 1) {
            $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)_$($Device.Device_Norm)"
            $Command = "$(Get-CommandPerDevice -Command "$Command" -Devices $Device.Devices) -d $($Device.Devices -join ',')"
            $Index = $Device.Devices -join ","
        }

        {while (Get-NetTCPConnection -State "Listen" -LocalPort $($Port) -ErrorAction SilentlyContinue){$Port++}} | Out-Null

        [PSCustomObject]@{
            Name         = $Name
            Type         = $Type
            Device       = $Device.Device
            Path         = $Path
            Arguments    = "-a $_ -o $($Pools.$Algorithm.Protocol)://$($Pools.$Algorithm.Host):$($Pools.$Algorithm.Port) -u $($Pools.$Algorithm.User) -p $($Pools.$Algorithm.Pass) -b $Port $Command $CommonCommands"
            HashRates    = [PSCustomObject]@{$Algorithm = ($Stats."$($Name)_$($Algorithm)_HashRate".Week)}
            API          = "Ccminer"
            Port         = $Port
            Wrap         = $false
            URI          = $Uri
            PowerDraw	 = $Stats."$($Name)_$($Algorithm)_PowerDraw".Week
            ComputeUsage = $Stats."$($Name)_$($Algorithm)_ComputeUsage".Week
            Pool         = "$($Pools.$Algorithm.Name)"
            Index        = $Index
        }
    }
    if ($Port) {$Port ++}
}
Sleep 0