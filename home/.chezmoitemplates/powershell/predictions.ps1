# predictions.ps1
# Chained command prediction support (Requires PowerShell 7.2+)

# 1. NAMESPACES
# PowerShell plugins are built on .NET. These "using" statements are just
# telling PowerShell where to find the internal tools needed to build a Predictor.
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Subsystem
using namespace System.Management.Automation.Subsystem.Prediction
using namespace System.Threading

# Skip if PowerShell version too old (Predictors require 7.2+)
if ($PSVersionTable.PSVersion -lt [Version]"7.2") {
    Write-Warning "Chained command prediction requires PowerShell 7.2+"
    return
}

# 2. THE CLASS 
# 'class' is a C#-style way to create a blueprint. 
# 'ICommandPredictor' is a strict rulebook provided by Microsoft. It says:
# "If you want to make a predictor, you MUST include specific functions, 
# even if they are empty."
class ChainedCommandPredictor : ICommandPredictor {
    
    # Every plugin needs a unique ID and Name to register with the system.
    [Guid]   $Id = [Guid]::new("b5c9f4d2-8e3a-4f1b-9c7d-6a2e8f0b3d5c")
    [string] $Name = "ChainedCommand"
    [string] $Description = "Provides predictions for commands after chain operators"

    # 3. THE LOGIC (GetSuggestion)
    # This function triggers every time you press a key.
    # It returns a "SuggestionPackage" - this is just a container required by 
    # the PowerShell engine to hold your list of grey-text suggestions.
    [SuggestionPackage] GetSuggestion([PredictionClient]$client, [PredictionContext]$context, [CancellationToken]$token) {
        
        # Get the full text of what you have typed so far.
        $input = $context.InputAst.Extent.Text

        # Look for the last chaining operator (&&, ||, ;, or |) followed by a word.
        if ($input -match '.*(\&\&|\|\||;|\|)\s*(\S+)$') {
            
            $partial = $Matches[2] # e.g., "wh"
            $prefix = $input.Substring(0, $input.Length - $partial.Length) # e.g., "echo 'hello' && "

            # Create an empty list to hold our suggestions.
            $suggestions = [List[PredictiveSuggestion]]::new()

            # Look at your last 50 commands.
            Get-History -Count 50 | ForEach-Object {
                
                # If a past command starts with "wh", add it to our list.
                if ($_.CommandLine.StartsWith($partial, [StringComparison]::OrdinalIgnoreCase) -and
                    $_.CommandLine -ne $partial) {
                    
                    # We glue the prefix ("echo && ") to the history match ("whoami")
                    $suggestions.Add([PredictiveSuggestion]::new($prefix + $_.CommandLine))
                }
            }

            # If we found matches, wrap them in the "Package" container and return them.
            if ($suggestions.Count -gt 0) {
                return [SuggestionPackage]::new($suggestions)
            }
        }

        # If you aren't typing after an && (or we found nothing), return nothing.
        return $null
    }

    # 4. THE REQUIRED "EMPTY" METHODS
    # Because we are using the 'ICommandPredictor' rulebook, PowerShell demands 
    # these methods exist, even though we don't need them for our simple plugin.
    [bool] CanAcceptFeedback([PredictionClient]$client, [PredictorFeedbackKind]$feedback) { return $false }
    [void] OnSuggestionDisplayed([PredictionClient]$client, [uint32]$session, [int]$countOrIndex) {}
    [void] OnSuggestionAccepted([PredictionClient]$client, [uint32]$session, [string]$acceptedSuggestion) {}
    [void] OnCommandLineAccepted([PredictionClient]$client, [IReadOnlyList[string]]$history) {}
    [void] OnCommandLineExecuted([PredictionClient]$client, [string]$commandLine, [bool]$success) {}
}

# 5. REGISTRATION
# Check if our plugin is already running (to prevent errors if you reload your profile).
$registered = [SubsystemManager]::GetSubsystems([SubsystemKind]::CommandPredictor) |
    Where-Object { $_.Name -eq "ChainedCommand" }

# If it's not running, register it with the PowerShell Subsystem Engine.
if (-not $registered) {
    try {
        [SubsystemManager]::RegisterSubsystem([SubsystemKind]::CommandPredictor, [ChainedCommandPredictor]::new())
    } catch {
        Write-Warning "Failed to register chained command predictor: $_"
    }
}

# 6. TURN IT ON
# Tells PSReadLine (the command-line UI) to show grey text using both History and our new Plugin.
Set-PSReadLineOption -PredictionSource HistoryAndPlugin