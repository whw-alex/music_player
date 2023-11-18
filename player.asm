.386 
.model flat, stdcall 
option casemap:none 

WinMain proto :dword, :dword, :dword, :dword
WndProc proto :dword, :dword, :dword, :dword 
Multimedia proto :dword, :dword, :dword, :dword , :dword 
PlayLocalList proto :dword, :dword, :dword, :dword 

PlayMp3File proto :dword, :dword 
FindAllSoundFile proto    ;�ҵ���ǰĿ¼�����еĸ���
GetRandomNum proto :dword  ;��������ǵ�ǰ��������������һ����0����ǰ�������������

show_volume proto :dword
AlterVolume proto :dword ;�ı�����
HandleSilence proto :dword ;�ı侲��״̬

include C:\masm32\include\windows.inc
include C:\masm32\include\user32.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\comctl32.inc
include C:\masm32\include\gdi32.inc
include C:\masm32\include\winmm.inc
include C:\masm32\include\user32.inc


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
	ID_BUTTON7	equ			207
	ID_SHOWPATH 	equ  		1000
	IDC_VOL_SLIDER	equ			1101
	IDC_VOL_TXT		equ			1102
	ID_PROGRESSBAR1	equ			2001

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
	hFindFile      HANDLE ?             ;���ڲ�������sound�ļ�
	hProgressBar   HANDLE ?
	mci_cmd		   BYTE ?; mci��������


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
	have_sound			byte 1	;�Ƿ�������

	SoundFileNum    dd  0
	FileNameBuffer  db 100 dup(0)      ; ���ڴ洢�ļ����Ļ�����
	FileList        db 2000 DUP(0)      
	Mp3Device 		db 	"MPEGVideo", 0
	FileName 		db 	128 dup (0) ;play �������·��
	RandomFileIndex dd  0

	szImagePath     db  "backgroud.bmp",0

	PauseText       db  "Pause",0
	ResumeText       db  "Resume",0

	SilenceText		db "Silence",0
	SoundText		db "Aloud",0

	musicPosition    dd    0
	musicLength      dd    0
	ErrorBuffer		 db    2000 DUP(0)
	MciStatusParams MCI_STATUS_PARMS <>
	seekParams     MCI_SEEK_PARMS <>
	replayParams     MCI_PLAY_PARMS <>

	HereMsg          db  "here!",0
	pnmhdr NMHDR <?> ; ֪ͨ��Ϣ�ṹ��
	OldProgressBarWndProc dd 0
	TimerID        dd 0

	int_fmt BYTE '%d',0	
	cmd_open BYTE 'open "%s" alias my_song type mpegvideo',0
	cmd_setVol BYTE "setaudio my_song volume to %d",0
	mciGenericParams MCI_SET_PARMS <>
	newVolume DWORD ?
    
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

	;========================���ñ�����ɫ=======================���ڲ���
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

		; ������ʱ�豸������
		invoke CreateCompatibleDC, hdc
		mov hdcMem, eax
		
		; ѡ��λͼ����ʱ�豸������
		invoke SelectObject, hdcMem, hBitmap
		
		; ����ͼ��
		invoke SetStretchBltMode, hdc, HALFTONE
		invoke StretchBlt, hdc, 0, 0, clientWidth, clientHeight, hdcMem, 0, 0, imageWidth,imageHeight,SRCCOPY
		
		; ������Դ
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

;=====================================================================================

HandleHorizontalScroll proc
local nPos:DWORD
local totalWidth:DWORD
local newPosition:DWORD

; ��ȡ��ǰ������λ��
invoke SendMessage, hProgressBar, PBM_GETPOS, 0, 0
mov nPos, eax

; ��ȡ���������ܿ��
invoke SendMessage, hProgressBar, PBM_GETRANGE, FALSE, 0
mov totalWidth, eax

; �����µĲ���λ��
mov eax, totalWidth
imul eax, nPos
mov newPosition, eax
idiv totalWidth



ret
HandleHorizontalScroll endp

; =============================================================================================================

HandleNotifyMessage proc
local code:DWORD

; ��ȡ֪ͨ��Ϣ�Ĵ���
mov eax, [pnmhdr].code
mov [code], eax


; ���������֪ͨ��Ϣ
.if [code] == PBM_DELTAPOS
; �����ﴦ�������λ�ñ仯���߼�
	invoke HandleHorizontalScroll
.endif

ret
HandleNotifyMessage endp

; =============================================================================================================

ProgressBarWndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	LOCAL xPos:WORD
	LOCAL newPos:DWORD


	.if uMsg == WM_LBUTTONDOWN
	; �����ﴦ�����������¼�������Ի�ȡ����������꣬��������µĽ�����λ��
	; Ȼ������µ�λ������MCI����λ��
		
		mov eax, lParam
		mov xPos, ax ; ��ȡ��16λ����x����
		
		; �����µ�λ�ò�����MCI����λ��
		; ����ļ��㷽ʽ������Ҫ�������������е���
		shl eax,16
		shr eax,16
		imul eax,musicLength
		mov edx,0
		mov ecx, 300 ; ���������ܳ���
		div ecx ; ������λ�����ܳ����еİٷֱ�
		mov newPos, eax ; ��ms���浽newPos��

		mov seekParams.dwTo, eax
		mov replayParams.dwFrom,eax
		mov seekParams.dwCallback, 0
		
		; ����MCI����λ��
		;invoke mciSendCommand, Mp3DeviceID, MCI_SEEK, MCI_SEEK_TO_PERCENTAGE, newPos
		invoke mciSendCommand, Mp3DeviceID, MCI_SEEK, MCI_WAIT or MCI_TO, addr seekParams

		invoke mciSendCommand, Mp3DeviceID, MCI_PLAY, MCI_NOTIFY or MCI_FROM, addr replayParams
		ret; ����0��ʾ��Ϣ������

	.endif

	; �������WM_LBUTTONDOWN��Ϣ������Ĭ�ϵĴ�����
	invoke CallWindowProc, OldProgressBarWndProc, hWnd, uMsg, wParam, lParam
	ret

ProgressBarWndProc endp
; =============================================================================================================

Multimedia proc hWin:dword, uMsg:dword, aParam:dword, bParam:dword ,lParam:LPARAM 

	.if uMsg == WM_INITDIALOG 

		invoke SetFocus, hWin    	; set the keyboard focus on the specified window 

	invoke SetDlgItemText, hWin, 1001, addr FileName ;set filename to ID_STATIC1

	invoke GetDlgItem, hWin, ID_PROGRESSBAR1
	mov hProgressBar, eax
	;invoke SendMessage, hProgressBar, PBM_SETRANGE, 0, MAKELPARAM(0,100) ; ���ý�������ΧΪ0-100
	;invoke SendMessage, hProgressBar, PBM_SETRANGE, 1, 100 ; ���ý�������ΧΪ0-100
	invoke SendMessage, hProgressBar, PBM_SETPOS, 0, 0 ; ��ʼ��������λ��Ϊ0

	invoke GetWindowLong, hProgressBar, GWL_WNDPROC
	mov OldProgressBarWndProc, eax ; ����ԭʼ���ڹ��̵�ַ
	invoke SetWindowLong, hProgressBar, GWL_WNDPROC, addr ProgressBarWndProc
	invoke SendDlgItemMessage, hWin, IDC_VOL_SLIDER, TBM_SETPOS, 1, 1000

	.elseif uMsg == WM_COMMAND
		mov eax, aParam 

		.if eax == ID_BUTTON1 			; play button
			mov eax, 20000    ; Place your calculated volume value here
			mov ebx, eax    ; Set both left and right channel volumes to the same value
			shl ebx, 16     ; Shift left by 16 bits for the right channel
			; Call waveOutSetVolume to set the system volume
			invoke waveOutSetVolume, 0, ebx
			.if PlayFlag == 0           ;PlayFlag  0����û���ڲ��ŵ� 1�������ڲ���  2������ͣ
 				mov PlayFlag, 1 

				invoke GetRandomNum,SoundFileNum
				push eax         
				mov eax, RandomFileIndex
				imul eax,eax,SIZEOF FileNameBuffer
				add eax,OFFSET FileList
				invoke lstrcpy,ADDR FileName, eax
				;invoke crt_printf, OFFSET FileName
				pop eax
				invoke PlayMp3File, hWin, addr FileName 

				
				; ������ʱ����ÿ100�������һ�ν�����
				invoke SetTimer, hWin, 1, 100, 0
				mov TimerID,eax
				invoke SetDlgItemText, hWin, 1001, addr FileName ;set filename to ID_STATIC1
			.endif 

		.elseif eax == ID_BUTTON2 		; stop button 
			.if PlayFlag != 0
				invoke mciSendCommand, Mp3DeviceID, MCI_CLOSE, 0, 0
				invoke KillTimer,hWin ,TimerID
				invoke SendMessage, hProgressBar, PBM_SETPOS, 0, 0
				invoke SetWindowText, hPauseBtn, addr PauseText
				mov PlayFlag, 1  
				mov PlayFlag, 0 
			.endif

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
		
		.elseif eax == ID_BUTTON7 		; silence button 
			invoke HandleSilence, hWin
			.if have_sound == 0
				invoke SetDlgItemText, hWin, 207, addr SoundText
			.else 
				invoke SetDlgItemText, hWin, 207, addr SilenceText
			.endif
		.endif 
		
		and eax, 0FFFFh
		
	.elseif uMsg == WM_HSCROLL
		invoke show_volume, hWin

	.elseif uMsg == WM_CLOSE
		invoke EndDialog, hWin, NULL 	; close the dialog box 


	.elseif uMsg == MM_MCINOTIFY 
		;mov eax,bParam
		;and eax,0FFFFh

		.if eax == MCI_NOTIFY
			
		.endif
		;invoke mciSendCommand, Mp3DeviceID, MCI_CLOSE, 0, 0				
		;mov PlayFlag, 0

	.elseif uMsg == WM_TIMER
	; �ڶ�ʱ����Ϣ�и��½�����λ��
	; ���� musicPosition �ǵ�ǰ���ֲ��ŵ�λ��
		mov MciStatusParams.dwItem, MCI_STATUS_POSITION
		mov MciStatusParams.dwCallback, 0 
		invoke mciSendCommand, Mp3DeviceID, MCI_STATUS, MCI_STATUS_ITEM or MCI_WAIT, ADDR MciStatusParams
		mov eax, MciStatusParams.dwReturn

		imul eax,eax,100
		mov edx,0
		mov ebx,musicLength
		idiv ebx
		mov musicPosition, eax 
	    invoke SendMessage, hProgressBar, PBM_SETPOS, musicPosition, 0

	.elseif uMsg == WM_HSCROLL
		; ����ˮƽ��������Ϣ
		invoke crt_printf, OFFSET HereMsg
		invoke HandleHorizontalScroll

	.endif

	xor eax, eax 
	ret 

