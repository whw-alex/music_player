.386 
.model flat, stdcall 
option casemap:none 

WinMain proto :dword, :dword, :dword, :dword
WndProc proto :dword, :dword, :dword, :dword 
Multimedia proto :dword, :dword, :dword, :dword 
PlayLocalList proto :dword, :dword, :dword, :dword 

PlayMp3File proto :dword, :dword 
FindAllSoundFile proto    ;找到当前目录下所有的歌曲
GetRandomNum proto :dword  ;这个参数是当前歌曲数量，返回一个【0，当前数量）的随机数

include C:\masm32\include\windows.inc
include C:\masm32\include\user32.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\comctl32.inc
include C:\masm32\include\gdi32.inc
include C:\masm32\include\winmm.inc

includelib C:\masm32\lib\user32.lib
includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\comctl32.lib
includelib C:\masm32\lib\gdi32.lib
includelib C:\masm32\lib\winmm.lib

includelib      msvcrt.lib
include         msvcrt.inc

RGB macro red,green,blue 
    xor eax, eax 
    mov ah, blue 
    shl eax, 8 
    mov ah, green 
    mov al, red 
endm

.const 		
	ButtonExitID   equ  		1					; button for main window
	ButtonPlayID    equ  		2
	ButtonSelectID     equ  		3

	ID_LIST1 	equ  		101					; button for dialog box 
	ID_BUTTON1 	equ  		201
   	ID_BUTTON2 	equ  		202
	ID_BUTTON3 	equ  		203
	ID_BUTTON4	equ			204
	ID_BUTTON5	equ			205
	ID_BUTTON6	equ			206
	ID_SHOWPATH 	equ  		1000

	clientHeight    equ       480
	clientWidth     equ       610
	imageWidth      equ       1500
	imageHeight     equ      1500

.data?
	hInstance 	HINSTANCE 		?
	CommandLine 	LPSTR 			?
	hQuitButton   	HWND        		?			; handle of button 
	hPlayButton     HWND        		?
	hJupButton      HWND        		? 
	icex 		INITCOMMONCONTROLSEX 	<>
	hbackground 	HBITMAP 		?
	bm 				BITMAP 			<>
	hBitmap		HBITMAP        ?
	hdcMem          HDC        0
	hPauseBtn      HWND        		? 
	hFindFile      HANDLE ?             ;用于查找所有sound文件


.data 
	ClassName 		db 	"test", 0
	AppName 		db 	"Music Player", 0
	ButtonClassName 	db 	"button", 0
	dlgname 		db 	"MAINSCREEN", 0
	dlgname1		db	"MAINSCREEN1", 0

	;BorderText     		db  	"==============================================", 0
	WelcomeText     	db  	"Weclome", 0
	WelcomeText2    	db  	"Just hit the play button and start to listen to music right away !", 0
	

	Quit_title     	db 	"Exit", 0
	Quit_text      	db  	"Are you sure to leave ? ", 0
	
		
	Start_song      	db  	"start.wav", 0
	First_song      	db  	"nujabes.wav", 0

	Background	  	    db  	"background.bmp", 0
		
	msg1    		db  	"quit", 0			; msg on button 
	msg2    		db  	"play", 0
   	msg3    		db  	"select", 0

	Mp3DeviceID 		dd 	0
	PlayFlag 		dd 	0 
	Mp3FilePattern 		db 	"*.mp3", 0
	WavFilePattern 		db 	"*.wav", 0

	SoundFileNum    dd  0
	FileNameBuffer  db 100 dup(0)      ; 用于存储文件名的缓冲区
	FileList        db 2000 DUP(0)      
	Mp3Device 		db 	"MPEGVideo", 0
	FileName 		db 	128 dup (0) ;play 歌曲相对路径
	RandomFileIndex dd  0

	szImagePath     db  "backgroud.bmp",0

	PauseText       db  "Pause",0
	ResumeText       db  "Resume",0
    
.code 
start: 
	invoke GetModuleHandle, NULL 
	mov hInstance, eax 

	invoke GetCommandLine 
	mov CommandLine, eax 

	invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess, eax 

; =============================================================================================================



WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:dword 

	local wc:WNDCLASSEX 
	local msg:MSG 
	local hwnd:HWND 						; handle 

	mov wc.cbSize, sizeof WNDCLASSEX 				
	mov wc.style, CS_HREDRAW or CS_VREDRAW 
	mov wc.lpfnWndProc, offset WndProc 				; main window 
	mov wc.cbClsExtra, NULL 
	mov wc.cbWndExtra, NULL 

	push hInst 
	pop wc.hInstance

	;========================设置背景颜色=======================现在不用
	;RGB    96,208,255
	;invoke CreateSolidBrush, eax
	;mov wc.hbrBackground, COLOR_GRAYTEXT + 1 or COLOR_BTNFACE + 1	
	;mov wc.hbrBackground,	eax	
	
	mov wc.lpszMenuName, NULL 
	mov wc.lpszClassName, offset ClassName

	invoke LoadIcon, NULL, IDI_APPLICATION 				
	mov wc.hIcon, eax 
	mov wc.hIconSm, eax 

	invoke LoadCursor, NULL, IDC_ARROW 					
	mov wc.hCursor, eax 

	invoke RegisterClassEx, addr wc 				; register 

	invoke CreateWindowEx, WS_EX_CLIENTEDGE, addr ClassName, \
		addr AppName, WS_VISIBLE or WS_OVERLAPPED or WS_SYSMENU, \
        100, 100, clientWidth, clientHeight, \
        NULL, NULL, hInst, NULL 

    mov hwnd, eax 
    invoke ShowWindow, hwnd, SW_SHOWNORMAL 
    invoke UpdateWindow, hwnd 

	invoke FindAllSoundFile

    .while TRUE 
    	invoke GetMessage, addr msg, NULL, 0, 0
    	.break .if (!eax)
    	invoke TranslateMessage, addr msg 
    	invoke DispatchMessage, addr msg 
    .endw 

    mov eax, msg.wParam 
    ret 
WinMain endp 

; =============================================================================================================

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 

 	local hdc:HDC 
 	local ps:PAINTSTRUCT 

 	.if uMsg == WM_DESTROY 
 		invoke PostQuitMessage, NULL 

 	.elseif uMsg == WM_PAINT 
 		invoke BeginPaint, hWnd, addr ps 
 		mov hdc, eax 

 		RGB    255, 255, 153
        invoke SetTextColor, hdc, eax 

        ;RGB   96,208,255
        invoke SetBkMode, hdc, TRANSPARENT

		invoke LoadImage,NULL, addr szImagePath,IMAGE_BITMAP,0,0,LR_LOADFROMFILE
		mov hBitmap,eax

		; 创建临时设备上下文
		invoke CreateCompatibleDC, hdc
		mov hdcMem, eax
		
		; 选择位图到临时设备上下文
		invoke SelectObject, hdcMem, hBitmap
		
		; 绘制图像
		invoke SetStretchBltMode, hdc, HALFTONE
		invoke StretchBlt, hdc, 0, 0, clientWidth, clientHeight, hdcMem, 0, 0, imageWidth,imageHeight,SRCCOPY
		
		; 清理资源
		invoke DeleteDC, hdcMem
		invoke DeleteObject, hBitmap


		invoke TextOut, hdc, 280, 280, addr WelcomeText, sizeof WelcomeText - 1
		;invoke TextOut, hdc, 150, 160, addr WelcomeText2, sizeof WelcomeText2 - 1
		;invoke TextOut, hdc, 120, 240, addr BorderText, sizeof BorderText - 1  			
		invoke EndPaint, hWnd, addr ps 

 	.elseif uMsg == WM_CREATE
 		invoke CreateWindowEx, NULL, addr ButtonClassName, addr msg1, \
        WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 400, 150, 120, 30, hWnd, ButtonExitID, hInstance, NULL
		mov hQuitButton, eax

		invoke CreateWindowEx, NULL, addr ButtonClassName, addr msg2, \
        WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 400, 250, 120, 30, hWnd, ButtonPlayID, hInstance, NULL
		mov hPlayButton, eax

		invoke CreateWindowEx, NULL, addr ButtonClassName, addr msg3, \
        WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 400, 350, 120, 30, hWnd, ButtonSelectID, hInstance, NULL
		mov hJupButton, eax

 	.elseif uMsg == WM_COMMAND 
 		mov edx, wParam
 		.if lParam == 0
 			ret 
 		.else
			.if dx == ButtonExitID 
				jmp quit 
			.elseif dx == ButtonPlayID 
				jmp play
			.else 
				jmp select
			.endif 
		.endif 
	.else 
 		invoke DefWindowProc, hWnd, uMsg, wParam, lParam
 		ret 
		
 	.endif 
	
	xor eax, eax 
 	ret

quit: 
	invoke MessageBox, NULL, offset Quit_text, offset Quit_title, MB_YESNO or MB_ICONQUESTION
	.if eax == IDYES 
		invoke DestroyWindow, hWnd 
	.endif 
	ret 

play:
	mov icex.dwSize, sizeof INITCOMMONCONTROLSEX
	invoke InitCommonControlsEx, addr icex 
	invoke CreateDialogParam, hInstance, addr dlgname, hWnd, addr Multimedia, NULL
	ret 

