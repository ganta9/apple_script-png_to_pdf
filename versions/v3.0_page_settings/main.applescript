-- ===================================================================
-- PNG to PDF 変換AppleScript (v3.0 ページ設定機能付き)
-- ===================================================================

-- 基本設定
set sourceFolder to "/Users/gantaku/本/_screenshot/" -- PNG画像があるフォルダ
set saveFolder to "/Users/gantaku/本/" -- PDF保存先フォルダ
set imageQuality to "85" -- 画質 (1-100, 100が最高画質)
set fitToPage to true -- 画像をページサイズに合わせる
set maxFileSize to 200 -- 最大ファイルサイズ (MB)

-- 設定ダイアログ関数
on showPageSettingsDialog()
	-- ページサイズの選択肢
	set pageSizeOptions to {"A4 (210×297mm)", "A3 (297×420mm)", "A5 (148×210mm)", "Letter (216×279mm)", "Legal (216×356mm)", "Tabloid (279×432mm)"}
	set orientationOptions to {"縦 (Portrait)", "横 (Landscape)"}
	
	-- ページサイズ選択
	set pageSizeChoice to choose from list pageSizeOptions with title "ページサイズ選択" with prompt "PDFのページサイズを選択してください:" default items {"A4 (210×297mm)"}
	if pageSizeChoice is false then error "キャンセルされました"
	
	-- 向き選択
	set orientationChoice to choose from list orientationOptions with title "ページの向き選択" with prompt "ページの向きを選択してください:" default items {"縦 (Portrait)"}
	if orientationChoice is false then error "キャンセルされました"
	
	-- 選択結果を解析
	set pageSize to item 1 of pageSizeChoice
	set orientation to item 1 of orientationChoice
	
	-- 内部形式に変換
	set pageSizeKey to ""
	if pageSize contains "A4" then
		set pageSizeKey to "A4"
	else if pageSize contains "A3" then
		set pageSizeKey to "A3"
	else if pageSize contains "A5" then
		set pageSizeKey to "A5"
	else if pageSize contains "Letter" then
		set pageSizeKey to "Letter"
	else if pageSize contains "Legal" then
		set pageSizeKey to "Legal"
	else if pageSize contains "Tabloid" then
		set pageSizeKey to "Tabloid"
	end if
	
	set orientationKey to ""
	if orientation contains "縦" then
		set orientationKey to "portrait"
	else
		set orientationKey to "landscape"
	end if
	
	return {pageSizeKey, orientationKey}
end showPageSettingsDialog

-- ===================================================================
-- メイン処理
-- ===================================================================

