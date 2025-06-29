-- ============================================
-- PNG画像をPDFに変換するAppleScript 
-- ============================================

-- 詳細設定
set sourceFolder to "/Users/gantaku/本/_screenshot/" -- PNG画像フォルダ
set saveFolder to "/Users/gantaku/本/" -- PDF保存先フォルダ
set imageQuality to "85" -- 画質 (1-100, 100が最高画質)
set pageSize to "A4" -- ページサイズ (A4, Letter, Legal など)
set fitToPage to true -- 画像をページサイズに合わせる

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
		set pdfFileName to fileNameInput
	else
		set pdfFileName to fileNameInput & ".pdf"
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
	display dialog "PNG→PDF変換設定" & return & return & "ファイル数: " & fileCount & " 個" & return & "画質: " & imageQuality & "%" & return & "ページサイズ: " & pageSize & return & "保存ファイル: " & pdfFileName buttons {"キャンセル", "変換開始"} default button "変換開始"
	
	-- ImageMagickコマンドの構築
	set convertCmd to "cd " & quoted form of sourceFolder & " && " & quoted form of convertPath
	if fitToPage then
		if pageSize is "A4" then
			set convertCmd to convertCmd & " -page A4"
		else if pageSize is "Letter" then
			set convertCmd to convertCmd & " -page Letter"
		end if
	end if
	set convertCmd to convertCmd & " -quality " & imageQuality & " -compress jpeg $(ls -1 *.png | sort -V) " & quoted form of (saveFolder & pdfFileName)
	
	-- 変換実行
	do shell script convertCmd
	
	-- ファイル作成の完了を待つ
	delay 2
	
	-- 結果の確認
	set pdfExists to do shell script "if [ -f " & quoted form of (saveFolder & pdfFileName) & " ]; then echo 'true'; else echo 'false'; fi"
	
	if pdfExists is "true" then
		-- ファイルサイズを取得
		set pdfSize to do shell script "ls -lh " & quoted form of (saveFolder & pdfFileName) & " | awk '{print $5}'"
		set pngMoveStatus to "移動しませんでした"
		display dialog "変換元のPNGファイルをゴミ箱に移動しますか？" with title "ファイルの後処理" buttons {"いいえ", "はい"} default button "はい"
		if button returned of result is "はい" then
			-- tellブロックとtryブロックの入れ子構造を修正
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
		
		-- 完了メッセージ
		display dialog "PDF変換が完了しました！" & return & return & "✅ ファイル名: " & pdfFileName & return & "📊 ファイルサイズ: " & pdfSize & return & "📁 保存場所: " & saveFolder & return & "🗑️ 元ファイル: " & pngMoveStatus & return & return & "Finderで保存先フォルダを開きました。" buttons {"OK"} default button "OK" with icon note
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
