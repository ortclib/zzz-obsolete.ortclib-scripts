
#param([string]$input)
#param([string]$replace)
#param([string]$replaceWith)
#param([string]$output)

$input=$args[0]
$replace=$args[1]
$replaceWith=$args[2]
$output=$args[3]

(Get-Content $input) | ForEach-Object { $_ -replace $replace, $replaceWith } | Set-Content $output