try
	-- PDFファイル名の入力
	set dialogResult to display dialog "保存するPDFファイル名を入力してください(.pdfは自動で付きます):" default answer "変換結果" with title "PDFファイル名の設定"
	set fileNameInput to text returned of dialogResult
	if fileNameInput is "" then
		-- ファイル名が空の場合はエラーとして処理を中止
		error "ファイル名が入力されませんでした"
	end if
	-- .pdf拡張子を自動で付ける
	if fileNameInput ends with ".pdf" then
		set baseFileName to text 1 thru -5 of fileNameInput
	else
		set baseFileName to fileNameInput
	end if
	
	-- ページ設定ダイアログの表示
	set pageSettings to my showPageSettingsDialog()
	set pageSize to item 1 of pageSettings
	set orientation to item 2 of pageSettings
	
	-- まずはImageMagickのパスを確認
	set convertPath to ""
	try
		set convertPath to do shell script "if [ -f /opt/homebrew/bin/convert ]; then echo '/opt/homebrew/bin/convert'; fi"
	end try
	if convertPath is "" then
		try
			set convertPath to do shell script "if [ -f /usr/local/bin/convert ]; then echo '/usr/local/bin/convert'; fi"
		end try
	end if
	if convertPath is "" then
		try
			set convertPath to do shell script "which convert 2>/dev/null || echo ''"
		end try
	end if
	
	if convertPath is "" then
		display dialog "ImageMagickが見つかりません。" & return & return & "以下の手順でインストールしてください：" & return & return & "1. ターミナルを開く" & return & "2. 以下のコマンドを実行" & return & "      brew install imagemagick" & return & return & "3. インストール後もう一度このスクリプトを実行" buttons {"OK"} default button "OK" with icon stop
		return
	end if
	
	-- 保存先フォルダの作成
	do shell script "mkdir -p " & quoted form of saveFolder
	
	-- PNGファイルのリストを取得
	set pngFiles to do shell script "cd " & quoted form of sourceFolder & " && ls -1 *.png 2>/dev/null | sort -V || echo ''"
	
	if pngFiles is "" then
		display dialog "PNGファイルが見つかりません" & return & return & "フォルダ: " & sourceFolder & return & "このフォルダにPNG画像があることを確認してください。" buttons {"OK"} default button "OK" with icon caution
		return
	end if
	
	-- ファイル数をカウント
	set fileList to paragraphs of pngFiles
	set fileCount to count of fileList
	
	-- 処理確認の表示
	display dialog "PNG→PDF変換設定（200MB分割対応）" & return & return & "ファイル数: " & fileCount & "件" & return & "画質: " & imageQuality & "%" & return & "ページサイズ: " & pageSize & return & "向き: " & orientation & return & "出力ファイル名: " & baseFileName & return & "最大ファイル: " & maxFileSize & "MB" buttons {"キャンセル", "変換開始"} default button "変換開始"
	
	-- 分割変換処理を実行
	set createdFiles to my splitConvertProcess(fileList, baseFileName, sourceFolder, saveFolder, convertPath, imageQuality, pageSize, orientation, fitToPage, maxFileSize)
	
	-- 結果の表示とPNG削除処理
	if (count of createdFiles) > 0 then
		set pngMoveStatus to "移動しませんでした"
		display dialog "変換済みのPNGファイルをゴミ箱に移動しますか？" with title "ファイルの移動" buttons {"いいえ", "はい"} default button "はい"
		if button returned of result is "はい" then
			tell application "Finder"
				try
					set sourceAlias to POSIX file sourceFolder as alias
					move (every file of sourceAlias whose name extension is "png") to trash
					set pngMoveStatus to "ゴミ箱に移動しました"
				on error
					set pngMoveStatus to "ファイルの移動に失敗しました"
				end try
			end tell
		end if
		
		-- 作成されたファイル情報表示
		set resultMessage to "PDF変換が完了しました！" & return & return
		set resultMessage to resultMessage & "作成されたファイル数: " & (count of createdFiles) & "件" & return & return
		repeat with i from 1 to count of createdFiles
			set fileInfo to item i of createdFiles
			set resultMessage to resultMessage & "■ " & (item 1 of fileInfo) & " (" & (item 2 of fileInfo) & ")" & return
		end repeat
		set resultMessage to resultMessage & return & "■ 保存場所: " & saveFolder & return & "■ 元ファイル: " & pngMoveStatus
		
		display dialog resultMessage buttons {"OK"} default button "OK" with icon note
	else
		display dialog "PDFの作成に失敗しました。" & return & "設定を確認してください。" buttons {"OK"} default button "OK" with icon stop
	end if
	
on error errMsg number errNum
	if errNum is -128 then
		-- ユーザーによるキャンセル
		display dialog "処理をキャンセルしました。" buttons {"OK"} default button "OK" with icon caution
	else
		-- その他のエラー
		display dialog "エラーが発生しました: " & return & return & errMsg & return & return & "エラー番号: " & errNum buttons {"OK"} default button "OK" with icon stop
	end if
end try

