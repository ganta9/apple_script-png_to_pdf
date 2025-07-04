-- ============================================
-- PNG画像をPDFに変換するAppleScript (200MB分割対応版)
-- ============================================

-- 詳細設定
set sourceFolder to "/Users/gantaku/本/_screenshot/" -- PNG画像フォルダ
set saveFolder to "/Users/gantaku/本/" -- PDF保存先フォルダ
set imageQuality to "85" -- 画質 (1-100, 100が最高画質)
set pageSize to "A4" -- ページサイズ (A4, Letter, Legal など)
set fitToPage to true -- 画像をページサイズに合わせる
set maxFileSize to 200 -- 最大ファイルサイズ (MB)

-- ============================================
-- メイン処理
-- ============================================

try
	-- PDFファイル名の入力を求める
	set dialogResult to display dialog "保存するPDFファイル名を入力してください（.pdfは不要です）:" default answer "名称未設定" with title "PDFファイル名の設定"
	set fileNameInput to text returned of dialogResult
	if fileNameInput is "" then
		-- ファイル名が空の場合はエラーとして処理を中断
		error "ファイル名が入力されませんでした。"
	end if
	-- .pdf拡張子を自動で付与
	if fileNameInput ends with ".pdf" then
		set baseFileName to text 1 thru -5 of fileNameInput
	else
		set baseFileName to fileNameInput
	end if
	
	-- まずImageMagickのパスを確認
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
		display dialog "ImageMagickが見つかりません。" & return & return & "以下の手順でインストールしてください：" & return & return & "1. ターミナルを開く" & return & "2. 以下のコマンドを実行：" & return & "   brew install imagemagick" & return & return & "3. インストール完了後、再度このスクリプトを実行" buttons {"OK"} default button "OK" with icon stop
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
	
	-- 処理内容の確認
	display dialog "PNG→PDF変換設定（200MB分割対応）" & return & return & "ファイル数: " & fileCount & " 個" & return & "画質: " & imageQuality & "%" & return & "ページサイズ: " & pageSize & return & "基準ファイル名: " & baseFileName & return & "最大サイズ: " & maxFileSize & "MB" buttons {"キャンセル", "変換開始"} default button "変換開始"
	
	-- 分割変換処理を開始
	set createdFiles to my splitConvertProcess(fileList, baseFileName, sourceFolder, saveFolder, convertPath, imageQuality, pageSize, fitToPage, maxFileSize)
	
	-- 結果の確認とPNG削除処理
	if (count of createdFiles) > 0 then
		set pngMoveStatus to "移動しませんでした"
		display dialog "変換元のPNGファイルをゴミ箱に移動しますか？" with title "ファイルの後処理" buttons {"いいえ", "はい"} default button "はい"
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
		
		-- 作成されたファイル情報を表示
		set resultMessage to "PDF変換が完了しました！" & return & return
		set resultMessage to resultMessage & "作成されたファイル数: " & (count of createdFiles) & " 個" & return & return
		repeat with i from 1 to count of createdFiles
			set fileInfo to item i of createdFiles
			set resultMessage to resultMessage & "📄 " & (item 1 of fileInfo) & " (" & (item 2 of fileInfo) & ")" & return
		end repeat
		set resultMessage to resultMessage & return & "📁 保存場所: " & saveFolder & return & "🗑️ 元ファイル: " & pngMoveStatus
		
		display dialog resultMessage buttons {"OK"} default button "OK" with icon note
	else
		display dialog "PDFの作成に失敗しました。" & return & "エラーログを確認してください。" buttons {"OK"} default button "OK" with icon stop
	end if
	
on error errMsg number errNum
	if errNum is -128 then
		-- ユーザーによるキャンセル
		display dialog "処理をキャンセルしました。" buttons {"OK"} default button "OK" with icon caution
	else
		-- その他のエラー
		display dialog "エラーが発生しました:" & return & return & errMsg & return & return & "エラー番号: " & errNum buttons {"OK"} default button "OK" with icon stop
	end if
end try

-- ============================================
-- 分割変換処理関数
-- ============================================
on splitConvertProcess(fileList, baseFileName, sourceFolder, saveFolder, convertPath, imageQuality, pageSize, fitToPage, maxFileSize)
	set createdFiles to {}
	set currentBatch to {}
	set currentPartNum to 1
	set totalFiles to count of fileList
	set processedFiles to 0
	
	repeat with i from 1 to totalFiles
		set currentFile to item i of fileList
		set currentBatch to currentBatch & {currentFile}
		
		-- バッチサイズのチェック（10ファイルごと、または最後のファイル）
		if (count of currentBatch) ≥ 10 or i = totalFiles then
			-- 現在のバッチでPDFを作成
			set currentFileName to baseFileName & "_part" & (currentPartNum as string) & ".pdf"
			if currentPartNum = 1 and totalFiles ≤ 10 then
				-- ファイルが少ない場合はパート番号なし
				set currentFileName to baseFileName & ".pdf"
			end if
			
			set tempPdfPath to saveFolder & currentFileName
			
			-- ImageMagickコマンドの構築
			set convertCmd to "cd " & quoted form of sourceFolder & " && " & quoted form of convertPath
			if fitToPage then
				if pageSize is "A4" then
					set convertCmd to convertCmd & " -page A4"
				else if pageSize is "Letter" then
					set convertCmd to convertCmd & " -page Letter"
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
					-- ファイルサイズが制限を超える場合、より小さなバッチに分割
					do shell script "rm -f " & quoted form of tempPdfPath
					set smallerBatches to my createSmallerBatches(currentBatch, baseFileName, currentPartNum, sourceFolder, saveFolder, convertPath, imageQuality, pageSize, fitToPage, maxFileSize)
					set createdFiles to createdFiles & smallerBatches
					set currentPartNum to currentPartNum + (count of smallerBatches)
				else
					-- ファイルサイズが制限内の場合
					set fileSize to do shell script "ls -lh " & quoted form of tempPdfPath & " | awk '{print $5}'"
					set createdFiles to createdFiles & {{currentFileName, fileSize}}
					set currentPartNum to currentPartNum + 1
				end if
				
				set processedFiles to processedFiles + (count of currentBatch)
				
				-- 進捗表示
				if totalFiles > 10 then
					display dialog "変換中... (" & processedFiles & "/" & totalFiles & " ファイル処理済み)" giving up after 1
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

-- ============================================
-- ファイルサイズ取得関数（MB単位）
-- ============================================
on getFileSizeMB(filePath)
	try
		set fileSizeBytes to do shell script "stat -f%z " & quoted form of filePath
		return fileSizeBytes / 1024 / 1024
	on error
		return 0
	end try
end getFileSizeMB

-- ============================================
-- より小さなバッチ作成関数
-- ============================================
on createSmallerBatches(originalBatch, baseFileName, startPartNum, sourceFolder, saveFolder, convertPath, imageQuality, pageSize, fitToPage, maxFileSize)
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
				if pageSize is "A4" then
					set convertCmd to convertCmd & " -page A4"
				else if pageSize is "Letter" then
					set convertCmd to convertCmd & " -page Letter"
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
					set recursiveBatches to my createSmallerBatches(currentBatch, baseFileName, currentPartNum, sourceFolder, saveFolder, convertPath, imageQuality, pageSize, fitToPage, maxFileSize)
					set createdFiles to createdFiles & recursiveBatches
					set currentPartNum to currentPartNum + (count of recursiveBatches)
				else
					-- ファイルサイズが制限内または単一ファイル
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