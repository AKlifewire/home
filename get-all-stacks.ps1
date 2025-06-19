# PowerShell script to get outputs for all stacks
$stacks = @(
    "dev-AppSyncStack",
    "dev-AmplifyHostingStack",
    "dev-PaymentStack",
    "dev-StorageStack",
    "dev-AuthStack",
    "dev-DeviceRegistrationStack",
    "dev-loTStack",
    "dev-UiJsonStack",
    "dev-AnalyticsStack",
    "dev-GreengrassStack",
    "dev-TwinMakerStack"
)

foreach ($stack in $stacks) {
    Write-Host "`n======================================================="
    Write-Host "Getting outputs for stack: $stack"
    Write-Host "=======================================================`n"
    
    try {
        $outputs = aws cloudformation describe-stacks --stack-name $stack --query "Stacks[0].Outputs" --output json
        
        # Try to parse and display in a more readable format
        try {
            $parsedOutputs = $outputs | ConvertFrom-Json
            Write-Host "Outputs:"
            foreach ($output in $parsedOutputs) {
                Write-Host "  $($output.OutputKey): $($output.OutputValue)"
                if ($output.Description) {
                    Write-Host "    Description: $($output.Description)"
                }
            }
        } catch {
            Write-Host "Raw output:"
            Write-Host $outputs
        }
    } catch {
        Write-Host "Error retrieving stack information: $_"
    }
}

Write-Host "`nAll stack outputs retrieved."