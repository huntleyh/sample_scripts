function Remove-BlobsWithOrWithoutVersions {
    param (
        [Parameter(Mandatory=$true)]
        [string]$accountName,        
        [Parameter(Mandatory=$true)]
        [string]$containerName,        
        [Parameter(Mandatory=$true)]
        [int]$retentionDays,
        [Parameter(Mandatory=$false)]
        [bool]$onlyWithVersions = $false,
        [Parameter(Mandatory=$false)]
        [bool]$whatIf = $true
    )

    # Set context
    $ctx = New-AzStorageContext `
        -StorageAccountName $accountName `
        -UseConnectedAccount

    # Getting all blobs with versions in the above container
    $blobs = Get-AzStorageBlob `
        -Container $containerName `
        -Context $ctx -IncludeVersion

    if ($onlyWithVersions)
    {
        $blobs = $blobs | Where-Object {$null -ne $_.VersionId}
    }

    # Iterate the list of versions
    foreach ($blob in $blobs)
    {
        # In below section, if this version is not the current version of the blob, version will be deleted. 
        if ($blob.LastModified.UtcDateTime -lt (Get-Date).AddDays((-$retentionDays)))
        {
            Write-Host "Deleting blob: $($blob.Name), Version: $($blob.VersionId)"
            Write-Host "Reason: Blob last modified date $($blob.LastModified.UtcDateTime) is older than $($retentionDays) days"

            if (-not $whatIf)
            {
                # For both calls to Remove-AzStorageBlob, we need to check if the blob has a version or not
                # We also ensure to pass in -Force to remove the blob and all snapshots without needing to prompt for confirmation
                if($null -eq $blob.VersionId -or $onlyWithVersions -eq $false)
                {
                    Remove-AzStorageBlob -Context $ctx -Container $containerName -Blob $blob.Name -Force
                }
                else
                {
                    Remove-AzStorageBlob -Context $ctx -Container $containerName -Blob $blob.Name -VersionId $blob.VersionId -Force
                }
            }
        }
    }
}

# Usage example:
$accountName = "<place-your-storage-name>"
$containerName = "<place-your-container-name>"
$retentionDays = 30

Remove-BlobsWithOrWithoutVersions -accountName $accountName -containerName $containerName -retentionDays $retentionDays -whatIf $true
