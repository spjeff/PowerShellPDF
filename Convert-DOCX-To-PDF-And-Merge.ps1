# Load MS Office Interop DLL
Add-Type -Path "C:\Windows\assembly\GAC_MSIL\Microsoft.Office.Interop.Word\15.0.0.0__71e9bce111e9429c\Microsoft.Office.Interop.Word.dll"
Add-Type -Path "C:\Windows\assembly\GAC_MSIL\Microsoft.Office.Interop.Excel\15.0.0.0__71e9bce111e9429c\Microsoft.Office.Interop.Excel.dll"
Add-Type -Path "C:\Windows\assembly\GAC_MSIL\Microsoft.Office.Interop.Publisher\15.0.0.0__71e9bce111e9429c\Microsoft.Office.Interop.Publisher.dll"
Add-Type -Path "C:\Windows\assembly\GAC_MSIL\Microsoft.Office.Interop.Visio\15.0.0.0__71e9bce111e9429c\Microsoft.Office.Interop.Visio.dll"
Add-Type -Path "C:\Windows\assembly\GAC_MSIL\Microsoft.Office.Interop.Visio.SaveAsWeb\15.0.0.0__71e9bce111e9429c\Microsoft.Office.Interop.Visio.SaveAsWeb.dll"
Add-Type -Path "C:\Windows\assembly\GAC_MSIL\Microsoft.Office.Interop.VisOcx\15.0.0.0__71e9bce111e9429c\Microsoft.Office.Interop.VisOcx.dll"

# from https://stuartsplace.com/computing/programming/powershell/merging-files-with-powershell
Function MergePDF($filePattern) {
    Add-Type -Path "DLL\itextsharp.dll"
    $files = Get-ChildItem -Path $filePattern

    # Maximum number of pages.
    $maxPages = 0

    # Files to process with number of pages sorted dictionary.
    $filesToProcess = @{}

    # Collect page count information for each PDF file.
    foreach ($file in $files) {
        $file.FullName

        # Assign current PDF to a reader object.
        $pdfReader = New-Object iTextSharp.text.pdf.PdfReader -ArgumentList $file.FullName

        # Assign the number of pages to the maximum if greater
        # than current value.
        if ($pdfReader.NumberOfPages -gt $maxPages) {
            $maxPages = $pdfReader.NumberOfPages
        }

        # Add the file information to the sorted dictionary.
        $filesToProcess.Add($file.FullName, $pdfReader.NumberOfPages)

        # Dispose of the reader object.
        $pdfReader.Dispose()
    }

    # If there are PDFs to merge, process them.
    if ($maxPages -gt 0 -and $filesToProcess.Count -gt 1) {

        # Create and open new document.
        $output = [System.IO.Path]::Combine($filePath, 'Output-Combined.pdf');
        $fileStream = New-Object System.IO.FileStream($output, [System.IO.FileMode]::OpenOrCreate);
        $document = New-Object iTextSharp.text.Document
        $writer = New-Object iTextSharp.text.pdf.PdfSmartCopy($document, $fileStream)
        $document.Open()

        # Process PDF files up to the maximum number of pages.
        for ($pageIndex = 1; $pageIndex -le $maxPages; $pageIndex++) {
            # Add the desired page from each PDF to the new PDF.
            foreach ($pdfFile in $filesToProcess.GetEnumerator()) {
                # Check if current file has the desired page to merge.
                if ($pageIndex -le $pdfFile.Value) {

                    # Assign the current PDF to a reader object.
                    $pdfReader = New-Object iTextSharp.text.pdf.PdfReader -ArgumentList $pdfFile.Name

                    # Extract the desired page.
                    $page = $writer.GetImportedPage($pdfReader, $pageIndex)

                    # Add the extracted page to the combined PDF.
                    $writer.AddPage($page)

                    # Dispose of the reader object.
                    $pdfReader.Dispose()
                }
            }
        }

        # Dispose of objects to clean up.
        $document.Dispose()
        $writer.Dispose()
        $filestream.Dispose()

        # Feedback that file merge has been successful.
        Write-Host "$($filesToProcess.Count) PDF files merged successfully."
    }

}

