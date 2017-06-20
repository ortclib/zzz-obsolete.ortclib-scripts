
#param([string]$path)
#param([string]$fileNameFilter)
#param([string]$searchFor)
#param([string]$replaceWith)

$path=$args[0]
$fileNameFilter=$args[1]
$searchFor=$args[2]
$replaceWith=$args[3]

$configFiles = Get-ChildItem $path $fileNameFilter -rec
foreach ($file in $configFiles)
{
    (Get-Content $file.PSPath) |
    Foreach-Object { $_ -replace $searchFor, $replaceWith } |
    Set-Content $file.PSPath
}
