using module ..\Include.psm1

class BMiner : Miner {
	[PSCustomObject]GetData ([String[]]$Algorithm, [Bool]$Safe = $false, [String]$DebugPreference = "SilentlyContinue") {
		$Server = "localhost"
		$Timeout = 10 #seconds

		$Delta = 0.05
		$Interval = 5
		$HashRates = @()

		$PowerDraws = @()
		$ComputeUsages = @()
        
        if ($this.index -eq $null -or $this.index -le 0) {
            $Index = @()
            for ($i = 0; $i -le 15; $i++) {$Index += $i}               
        }
        else {
            $Index = $this.index
        }
			
		$URI = "http://$($Server):$($this.Port)/api/status"
        $Response = ""

		do {
			# Read Data from hardware
			$ComputeData = [PSCustomObject]@{}
			$ComputeData = (Get-ComputeData -MinerType $this.type -Index $this.index)

#			$PowerDraws += $ComputeData.PowerDraw
#			$ComputeUsages += $ComputeData.ComputeUsage

			$HashRates += $HashRate = [PSCustomObject]@{}

			try {
			    $Response = Invoke-WebRequest $URI -UseBasicParsing -TimeoutSec $Timeout -ErrorAction Stop
			    $Data = $Response | ConvertFrom-Json -ErrorAction Stop
			}
			catch {
			    Write-Log -Level Error "Failed to connect to miner ($($this.Name)). "
			    break
			}

            if ($DebugPreference -ne "SilentlyContinue") {Write-Log -Level Debug $Response}

            $HashRate_Value = 0
            $PowerDraw = 0
            $ComputeUsage = 0
            $ComputeUsageCount = 0
            $Index | Where  {$Data.miners.$_.device} | ForEach {
                $HashRate_Value += [Double]$Data.miners.$_.solver.solution_rate
                $PowerDraw += [Double]$Data.miners.$_.device.power
                $ComputeUsage += [Double]$Data.miners.$_.device.utilization.gpu
                $ComputeUsageCount++
            }

            if ($ComputeUsageCount -gt 0) {
                $PowerDraws += [Double]$PowerDraw
                $ComputeUsages += ($ComputeUsage / $ComputeUsageCount)
            }

			$HashRate_Name = [String]$Algorithm[0]
			if ($Algorithm[0] -match ".+NiceHash") {
				$HashRate_Name = "$($HashRate_Name)Nicehash"
			}

			if ($HashRate_Name -and ($Algorithm -like (Get-Algorithm $HashRate_Name)).Count -eq 1) {
			    $HashRate | Add-Member @{(Get-Algorithm $HashRate_Name) = [Int64]$HashRate_Value}
			}

			$Algorithm | Where-Object {-not $HashRate.$_} | ForEach-Object {break}

			if (-not $Safe) {break}

			Start-Sleep $Interval
		} while ($HashRates.Count -lt 6)

		$HashRate = [PSCustomObject]@{}
		$Algorithm | ForEach-Object {$HashRate | Add-Member @{$_ = [Int64]($HashRates.$_ | Measure-Object -Maximum -Minimum -Average | Where-Object {$_.Maximum - $_.Minimum -le $_.Average * $Delta}).Maximum}}
		$Algorithm | Where-Object {-not $HashRate.$_} | Select-Object -First 1 | ForEach-Object {$Algorithm | ForEach-Object {$HashRate.$_ = [Int]0}}

		$PowerDraws_Info = [PSCustomObject]@{}
		$PowerDraws_Info = ($PowerDraws | Measure-Object -Maximum -Minimum -Average)
		$PowerDraw = if ($PowerDraws_Info.Maximum - $PowerDraws_Info.Minimum -le $PowerDraws_Info.Average * $Delta) {$PowerDraws_Info.Maximum} else {$PowerDraws_Info.Average}

		$ComputeUsages_Info = [PSCustomObject]@{}
		$ComputeUsages_Info = ($ComputeUsages | Measure-Object -Maximum -Minimum -Average)
		$ComputeUsage = if ($ComputeUsages_Info.Maximum - $ComputeUsages_Info.Minimum -le $ComputeUsages_Info.Average * $Delta) {$ComputeUsages_Info.Maximum} else {$ComputeUsages_Info.Average}

		return [PSCustomObject]@{
			HashRate     = $HashRate
			PowerDraw    = $PowerDraw
			ComputeUsage = $ComputeUsage
            Response     = $Response
		}
	}
}