# from https://github.com/escottj/Doc2PDF/blob/master/Doc2PDF.ps1
#Define Office Formats
$Wrd_Array = @('*.DOCX', '*.DOC', '*.ODT', '*.RTF', '*.TXT', '*.WPD')
$Exl_Array = @('*.XLSX', '*.XLS', '*.ODS', '*.CSV')
$Pow_Array = @('*.PPTX', '*.PPT', '*.ODP')
$Pub_Array = @('*.PUB')
$Vis_Array = @('*.VSDX', '*.VSD', '*.VSSX', '*.VSS')
$Off_Array = $Wrd_Array + $Exl_Array + $Pow_Array + $Pub_Array + $Vis_Array

 
#Convert Word to PDF
Function Wrd-PDF($f, $p) {
    $f.Fullname
    $Wrd = New-Object -ComObject "Word.Application"
    $Version = $Wrd.Version
    $Doc = $Wrd.Documents.Open($f)
    #Check Version of Office Installed
    If ($Version -eq '16.0' -Or $Version -eq '15.0') {
        try {
            $Doc.SaveAs($p, 17)
        }
        catch {}
        $Doc.Close($False)
    }
    ElseIf ($Version -eq '14.0') {
        $Doc.SaveAs([ref] $p, [ref] 17)
        $Doc.Close([ref]$False)
    }
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
    $Wrd.Quit() | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Wrd) | Out-Null
}
 
#Convert Excel to PDF
Function Exl-PDF($f, $p) {
    $f.Fullname
    $Exl = New-Object -ComObject "Excel.Application"
    $Doc = $Exl.Workbooks.Open($f)
    $Doc.ExportAsFixedFormat([Microsoft.Office.Interop.Excel.XlFixedFormatType]::xlTypePDF, $p)
    $Doc.Close($False)
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
    $Exl.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Exl) | Out-Null
}
 
#Convert PowerPoint to PDF
Function Pow-PDF($f, $p) {
    $f.Fullname
    $Pow = New-Object -ComObject "PowerPoint.Application"
    $Doc = $Pow.Presentations.Open($f, $True, $True, $False)
    $Doc.SaveAs($p, 32)
    $Doc.Close()
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
    $Pow.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Pow) | Out-Null
}
 
#Convert Publisher to PDF
Function Pub-PDF($f, $p) {
    $f.Fullname
    $Pub = New-Object -ComObject "Publisher.Application"
    $Doc = $Pub.Open($f)
    $Doc.ExportAsFixedFormat([Microsoft.Office.Interop.Publisher.PbFixedFormatType]::pbFixedFormatTypePDF, $p)
    $Doc.Close()
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
    $Pub.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Pub) | Out-Null
}
 
#Convert Visio to PDF
Function Vis-PDF($f, $p) {
    $f.Fullname
    $Vis = New-Object -ComObject "Visio.Application"
    $Doc = $Vis.Documents.Open($f)
    # from https://docs.microsoft.com/en-us/office/vba/api/visio.visfixedformattypes
    # from https://docs.microsoft.com/en-us/office/vba/api/visio.document.exportasfixedformat
    # Params = 1, $filename, 1, 0
    # 1=visFixedFormatPDF
    # 1=visDocExIntentPrint
    # 0=visPrintAll
    $Doc.ExportAsFixedFormat(1, $p, 1, 0)
    $Doc.Close()
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
    $Vis.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Vis) | Out-Null
}
 
#Check for Word Formats
Function Wrd-Chk($f, $e, $p) {
    $f.Fullname
    $f = [string]$f
    For ($i = 0; $i -le $Wrd_Array.Length; $i++) {
        $Temp = [string]$Wrd_Array[$i]
        $Temp = $Temp.TrimStart('*')
        If ($e -eq $Temp) {
            Wrd-PDF $f $p
        }
    }
}
 
