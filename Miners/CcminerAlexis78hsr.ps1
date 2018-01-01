﻿using module ..\Include.psm1

$Path = ".\Bin\NVIDIA-Alexis78hsr\ccminer-alexis.exe"
$Uri = "https://github.com/nemosminer/ccminer-hcash/releases/download/alexishsr/ccminer-hsr-alexis-x86-cuda8.7z"

$Port = 4068

# Custom command to be applied to all algorithms
$CommonCommands = ""

# Uncomment defunct or outpaced algorithms with _ (do not use # to distinguish from default config)
$Commands = [PSCustomObject]@{
    "blake2s"    = "" # my best values Values for 1080ti/1070/10603G "-i 31,31,31" #Blake2s, Beaten by Ccminer-x11gost. Note: do not use Excavator, high rejects
    "blakecoin"  = "" #Blakecoin, fastest!
    "c11"        = "" # my best values Values for 1080ti/1070/10603G "-i 21.5,21.5,21" #C11 beaten by Ccminer-x11gost
    "decred"     = "" #Decred, broken, invalid share
    "hsr"        = "" # my best values Values for 1080ti/1070/10603G "-i 21.5,21.5,21" # hsr, beaten by CcminerPalginHSR!
    "keccak"     = "" # my best values Values for 1080ti/1070/10603G "-m 2 -i 20" #Keccak beaten by CcminerXevan
    "lbry"       = "" # my best values Values for 1080ti/1070/10603G "-i 28" #Lbry beaten by ExcavatorNvidia6
    "lyra2v2"    = "" # my best values Values for 1080ti/1070/10603G "-i 24.25,24.25,23" #Lyra2RE2, fastest, does not pay :-(
    "myr-gr"     = "" #MyriadGroestl, beaten by CcminerKlaust817_CUDA91!
    "neoscrypt"  = "" #NeoScrypt, lower intensity is better, beaten by CcminerKlausT
    "nist5"      = "" #Nist5, beaten by CcminerKlaust817_CUDA91
    "sia"        = "" #Sia
    "sib"        = "" # my best values Values for 1080ti/1070/10603G "-i 21.5,20.5,20.5" #Sib / x11gost, beaten by Ccminer-x11gost
    "skein"      = "" # my best values Values for 1080ti/1070/10603G "-i 30,20,28.9" #Skein, where do my hashes go???
    "skein2"     = "" # Double Skein (Woodcoin)
    "vanilla"    = "" #BlakeVanilla
    "vcash"      = "" # Blake256-8rounds (XVC)
    "veltor"     = "" # my best values Values for 1080ti/1070/10603G "-i 22" #Veltor, beaten by CcminerPalgin
    "whirlpool"  = "" # whirlpool (JoinCoin)
    "x11evo"     = "" #X11evo
    "x17"        = "" # my best values Values for 1080ti/1070/10603G "-i 21.5,21.4,20.8" # Fastest
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
            PowerDraw    = $Stats."$($Name)_$($Algorithm)_PowerDraw".Week
            ComputeUsage = $Stats."$($Name)_$($Algorithm)_ComputeUsage".Week
            Pool         = "$($Pools.$Algorithm.Name)"
            Index        = $Index
        }
    }
    if ($Port) {$Port ++}
}
Sleep 0