select: 
	mov icex.dwSize, sizeof INITCOMMONCONTROLSEX
	invoke InitCommonControlsEx, addr icex 
	invoke CreateDialogParam, hInstance, addr dlgname1, hWnd, addr PlayLocalList, NULL
	ret 

WndProc endp 

; =============================================================================================================

Multimedia proc hWin:dword, uMsg:dword, aParam:dword, bParam:dword 

	.if uMsg == WM_INITDIALOG 

		invoke SetFocus, hWin    	; set the keyboard focus on the specified window 

	invoke SetDlgItemText, hWin, 1001, addr FileName ;set filename to ID_STATIC1

	.elseif uMsg == WM_COMMAND
		mov eax, aParam 

		.if eax == ID_BUTTON1 			; play button	
			.if PlayFlag == 0           ;PlayFlag  0代表没有在播放的 1代表正在播放  2代表暂停
 				mov PlayFlag, 1 

				invoke GetRandomNum,SoundFileNum
				push eax         
				mov eax, RandomFileIndex
				imul eax,eax,SIZEOF FileNameBuffer
				add eax,OFFSET FileList
				invoke lstrcpy,ADDR FileName, eax
				invoke crt_printf, OFFSET FileName
				pop eax
				invoke PlayMp3File, hWin, addr FileName 
				invoke SetDlgItemText, hWin, 1001, addr FileName ;set filename to ID_STATIC1
			.endif 

		.elseif eax == ID_BUTTON2 		; stop button 
			invoke mciSendCommand, Mp3DeviceID, MCI_CLOSE, 0, 0
			mov PlayFlag, 0 

		.elseif eax == ID_BUTTON3 		; pause button 
			invoke GetDlgItem, hWin,  ID_BUTTON3 
			mov hPauseBtn,eax
			.if PlayFlag == 1
				invoke mciSendCommand, Mp3DeviceID, MCI_PAUSE, 0, 0
				invoke SetWindowText, hPauseBtn, addr ResumeText
				mov PlayFlag, 2  

			.elseif PlayFlag == 2
				invoke mciSendCommand, Mp3DeviceID, MCI_RESUME, 0, 0
				invoke SetWindowText, hPauseBtn, addr PauseText
				mov PlayFlag, 1  				

			.endif



		.endif 
		
		and eax, 0FFFFh 

	.elseif uMsg == WM_CLOSE
		invoke EndDialog, hWin, NULL 	; close the dialog box 

	.elseif uMsg == MM_MCINOTIFY 
		invoke mciSendCommand, Mp3DeviceID, MCI_CLOSE, 0, 0				
		mov PlayFlag, 0

	.endif

	xor eax, eax 
	ret 

Multimedia endp 

;=====================================================================================
PlayLocalList proc hWin:dword, uMsg:dword, aParam:dword, bParam:dword 

	.if uMsg == WM_INITDIALOG 

		; para: HWND  hDlg, LPSTR lpPathSpec (*.mp3) , int nIDListBox, int nIDStaticPath, UINT uFileType
		invoke DlgDirList, hWin, addr Mp3FilePattern, ID_LIST1, ID_SHOWPATH, DDL_DIRECTORY or DDL_DRIVES 

		; when the new string is selected, the list box removes the highlight from the previously selected string.
		invoke SendDlgItemMessage, hWin, ID_LIST1, LB_SETCURSEL, 0, 0 	

		invoke SendDlgItemMessage, hWin, ID_LIST1, LB_GETTEXT, eax, addr FileName     ; get string from the list box 
		invoke SetFocus, hWin    	; set the keyboard focus on the specified window 

	.elseif uMsg == WM_COMMAND
		mov eax, aParam 

		.if eax == ID_BUTTON4 			; play button	
			.if PlayFlag == 0
				mov PlayFlag, 1 
				invoke SendDlgItemMessage, hWin, ID_LIST1, LB_GETCURSEL, 0, 0
				invoke SendDlgItemMessage, hWin, ID_LIST1, LB_GETTEXT, eax, addr FileName
				invoke PlayMp3File, hWin, addr FileName 
			.endif 

		.elseif eax == ID_BUTTON5 		; stop button 
			invoke mciSendCommand, Mp3DeviceID, MCI_CLOSE, 0, 0
			mov PlayFlag, 0 

		.elseif eax == ID_BUTTON6		; close button (close the dialog box)
			invoke SendMessage, hWin, WM_CLOSE, NULL, NULL 

		.endif 
		
		and eax, 0FFFFh 

		.if eax == ID_LIST1 
			mov eax, aParam 
			shr eax, 16 

			.if eax == LBN_DBLCLK 		; double click 
				invoke DlgDirSelectEx, hWin, addr Mp3FilePattern, 128, ID_LIST1
				invoke DlgDirList, hWin, addr Mp3FilePattern, ID_LIST1, ID_SHOWPATH, DDL_DIRECTORY or DDL_DRIVES
				invoke SendDlgItemMessage, hWin, ID_LIST1, LB_SETCURSEL, 0, 0
			.endif 
		.endif 

	.elseif uMsg == WM_CLOSE
		invoke EndDialog, hWin, NULL 	; close the dialog box 

	.elseif uMsg == MM_MCINOTIFY 
		invoke mciSendCommand, Mp3DeviceID, MCI_CLOSE, 0, 0				
		mov PlayFlag, 0

	.endif

	xor eax, eax 
	ret 