-- ===================================================================
-- 分割変換処理関数
-- ===================================================================
on splitConvertProcess(fileList, baseFileName, sourceFolder, saveFolder, convertPath, imageQuality, pageSize, orientation, fitToPage, maxFileSize)
	set createdFiles to {}
	set currentBatch to {}
	set currentPartNum to 1
	set totalFiles to count of fileList
	set processedFiles to 0
	
	repeat with i from 1 to totalFiles
		set currentFile to item i of fileList
		set currentBatch to currentBatch & {currentFile}
		
		-- バッチサイズが10ファイルになったか、最後のファイル処理
		if (count of currentBatch) ≥ 10 or i = totalFiles then
			-- 現在のバッチでPDFを作成
			set currentFileName to baseFileName & "_part" & (currentPartNum as string) & ".pdf"
			if currentPartNum = 1 and totalFiles ≤ 10 then
				-- ファイルが少ない場合は連番なし
				set currentFileName to baseFileName & ".pdf"
			end if
			
			set tempPdfPath to saveFolder & currentFileName
			
			-- ImageMagickコマンドの構築
			set convertCmd to "cd " & quoted form of sourceFolder & " && " & quoted form of convertPath
			if fitToPage then
				if orientation is "portrait" then
					if pageSize is "A4" then
						set convertCmd to convertCmd & " -page A4"
					else if pageSize is "A3" then
						set convertCmd to convertCmd & " -page A3"
					else if pageSize is "A5" then
						set convertCmd to convertCmd & " -page A5"
					else if pageSize is "Letter" then
						set convertCmd to convertCmd & " -page Letter"
					else if pageSize is "Legal" then
						set convertCmd to convertCmd & " -page Legal"
					else if pageSize is "Tabloid" then
						set convertCmd to convertCmd & " -page Tabloid"
					end if
				else
					-- 横向きの場合はページサイズ設定なしで、後でPDFを回転
					-- 一旦縦向きで作成してからPDFを回転させる方法を使用
					if pageSize is "A4" then
						set convertCmd to convertCmd & " -page A4"
					else if pageSize is "A3" then
						set convertCmd to convertCmd & " -page A3"
					else if pageSize is "A5" then
						set convertCmd to convertCmd & " -page A5"
					else if pageSize is "Letter" then
						set convertCmd to convertCmd & " -page Letter"
					else if pageSize is "Legal" then
						set convertCmd to convertCmd & " -page Legal"
					else if pageSize is "Tabloid" then
						set convertCmd to convertCmd & " -page Tabloid"
					end if
				end if
			end if
			
			-- バッチファイルリストの構築
			set batchFilesStr to ""
			repeat with j from 1 to count of currentBatch
				if j > 1 then set batchFilesStr to batchFilesStr & " "
				set batchFilesStr to batchFilesStr & quoted form of (item j of currentBatch)
			end repeat
			
			set convertCmd to convertCmd & " -quality " & imageQuality & " -compress jpeg " & batchFilesStr & " " & quoted form of tempPdfPath
			
			try
				-- 変換実行
				do shell script convertCmd
				delay 1
				
				-- ファイルサイズをチェック
				set fileSizeMB to my getFileSizeMB(tempPdfPath)
				
				if fileSizeMB > maxFileSize then
					-- ファイルサイズが大きすぎる場合は小さなバッチに分割
					do shell script "rm -f " & quoted form of tempPdfPath
					set smallerBatches to my createSmallerBatches(currentBatch, baseFileName, currentPartNum, sourceFolder, saveFolder, convertPath, imageQuality, pageSize, orientation, fitToPage, maxFileSize)
					set createdFiles to createdFiles & smallerBatches
					set currentPartNum to currentPartNum + (count of smallerBatches)
				else
					-- ファイルサイズが適切な場合
					-- 横向きの場合はPDFを回転
					if orientation is "landscape" then
						try
							-- pdftk を使用してPDFを90度回転
							set rotatedPdfPath to saveFolder & "temp_rotated_" & currentFileName
							do shell script "pdftk " & quoted form of tempPdfPath & " cat 1-endeast output " & quoted form of rotatedPdfPath
							-- 元のファイルを削除して回転済みファイルをリネーム
							do shell script "rm -f " & quoted form of tempPdfPath
							do shell script "mv " & quoted form of rotatedPdfPath & " " & quoted form of tempPdfPath
						on error
							-- pdftk が利用できない場合はPythonのPyPDF2を試行
							try
								set pythonScript to "
import sys
from PyPDF2 import PdfFileReader, PdfFileWriter

input_pdf = '" & tempPdfPath & "'
output_pdf = input_pdf

with open(input_pdf, 'rb') as infile:
    reader = PdfFileReader(infile)
    writer = PdfFileWriter()
    
    for page_num in range(reader.numPages):
        page = reader.getPage(page_num)
        page.rotateClockwise(90)
        writer.addPage(page)
    
    with open(output_pdf + '.tmp', 'wb') as outfile:
        writer.write(outfile)

import os
os.rename(output_pdf + '.tmp', output_pdf)
"
								do shell script "python3 -c " & quoted form of pythonScript
							end try
						end try
					end if
					
					set fileSize to do shell script "ls -lh " & quoted form of tempPdfPath & " | awk '{print $5}'"
					set createdFiles to createdFiles & {{currentFileName, fileSize}}
					set currentPartNum to currentPartNum + 1
				end if
				
				set processedFiles to processedFiles + (count of currentBatch)
				
				-- 進捗表示
				if totalFiles > 10 then
					display dialog "変換中... (" & processedFiles & "/" & totalFiles & " ファイル処理中)" giving up after 1
				end if
				
			on error
				-- 変換失敗時の処理
				try
					do shell script "rm -f " & quoted form of tempPdfPath
				end try
			end try
			
			-- 次のバッチの準備
			set currentBatch to {}
		end if
	end repeat
	
	return createdFiles
end splitConvertProcess

-- ===================================================================
-- ファイルサイズ取得関数（MB単位で取得）
-- ===================================================================
on getFileSizeMB(filePath)
	try
		set fileSizeBytes to do shell script "stat -f%z " & quoted form of filePath
		return fileSizeBytes / 1024 / 1024
	on error
		return 0
	end try
end getFileSizeMB