Multimedia endp 


;=====================================================================================
PlayMp3File proc hWin:dword, NameOfFile:dword 

	local mciOpenParms:MCI_OPEN_PARMS, mciPlayParms:MCI_PLAY_PARMS

	; para: LPHMIDIIN lphMidiIn, UINT uDeviceID, DWORD_PTR dwCallback, DWORD_PTR dwCallbackInstance, DWORD dwFlags

	mov eax, hWin
	mov mciPlayParms.dwCallback, eax 

	mov eax, offset Mp3Device 
	mov mciOpenParms.lpstrDeviceType, eax 

	mov eax, NameOfFile 
	mov mciOpenParms.lpstrElementName, eax 

	invoke mciSendCommand, 0, MCI_OPEN,MCI_OPEN_ELEMENT or MCI_WAIT, addr mciOpenParms
	mov eax, mciOpenParms.wDeviceID 
	mov Mp3DeviceID, eax
	;invoke mciSendCommand, Mp3DeviceID, MCI_SET, 0, MCI_FORMAT_MILLISECONDS

	invoke mciGetErrorString, eax, addr ErrorBuffer, sizeof ErrorBuffer
	invoke crt_printf, OFFSET ErrorBuffer

	invoke mciSendCommand, Mp3DeviceID, MCI_PLAY, MCI_NOTIFY, addr mciPlayParms

	mov MciStatusParams.dwItem, MCI_STATUS_LENGTH
	mov MciStatusParams.dwCallback, 0 
		;invoke mciSendCommand, Mp3DeviceID, MCI_STATUS,MCI_STATUS_LENGTH, 0 ;��������
	invoke mciSendCommand, Mp3DeviceID, MCI_STATUS, MCI_STATUS_ITEM or MCI_WAIT, ADDR MciStatusParams
	mov eax, MciStatusParams.dwReturn
	mov musicLength, eax ; ebx �洢���ֵ���ʱ��

	ret 

PlayMp3File endp 

; ====================================================================================================================

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

				invoke wsprintf, ADDR mci_cmd, ADDR cmd_open, ADDR FileName
				invoke mciSendString, ADDR mci_cmd, NULL, 0, NULL

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



