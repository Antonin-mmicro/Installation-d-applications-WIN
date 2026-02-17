$path = "$env:USERPROFILE\Desktop\FTA.zip"
$finalpath = "$env:USERPROFILE\Desktop\FTA\File-Type-Association-main\main.exe"

if (Test-Path $finalpath) {
  Write-Host "File Type Asscociation est déja installé à l'emplacemenet $finalpath"
  exit 1
} else {
  Write-Host "Telechargement en cours..."
}

iwr "https://codeload.github.com/Antonin-mmicro/File-Type-Association/zip/refs/heads/main" -OutFile $path

if (Test-Path $path) {
  Write-Host "Telechargement réussi !"
  Write-Host "Extraction de l'archive en cours..."
} else {
  Write-Host "Un probleme a eu lieu pendant le telechargement : $_"
  Write-Host "Vous pouvez le telecharger manuellement via : https://codeload.github.com/Antonin-mmicro/File-Type-Association/zip/refs/heads/main"
  exit 1
}

Expand-Archive -Path $path -DestinationPath $finalpath -Force

if ($finalpath) {
  Write-Host "Extraction reussi !"
  Write-Host "L'outil est disponible à $finalpath"
  Write-Host "Suppression du fichier zip"
} else {
  Write-Host "Un probleme a lieu pendant l'extraction"
}

Remove-Item -Path $path

if (Test-Path $path) {
  Write-Host "Probleme lors de la suppression du fichier zip : $_"
  Write-Host "Veuillez le faire à la main depuis : $path$"
} else {
  Write-Host "Suppression reussi"
  Write-Host "Programme fini"
} #VERIF ETAT UCPD AVANT LE FILE TYPE ASSOCIATION REQUIS !!!!