-- ===================================================================
-- より小さなバッチ作成関数
-- ===================================================================
on createSmallerBatches(originalBatch, baseFileName, startPartNum, sourceFolder, saveFolder, convertPath, imageQuality, pageSize, orientation, fitToPage, maxFileSize)
	set createdFiles to {}
	set batchSize to (count of originalBatch) div 2
	if batchSize < 1 then set batchSize to 1
	
	set currentBatch to {}
	set currentPartNum to startPartNum
	
	repeat with i from 1 to count of originalBatch
		set currentBatch to currentBatch & {item i of originalBatch}
		
		if (count of currentBatch) ≥ batchSize or i = (count of originalBatch) then
			set currentFileName to baseFileName & "_part" & (currentPartNum as string) & ".pdf"
			set tempPdfPath to saveFolder & currentFileName
			
			-- ImageMagickコマンドの構築
			set convertCmd to "cd " & quoted form of sourceFolder & " && " & quoted form of convertPath
			if fitToPage then
				if orientation is "portrait" then
					if pageSize is "A4" then
						set convertCmd to convertCmd & " -page A4"
					else if pageSize is "A3" then
						set convertCmd to convertCmd & " -page A3"
					else if pageSize is "A5" then
						set convertCmd to convertCmd & " -page A5"
					else if pageSize is "Letter" then
						set convertCmd to convertCmd & " -page Letter"
					else if pageSize is "Legal" then
						set convertCmd to convertCmd & " -page Legal"
					else if pageSize is "Tabloid" then
						set convertCmd to convertCmd & " -page Tabloid"
					end if
				else
					-- 横向きの場合はページサイズ設定なしで、後でPDFを回転
					-- 一旦縦向きで作成してからPDFを回転させる方法を使用
					if pageSize is "A4" then
						set convertCmd to convertCmd & " -page A4"
					else if pageSize is "A3" then
						set convertCmd to convertCmd & " -page A3"
					else if pageSize is "A5" then
						set convertCmd to convertCmd & " -page A5"
					else if pageSize is "Letter" then
						set convertCmd to convertCmd & " -page Letter"
					else if pageSize is "Legal" then
						set convertCmd to convertCmd & " -page Legal"
					else if pageSize is "Tabloid" then
						set convertCmd to convertCmd & " -page Tabloid"
					end if
				end if
			end if
			
			-- バッチファイルリストの構築
			set batchFilesStr to ""
			repeat with j from 1 to count of currentBatch
				if j > 1 then set batchFilesStr to batchFilesStr & " "
				set batchFilesStr to batchFilesStr & quoted form of (item j of currentBatch)
			end repeat
			
			set convertCmd to convertCmd & " -quality " & imageQuality & " -compress jpeg " & batchFilesStr & " " & quoted form of tempPdfPath
			
			try
				do shell script convertCmd
				delay 1
				
				set fileSizeMB to my getFileSizeMB(tempPdfPath)
				
				if fileSizeMB > maxFileSize and (count of currentBatch) > 1 then
					-- まだ大きすぎる場合は再帰的に分割
					do shell script "rm -f " & quoted form of tempPdfPath
					set recursiveBatches to my createSmallerBatches(currentBatch, baseFileName, currentPartNum, sourceFolder, saveFolder, convertPath, imageQuality, pageSize, orientation, fitToPage, maxFileSize)
					set createdFiles to createdFiles & recursiveBatches
					set currentPartNum to currentPartNum + (count of recursiveBatches)
				else
					-- ファイルサイズが適切または単一ファイル
					-- 横向きの場合はPDFを回転
					if orientation is "landscape" then
						try
							-- pdftk を使用してPDFを90度回転
							set rotatedPdfPath to saveFolder & "temp_rotated_" & currentFileName
							do shell script "pdftk " & quoted form of tempPdfPath & " cat 1-endeast output " & quoted form of rotatedPdfPath
							-- 元のファイルを削除して回転済みファイルをリネーム
							do shell script "rm -f " & quoted form of tempPdfPath
							do shell script "mv " & quoted form of rotatedPdfPath & " " & quoted form of tempPdfPath
						on error
							-- pdftk が利用できない場合はPythonのPyPDF2を試行
							try
								set pythonScript to "
import sys
from PyPDF2 import PdfFileReader, PdfFileWriter

input_pdf = '" & tempPdfPath & "'
output_pdf = input_pdf

with open(input_pdf, 'rb') as infile:
    reader = PdfFileReader(infile)
    writer = PdfFileWriter()
    
    for page_num in range(reader.numPages):
        page = reader.getPage(page_num)
        page.rotateClockwise(90)
        writer.addPage(page)
    
    with open(output_pdf + '.tmp', 'wb') as outfile:
        writer.write(outfile)

import os
os.rename(output_pdf + '.tmp', output_pdf)
"
								do shell script "python3 -c " & quoted form of pythonScript
							end try
						end try
					end if
					
					set fileSize to do shell script "ls -lh " & quoted form of tempPdfPath & " | awk '{print $5}'"
					set createdFiles to createdFiles & {{currentFileName, fileSize}}
					set currentPartNum to currentPartNum + 1
				end if
			on error
				try
					do shell script "rm -f " & quoted form of tempPdfPath
				end try
			end try
			
			set currentBatch to {}
		end if
	end repeat
	
	return createdFiles
end createSmallerBatches