FindAllSoundFile PROC

	local 	FileData:WIN32_FIND_DATA  
    invoke FindFirstFile, ADDR Mp3FilePattern, ADDR FileData
    mov hFindFile, eax

    .while hFindFile != INVALID_HANDLE_VALUE
        ; �����ҵ����ļ�
        invoke lstrcpy, ADDR FileNameBuffer, ADDR FileData.cFileName     ; ��ʱ FileNameBuffer �а�����һ�� .mp3 �ļ����ļ���
		;invoke crt_printf, OFFSET FileNameBuffer

		;���µõ������filename�ӵ�FileList����
		push eax  
		mov eax, SoundFileNum
		imul eax,eax,SIZEOF FileNameBuffer
		add eax,OFFSET FileList
		invoke lstrcpy,eax, ADDR FileNameBuffer
		pop eax

		inc SoundFileNum

        ; ����������һ���ļ�
        invoke FindNextFile, hFindFile, ADDR FileData
		.if !eax
                ; ��� GetLastError �Ƿ�Ϊ ERROR_NO_MORE_FILES
                invoke GetLastError
                .if eax == ERROR_NO_MORE_FILES
                    ; û�и���ƥ����˳�ѭ��
                    .break
                .endif
        .endif
    .endw
	 invoke FindClose, hFindFile

	invoke FindFirstFile, ADDR WavFilePattern, ADDR FileData
	mov hFindFile, eax

	.while hFindFile != INVALID_HANDLE_VALUE
	    ; �����ҵ����ļ�
	    invoke lstrcpy, ADDR FileNameBuffer, ADDR FileData.cFileName     ; ��ʱ FileNameBuffer �а�����һ�� .mp3 �ļ����ļ���
		;���µõ������filename�ӵ�FileList����
		push eax  
		mov eax, SoundFileNum
		imul eax,eax,SIZEOF FileNameBuffer
		add eax,OFFSET FileList
		invoke lstrcpy,eax, ADDR FileNameBuffer
		pop eax

		inc SoundFileNum

	    ; ����������һ���ļ�
	    invoke FindNextFile, hFindFile, ADDR FileData
				.if !eax
                ; ��� GetLastError �Ƿ�Ϊ ERROR_NO_MORE_FILES
                invoke GetLastError
                .if eax == ERROR_NO_MORE_FILES
                    ; û�и���ƥ����˳�ѭ��
                    .break
                .endif
        .endif
	.endw
	 invoke FindClose, hFindFile
	 ret

FindAllSoundFile ENDP

; ====================================================================================================================
show_volume proc hWin: DWORD
	local tmp: DWORD
	invoke SendDlgItemMessage,hWin,IDC_VOL_SLIDER,TBM_GETPOS,0,0;��ȡ��ǰSlider�α�λ��
	;����������ʾ����
	mov tmp, 10
	mov edx, 0
	div tmp
	invoke wsprintf, addr mci_cmd, addr int_fmt, eax
	invoke SendDlgItemMessage, hWin, IDC_VOL_TXT, WM_SETTEXT, 0, addr mci_cmd
	invoke AlterVolume, hWin
	Ret
show_volume endp

; ====================================================================================================================

AlterVolume PROC hWin: dword
	invoke SendDlgItemMessage,hWin,IDC_VOL_SLIDER,TBM_GETPOS,0,0	;��ȡ��ǰSliderλ��

	.if have_sound == 1
		;invoke AlterVolume, hWin
		mov ecx, 200       
	    imul eax, ecx

		;mov eax, 1000    ; Place your calculated volume value here
		mov ebx, eax    ; Set both left and right channel volumes to the same value
		shl ebx, 16     ; Shift left by 16 bits for the right channel

		; Call waveOutSetVolume to set the system volume
		invoke waveOutSetVolume, 0, ebx
	.else
		;invoke AlterVolume, hWin
		mov eax, 0    ; Place your calculated volume value here
		mov ebx, eax    ; Set both left and right channel volumes to the same value
		shl ebx, 16     ; Shift left by 16 bits for the right channel

		; Call waveOutSetVolume to set the system volume
		invoke waveOutSetVolume, 0, ebx
	.endif

	mov mciGenericParams.dwAudio, 0 ; ��������ֵ��volume_value ���������õ�������ֵ
	mov eax, hWin
	mov mciGenericParams.dwCallback, 0
	;invoke mciSendCommand, Mp3DeviceID, MCI_SET_AUDIO, MCI_NOTIFY, addr mciGenericParams
	invoke mciSendCommand, Mp3DeviceID, MCI_SET, MCI_SET_AUDIO_ALL, ADDR mciGenericParams

	ret
AlterVolume ENDP

; ====================================================================================================================

HandleSilence PROC hWin: dword
	.if have_sound == 1
		mov have_sound,0
	.else
		mov have_sound,1
	.endif
	invoke AlterVolume, hWin
	ret
HandleSilence ENDP

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


