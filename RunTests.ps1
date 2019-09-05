class TestCase
{
    [string] $TestName=""
    [string] $ProjectFile=""
    [bool] $BuildSucceeds=$true
    [string[]] $PassCriteria=""

    TestCase([string]$ProjectFile, [bool] $BuildSucceeds)
    {
        $this.Init($ProjectFile, $BuildSucceeds, @())
    }

    TestCase([string]$ProjectFile, [bool] $BuildSucceeds, [string[]]$PassCriteria)
    {
        $this.Init($ProjectFile, $BuildSucceeds, $PassCriteria)
    }

    hidden Init([string]$ProjectFile, [bool] $BuildSucceeds, [string[]]$PassCriteria)
    {
        $this.ProjectFile = $ProjectFile
        $this.BuildSucceeds = $BuildSucceeds
        $this.PassCriteria = $PassCriteria
    }
}

$testCases = @(
    [TestCase]::new("DefaultSwitches.csproj", $true)
    [TestCase]::new("ExplicitAppDef.csproj", $true)
    [TestCase]::new("ExplicitAppDefAndPages.csproj", $true)
    [TestCase]::new("ExplicitAppDefFlagNoAppDef.csproj", $false)
    [TestCase]::new("ExplicitFlagsNoPageOrAppDef.csproj", $false)
    [TestCase]::new("ExplicitPages.csproj", $true)
    [TestCase]::new("ExplicitPageFlagNoPage.csproj", $false)
    [TestCase]::new("ExplicitItems.csproj", $true)
    [TestCase]::new("ExplicitItemsNoAppDef.csproj", $false)
    [TestCase]::new("ExplicitItemsNoPage.csproj", $true)
    [TestCase]::new("ExplicitItemsNoPageOrAppDef.csproj", $false)
    [TestCase]::new("NoSwitches.csproj", $false, @("NETSDK1106"))
)

if (Test-Path "log")
{
    Remove-Item "log" -Force -Recurse | Out-Null
}

foreach ($testCase in $testCases)
{
    Write-Host Test Case: $testCase.ProjectFile -ForegroundColor White

    dotnet clean $testCase.ProjectFile | Out-Null
    dotnet restore $testCase.ProjectFile | Out-Null
    $result = dotnet build $testCase.ProjectFile -bl

    if (($? -and $testCase.BuildSucceeds) -or (!$? -and !$testCase.BuildSucceeds))
    {
        Write-Host `t BuildSucceeds: Expected: $testCase.BuildSucceeds Actual: $? - PASS -ForegroundColor Green

        foreach ($criteria in $testCase.PassCriteria)
        {
            if ($result -Match $criteria)
            {
                Write-Host `t Criteria: $criteria - PASS -ForegroundColor Green
            }
            else
            {
                Write-Host `t Criteria: $criteria - FAIL -ForegroundColor Red
            }
        }
    }
    else
    {
         Write-Host `t BuildSucceeds: Expected: $testCase.BuildSucceeds Actual: $? - FAIL -ForegroundColor Red
    }


    if (!(Test-Path "log"))
    {
        New-Item "log" -ItemType Directory | Out-Null
    }

    Move-Item -Path msbuild.binlog -Destination (Join-Path -Path "log" -ChildPath ($testCase.ProjectFile + ".binlog")) -Force
 }