PlayLocalList endp 

; ====================================================================================================================

PlayMp3File proc hWin:dword, NameOfFile:dword 

	local mciOpenParms:MCI_OPEN_PARMS, mciPlayParms:MCI_PLAY_PARMS

	; para: LPHMIDIIN lphMidiIn, UINT uDeviceID, DWORD_PTR dwCallback, DWORD_PTR dwCallbackInstance, DWORD dwFlags

	mov eax, hWin
	mov mciPlayParms.dwCallback, eax 

	mov eax, offset Mp3Device 
	mov mciOpenParms.lpstrDeviceType, eax 

	mov eax, NameOfFile 
	mov mciOpenParms.lpstrElementName, eax 

	invoke mciSendCommand, 0, MCI_OPEN, MCI_OPEN_TYPE or MCI_OPEN_ELEMENT, addr mciOpenParms

	mov eax, mciOpenParms.wDeviceID 
	mov Mp3DeviceID, eax 
	invoke mciSendCommand, Mp3DeviceID, MCI_PLAY, MCI_NOTIFY, addr mciPlayParms
	ret 

PlayMp3File endp 

; ====================================================================================================================

FindAllSoundFile PROC

	local 	FileData:WIN32_FIND_DATA  
    invoke FindFirstFile, ADDR Mp3FilePattern, ADDR FileData
    mov hFindFile, eax

    .while hFindFile != INVALID_HANDLE_VALUE
        ; 处理找到的文件
        invoke lstrcpy, ADDR FileNameBuffer, ADDR FileData.cFileName     ; 此时 FileNameBuffer 中包含了一个 .mp3 文件的文件名
		;invoke crt_printf, OFFSET FileNameBuffer

		;把新得到的这个filename接到FileList后面
		push eax  
		mov eax, SoundFileNum
		imul eax,eax,SIZEOF FileNameBuffer
		add eax,OFFSET FileList
		invoke lstrcpy,eax, ADDR FileNameBuffer
		pop eax

		inc SoundFileNum

        ; 继续查找下一个文件
        invoke FindNextFile, hFindFile, ADDR FileData
		.if !eax
                ; 检查 GetLastError 是否为 ERROR_NO_MORE_FILES
                invoke GetLastError
                .if eax == ERROR_NO_MORE_FILES
                    ; 没有更多匹配项，退出循环
                    .break
                .endif
        .endif
    .endw
	 invoke FindClose, hFindFile

	invoke FindFirstFile, ADDR WavFilePattern, ADDR FileData
	mov hFindFile, eax

	.while hFindFile != INVALID_HANDLE_VALUE
	    ; 处理找到的文件
	    invoke lstrcpy, ADDR FileNameBuffer, ADDR FileData.cFileName     ; 此时 FileNameBuffer 中包含了一个 .mp3 文件的文件名
		;把新得到的这个filename接到FileList后面
		push eax  
		mov eax, SoundFileNum
		imul eax,eax,SIZEOF FileNameBuffer
		add eax,OFFSET FileList
		invoke lstrcpy,eax, ADDR FileNameBuffer
		pop eax

		inc SoundFileNum

	    ; 继续查找下一个文件
	    invoke FindNextFile, hFindFile, ADDR FileData
				.if !eax
                ; 检查 GetLastError 是否为 ERROR_NO_MORE_FILES
                invoke GetLastError
                .if eax == ERROR_NO_MORE_FILES
                    ; 没有更多匹配项，退出循环
                    .break
                .endif
        .endif
	.endw
	 invoke FindClose, hFindFile
	 ret

FindAllSoundFile ENDP

; ====================================================================================================================

GetRandomNum PROC total_num:DWORD
	push edx
	push eax
	invoke GetTickCount
	mov edx,0
	div total_num
	mov RandomFileIndex,edx
	pop eax
	pop edx
     ret
GetRandomNum ENDP

end start 



