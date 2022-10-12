#https://medium.com/shrike-techblog/generate-word-documents-with-powershell-cda654b9cb0e

Param(
	[String]$basePath,
	[String[]]$Include=@("*.cs"),
	[string[]]$ignoreFiles=@(),
	[string[]]$ignorePath=@()
)

function Resolve-RelativePath($path, $fromPath) {
	$path = Resolve-Path $path
	$fromPath = Resolve-Path $fromPath
	$fromUri = new-object -TypeName System.Uri -ArgumentList "$fromPath\"
	$pathUri = new-object -TypeName System.Uri -ArgumentList $path
	return $fromUri.MakeRelativeUri($pathUri).ToString().Replace('/', [System.IO.Path]::DirectorySeparatorChar);
}

Function New-WordText {
    Param (
        [string]$Text,
        [int]$Size = 11,
        [string]$Style = 'Normal',
        [Microsoft.Office.Interop.Word.WdColor]$ForegroundColor = "wdColorAutomatic",
        [switch]$Bold,
        [switch]$Italic,
        [switch]$NoNewLine
    )  
    Try {
        $Selection.Style = $Style
    } Catch {
        Write-Warning "Style: `"$Style`" doesn't exist! Try another name."
        Break
    }
 
    If ($Style -notmatch 'Title|^Heading'){
        $Selection.Font.Size = $Size  
        If ($PSBoundParameters.ContainsKey('Bold')) {
            $Selection.Font.Bold = 1
        } Else {
            $Selection.Font.Bold = 0
        }
        If ($PSBoundParameters.ContainsKey('Italic')) {
            $Selection.Font.Italic = 1
        } Else {
            $Selection.Font.Italic = 0
        }          
        $Selection.Font.Color = $ForegroundColor
    }
 
    $Selection.TypeText($Text)
 
    If (-NOT $PSBoundParameters.ContainsKey('NoNewLine')) {
        $Selection.TypeParagraph()
    }
}

$word = New-Object -ComObject word.application
$word.Visible = $false
$doc = $word.documents.add()
$doc.Styles["Normal"].ParagraphFormat.SpaceAfter = 0
$doc.Styles["Normal"].ParagraphFormat.SpaceBefore = 0
$margin = 36 # 1.26 cm
$doc.PageSetup.LeftMargin = $margin
$doc.PageSetup.RightMargin = $margin
$doc.PageSetup.TopMargin = $margin
$doc.PageSetup.BottomMargin = $margin
$selection = $word.Selection
New-WordText -Text "$($Env:Computername)" -Style 'Title'
New-WordText -Text "Report compiled at $(Get-Date)."

$range = $selection.Range
$toc = $doc.TablesOfContents.Add($range)
$selection.TypeParagraph()

Get-ChildItem -Path $basePath -r -Include $Include | ForEach-Object {
	$filePath = $_.fullname
	$relativePath = Resolve-RelativePath $filePath $basePath
	$fileName = $_.name

	# Fitler out files
	if ($ignoreFiles -contains $fileName) {
		Write-Host "Skipping file $fileName" -ForegroundColor DarkGray
		return
	}
	if (($ignorePath | where { $relativePath -like $_}).Length -gt 0) {
		Write-Host "Skipping path $filePath" -ForegroundColor DarkGray
		return
	}

	$temp = Get-Content $filePath -Encoding UTF8 -Raw

	$selection.Style = "Heading 1"
	$selection.TypeText($relativePath)
	$selection.TypeParagraph()
	$selection.Style = "Normal"
	$selection.TypeText($temp);
	$selection.TypeParagraph()
}

$toc.Update()

$outputPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$outputPath = $outputPath + "\sources.docx"
$doc.SaveAs($outputPath)
$doc.Close()
$word.Quit()