#Check for Excel Formats
Function Exl-Chk($f, $e, $p) {
    $f.Fullname
    $f = [string]$f
    For ($i = 0; $i -le $Exl_Array.Length; $i++) {
        $Temp = [string]$Exl_Array[$i]
        $Temp = $Temp.TrimStart('*')
        If ($e -eq $Temp) {
            Exl-PDF $f $p
        }
    }
}
 
#Check for PowerPoint Formats
Function Pow-Chk($f, $e, $p) {
    $f.Fullname
    $f = [string]$f
    For ($i = 0; $i -le $Pow_Array.Length; $i++) {
        $Temp = [string]$Pow_Array[$i]
        $Temp = $Temp.TrimStart('*')
        If ($e -eq $Temp) {
            Pow-PDF $f $p
        }
    }
}
 
#Check for Publisher Formats
Function Pub-Chk($f, $e, $p) {
    $f.Fullname
    $f = [string]$f
    For ($i = 0; $i -le $Pub_Array.Length; $i++) {
        $Temp = [string]$Pub_Array[$i]
        $Temp = $Temp.TrimStart('*')
        If ($e -eq $Temp) {
            Pub-PDF $f $p
        }
    }
}
 
#Check for Visio Formats
Function Vis-Chk($f, $e, $p) {
    $f.Fullname
    $f = [string]$f
    For ($i = 0; $i -le $Vis_Array.Length; $i++) {
        $Temp = [string]$Vis_Array[$i]
        $Temp = $Temp.TrimStart('*')
        If ($e -eq $Temp) {
            Vis-PDF $f $p
        }
    }
}
 
#Check if input is file or directory
Function ConvertFolder($filePattern) {
    $ExtChk = [System.IO.Path]::GetExtension($filePattern)
    If ($ExtChk -eq '') {
        $Files = Get-ChildItem -path $Input -include $Off_Array -recurse
        ForEach ($File in $Files) {
            ConvertFile $File
        }
    }
    Else {
        $File = $filePattern
        ConvertFile $File
    } 
}

Function ConvertFile($Ext, $filepath) {
    # Single file variable lookup
    $Path = [System.IO.Path]::GetDirectoryName($File)
    $Filename = [System.IO.Path]::GetFileNameWithoutExtension($File)
    $Ext = [System.IO.Path]::GetExtension($File)
    $PDF = $Path + '\' + $Filename + '.pdf'
    ConvertFile $Ext $Filename

    # Extension support
    switch ($Ext) {
        ".DOC" { Wrd-Chk $File $Ext $PDF ; break; }
        ".DOCX" { Wrd-Chk $File $Ext $PDF ; break; }
        ".RTF" { Wrd-Chk $File $Ext $PDF ; break; }
        ".TXT" { Wrd-Chk $File $Ext $PDF ; break; }
        ".CSV" { Exl-Chk $File $Ext $PDF ; break; }
        ".XLS" { Exl-Chk $File $Ext $PDF ; break; }
        ".XLSX" { Exl-Chk $File $Ext $PDF ; break; }
        ".PPT" { Pow-Chk $File $Ext $PDF ; break; }
        ".PPTX" { Pow-Chk $File $Ext $PDF ; break; }
        ".PUB" { Pub-Chk $File $Ext $PDF ; break; }
        ".VSD" { Vis-Chk $File $Ext $PDF ; break; }
        ".VSDX" { Vis-Chk $File $Ext $PDF ; break; }
        ".VSS" { Vis-Chk $File $Ext $PDF ; break; }
    }
}

# Main
function Main() {
    Write-Host "CONVERT MS OFFICE TO PDF" -Fore Yellow
    Convert "INPUT"

    Write-Host "MERGE PDFS TO COMBINED.PDF" -Fore Yellow
    MergePDF "INPUT\*.pdf"
}
Main