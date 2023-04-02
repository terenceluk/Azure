$searchName = "Delete_Sensitive"
$searchNamePurge = "$searchName" + "_Purge"
$typeOfDelete = "Harddelete"
New-ComplianceSearchAction -SearchName $searchName -Purge -PurgeType $typeOfDelete -Confirm:$false -Force

for ($i = 1; $i -le 100; $i++) {
    Write-Host "Executing iteration $i"
    do {
        Start-Sleep -Seconds 1
        $status = Get-ComplianceSearchAction -Identity $SearchNamePurge 
        Write-Host "Status: $($status.Status)"
        if ($status.Status -eq "Completed")
        {
            Write-Host "Status is completed so output results and deleting."
            Get-ComplianceSearchAction -Identity $SearchNamePurge | Format-List Results
            $outfile = "$searchName-purgelog$i.txt"
            Get-ComplianceSearchAction -Identity $SearchNamePurge | Format-List | Out-File $outfile
            Get-ComplianceSearchAction -Identity $SearchNamePurge | Remove-ComplianceSearchAction -Confirm:$false
        }
    } while ($status.Status -ne "Completed")

    try {
        New-ComplianceSearchAction -SearchName $searchName -Purge -PurgeType $typeOfDelete -Confirm:$false -Force
    }
    catch {
        Write-Host "An error occurred while executing the command. Exiting loop."
        break
    }
}
