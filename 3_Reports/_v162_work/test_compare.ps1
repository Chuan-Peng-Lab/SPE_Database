$ErrorActionPreference = 'Stop'
$WR = "D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing"
$orig = Join-Path $WR "SPE_数据库_v16.1.docx"
$rev  = Join-Path $WR "SPE_数据库_v16.2.docx"
$out  = "D:\GitHub_programe\GitHub\SPE_Database\3_Reports\_v162_work\_compare_test.docx"

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$word.UserName = "czx"
$word.UserInitials = "czx"

try {
    $d1 = $word.Documents.Open($orig, $false, $true)
    $d2 = $word.Documents.Open($rev, $false, $true)
    # CompareDocuments(Original, Revised, Destination=2 new, Granularity=0 word,
    #   CompareFormatting=F, CompareCaseChanges=F, CompareWhitespace=F, CompareTables=T,
    #   CompareHeaders=F, CompareFootnotes=F, CompareTextboxes=F, CompareFields=F,
    #   CompareComments=F, CompareMoves=T, RevisedAuthor="czx", IgnoreAllComparisonWarnings=T)
    $cmp = $word.CompareDocuments($d1, $d2, 2, 0, $false, $false, $false, $true,
                                  $false, $false, $false, $false, $false, $true,
                                  "czx", $true)
    Write-Output ("revisions: " + $cmp.Revisions.Count)
    $authors = @{}
    foreach ($r in $cmp.Revisions) {
        $a = [string]$r.Author
        if ($authors.ContainsKey($a)) { $authors[$a]++ } else { $authors[$a] = 1 }
    }
    foreach ($k in $authors.Keys) { Write-Output ("  author '" + $k + "' -> " + $authors[$k]) }
    $types = @{}
    foreach ($r in $cmp.Revisions) {
        $t = [string]$r.Type
        if ($types.ContainsKey($t)) { $types[$t]++ } else { $types[$t] = 1 }
    }
    foreach ($k in $types.Keys) { Write-Output ("  type " + $k + " -> " + $types[$k]) }

    $cmp.SaveAs2($out, 16)
    Write-Output ("saved -> " + $out)
    $cmp.Close($false)
    $d1.Close($false); $d2.Close($false)
} finally {
    $word.Quit()
}
