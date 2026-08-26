[CmdletBinding()]
param(
    [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}
Set-Location -LiteralPath $RepositoryRoot

$labFolders = Get-ChildItem -Directory | Where-Object { $_.Name -match '^Lab\s*\d+' } |
    Sort-Object {
        if ($_.Name -match '\d+') { [int]$Matches[0] } else { [int]::MaxValue }
    }

function Get-LabLabel([string]$Name) {
    if ($Name -match '(\d+)') { return "Lab $($Matches[1])" }
    return $Name
}

$rows = foreach ($lab in $labFolders) {
    $notebooks = @(Get-ChildItem -LiteralPath $lab.FullName -File -Filter '*.ipynb')
    $documents = @(Get-ChildItem -LiteralPath $lab.FullName -File | Where-Object {
        $_.Extension -in '.docx', '.pdf'
    })
    $parts = @()
    if ($notebooks.Count) { $parts += 'Jupyter notebook' }
    if ($documents.Count) { $parts += 'output document' }
    if (-not $parts.Count) { $parts += 'lab materials' }
    "| $(Get-LabLabel $lab.Name) | $($parts -join ' and ') |"
}

$tableRows = if ($rows) { $rows -join [Environment]::NewLine } else { '| — | No lab folders found |' }
$readme = @"
# Computer Vision

MCA Semester 3 Computer Vision laboratory work, including Jupyter notebooks, result documents, and image assets.

## Contents

| Lab | Materials |
| --- | --- |
$tableRows

## Getting started

Open a lab notebook in Jupyter Notebook or JupyterLab. The image files in the repository root are used as sample inputs for the exercises.

## License

This project is released under the [MIT License](LICENSE).

> This file is automatically regenerated from the repository's lab folders by GitHub Actions. Edit `scripts/Update-RepoMetadata.ps1` to change its template.
"@

[System.IO.File]::WriteAllText((Join-Path $RepositoryRoot 'README.md'), $readme.TrimEnd() + [Environment]::NewLine)

$labels = @($labFolders | ForEach-Object { Get-LabLabel $_.Name })
$labSummary = if ($labels.Count) { $labels -join ', ' } else { 'laboratory exercises' }
$description = "MCA Semester 3 Computer Vision lab work: $labSummary."
[System.IO.File]::WriteAllText((Join-Path $RepositoryRoot '.github/repository-description.txt'), $description + [Environment]::NewLine)
