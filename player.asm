.386 
.model flat, stdcall 
option casemap:none 

WinMain proto :dword, :dword, :dword, :dword
WndProc proto :dword, :dword, :dword, :dword 
Multimedia proto :dword, :dword, :dword, :dword 
PlayMp3File proto :dword, :dword 

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

RGB macro red,green,blue 
    xor eax, eax 
    mov ah, blue 
    shl eax, 8 
    mov ah, green 
    mov al, red 
endm

.const 		
	ButtonEarthID   equ  		1					; button for main window
	ButtonPlayID    equ  		2
	ButtonJupID     equ  		3

	ID_LIST1 	equ  		101					; button for dialog box 
	ID_BUTTON1 	equ  		201
   	ID_BUTTON2 	equ  		202
	ID_BUTTON3 	equ  		203
	ID_SHOWPATH 	equ  		1000

	clientHeight    equ       480
	clientWidth     equ       610
	imageWidth      equ       1500
	imageHeight     equ      1500

.data?
	hInstance 	HINSTANCE 		?
	CommandLine 	LPSTR 			?
	hEarthButton   	HWND        		?			; handle of button 
	hPlayButton     HWND        		?
	hJupButton      HWND        		? 
	icex 		INITCOMMONCONTROLSEX 	<>
	hbackground 	HBITMAP 		?
	bm 				BITMAP 			<>
	hBitmap		HBITMAP        ?
	hdcMem          HDC        0

.data 
	ClassName 		db 	"test", 0
	AppName 		db 	"Music Player", 0
	ButtonClassName 	db 	"button", 0
	dlgname 		db 	"MAINSCREEN", 0

	;BorderText     		db  	"==============================================", 0
	WelcomeText     	db  	"Weclome !", 0
	WelcomeText2    	db  	"Just hit the play button and start to listen to music right away !", 0
	

	Earth_title     	db 	"Exit to Earth", 0
	Earth_text      	db  	"Are you sure to leave ? ", 0
	
		
	Start_song      	db  	"start.wav", 0
	First_song      	db  	"nujabes.wav", 0

	Background	  	    db  	"background.bmp", 0
		
	msg1    		db  	"Exit to Earth", 0			; msg on button 
	msg2    		db  	"play", 0
   	msg3    		db  	"Fly to Jupiter", 0

	Mp3DeviceID 		dd 	0
	PlayFlag 		dd 	0 
	Mp3Files 		db 	"*.mp3", 125 dup (0)
	Mp3Device 		db 	"MPEGVideo", 0
	FileName 		db 	"C418-Subwoofer Lullaby.mp3", 128 dup (0) ;play 歌曲相对路径
	szImagePath     db  "backgroud.bmp",0
    
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

        RGB    96,208,255
        invoke SetBkColor, hdc, eax 

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


		invoke TextOut, hdc, 190, 130, addr WelcomeText, sizeof WelcomeText - 1
		invoke TextOut, hdc, 150, 160, addr WelcomeText2, sizeof WelcomeText2 - 1
		;invoke TextOut, hdc, 120, 240, addr BorderText, sizeof BorderText - 1  			
		invoke EndPaint, hWnd, addr ps 

 	.elseif uMsg == WM_CREATE
 		invoke CreateWindowEx, NULL, addr ButtonClassName, addr msg1, \
        WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 40, 350, 150, 30, hWnd, ButtonEarthID, hInstance, NULL
		mov hEarthButton, eax

		invoke CreateWindowEx, NULL, addr ButtonClassName, addr msg2, \
        WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 220, 350, 150, 30, hWnd, ButtonPlayID, hInstance, NULL
		mov hPlayButton, eax

		invoke CreateWindowEx, NULL, addr ButtonClassName, addr msg3, \
        WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 400, 350, 150, 30, hWnd, ButtonJupID, hInstance, NULL
		mov hJupButton, eax

 	.elseif uMsg == WM_COMMAND 
 		mov edx, wParam
 		.if lParam == 0
 			ret 
 		.else
			.if dx == ButtonEarthID 
				jmp earth 
			.elseif dx == ButtonPlayID 
				jmp play
			.else 
				jmp jupiter 
			.endif 
		.endif 
	.else 
 		invoke DefWindowProc, hWnd, uMsg, wParam, lParam
 		ret 
		
 	.endif 
	
	xor eax, eax 
 	ret

earth: 
	invoke MessageBox, NULL, offset Earth_text, offset Earth_title, MB_YESNO or MB_ICONQUESTION
	.if eax == IDYES 
		invoke DestroyWindow, hWnd 
	.endif 
	ret 

play:
	mov icex.dwSize, sizeof INITCOMMONCONTROLSEX
	invoke InitCommonControlsEx, addr icex 
	invoke CreateDialogParam, hInstance, addr dlgname, hWnd, addr Multimedia, NULL
	ret 

jupiter: 
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
			.if PlayFlag == 0
				mov PlayFlag, 1 
				invoke PlayMp3File, hWin, addr FileName 
			.endif 

		.elseif eax == ID_BUTTON2 		; stop button 
			invoke mciSendCommand, Mp3DeviceID, MCI_CLOSE, 0, 0
			mov PlayFlag, 0 

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

end start 
