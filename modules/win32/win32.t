
module win32;

import platform;

func __debugbreak()         intrinsic("intrin.h");
func __rdtsc() (cycles u64) intrinsic("intrin.h");
// unsinged long is not the same as u32, why microsoft? why?!
//func _BitScanReverse(index u32 ref, mask u32) (ok u8) intrinsic("intrin.h");

func GetLastError() (result u32)                                  calling_convention "__stdcall" extern_binding("kernel32", true);
func ExitProcess(uExitCode u32)                                   calling_convention "__stdcall" extern_binding("kernel32", true);
func GetSystemTimeAsFileTime(lpSystemTimeAsFileTime FILETIME ref) calling_convention "__stdcall" extern_binding("kernel32", true);
func GetLocalTime(lpSystemTime SYSTEMTIME ref)                    calling_convention "__stdcall" extern_binding("kernel32", true);
func Sleep(dwMilliseconds u32)                                    calling_convention "__stdcall" extern_binding("kernel32", true);

func VirtualAlloc(lpAddress u8 ref, dwSize usize, flAllocationType u32, flProtect u32) (result u8 ref)  calling_convention "__stdcall" extern_binding("kernel32", true);
func VirtualFree(lpAddress u8 ref, dwSize usize, dwFreeType u32) (result u32) calling_convention "__stdcall" extern_binding("kernel32", true);
func GetFileAttributesExA(lpFileName cstring, fInfoLevelId s32, lpFileInformation u8 ref) (result s32) calling_convention "__stdcall" extern_binding("kernel32", true);
func CreateFileA(lpFileName cstring, dwDesiredAccess u32, dwShareMode u32, lpSecurityAttributes u8 ref, dwCreationDisposition u32, dwFlagsAndAttributes u32, hTemplateFile HANDLE) (result HANDLE) calling_convention "__stdcall" extern_binding("kernel32", true);
func ReadFile(hFile HANDLE, lpBuffer u8 ref, nNumberOfBytesToRead u32, lpNumberOfBytesRead u32 ref, lpOverlapped u8 ref) (result s32) calling_convention "__stdcall" extern_binding("kernel32", true);
func WriteFile(hFile HANDLE, lpBuffer u8 ref, nNumberOfBytesToWrite u32, lpNumberOfBytesWritten u32 ref, lpOverlapped u8 ref) (result s32) calling_convention "__stdcall" extern_binding("kernel32", true);
func CreateDirectoryA(lpPathName cstring, lpSecurityAttributes u8 ref) (result s32) calling_convention "__stdcall" extern_binding("kernel32", true);
func CloseHandle(hObject HANDLE) (result s32) calling_convention "__stdcall" extern_binding("kernel32", true);
func CopyFileA(lpExistingFileName cstring, lpNewFileName cstring, bFailIfExists s32) (result s32) calling_convention "__stdcall" extern_binding("kernel32", true);
func LoadLibraryA(lpLibFileName cstring) (module HMODULE) calling_convention "__stdcall" extern_binding("kernel32", true);
func FreeLibrary(hLibModule HMODULE) (result s32) calling_convention "__stdcall" extern_binding("kernel32", true);
func GetProcAddress(hModule HMODULE, lpProcName cstring) (result u8 ref) calling_convention "__stdcall" extern_binding("kernel32", true);
func AttachConsole(dwProcessId u32) (result s32)  calling_convention "__stdcall" extern_binding("kernel32", true);
func AllocConsole() (result s32)                  calling_convention "__stdcall" extern_binding("kernel32", true);
func FreeConsole() (result s32)                   calling_convention "__stdcall" extern_binding("kernel32", true);
func GetStdHandle(nStdHandle u32) (handle HANDLE) calling_convention "__stdcall" extern_binding("kernel32", true);
func WriteConsoleA(hConsoleOutput HANDLE, lpBuffer u8 ref, nNumberOfCharsToWrite u32, lpNumberOfCharsWritten u32 ref, lpReserved u8 ref) (result s32)                  calling_convention "__stdcall" extern_binding("kernel32", true);
func GetModuleFileNameA(hModule HMODULE, lpFilename cstring, nSize s32) (result s32) calling_convention "__stdcall" extern_binding("kernel32", true);
func GetConsoleMode(hConsoleHandle HANDLE, lpMode u32 ref) (result s32) calling_convention "__stdcall" extern_binding("kernel32", true);
func CreateThread(lpThreadAttributes u8 ref, dwStackSize usize, lpStartAddress THREAD_START_ROUTINE, lpParameter u8 ref, dwCreationFlags u32, lpThreadId u32 ref) (handle HANDLE) calling_convention "__stdcall" extern_binding("kernel32", true);
func ResumeThread(hThread HANDLE) (result u32) calling_convention "__stdcall" extern_binding("kernel32", true);
func WaitForSingleObject(hHandle HANDLE, dwMilliseconds u32) (result u32) calling_convention "__stdcall" extern_binding("kernel32", true);

func PeekMessageA(lpMsg MSG ref, hWnd HWND, wMsgFilterMin u32, wMsgFilterMax u32, wRemoveMsg u32) (result s32) calling_convention "__stdcall" extern_binding("user32", true);
func LoadCursorA(hInstance HINSTANCE, lpCursorName cstring) (result HCURSOR)                     calling_convention "__stdcall" extern_binding("user32", true);
func RegisterClassA(lpWndClass WNDCLASSA ref) (result u16)                                          calling_convention "__stdcall" extern_binding("user32", true);
func DefWindowProcA    WNDPROC                                                                         extern_binding("user32", true);
func TranslateMessage  (lpMsg MSG ref) (result s32)                                                     calling_convention "__stdcall" extern_binding("user32", true);
func DispatchMessageA  (lpMsg MSG ref) (result LRESULT)                                                 calling_convention "__stdcall" extern_binding("user32", true);
func PostQuitMessage   (nExitCode s32)                                                                  calling_convention "__stdcall" extern_binding("user32", true);
func MsgWaitForMultipleObjects(nCount u32, pHandles HANDLE ref, fWaitAll s32, dwMilliseconds u32, dwWakeMask u32) (result u32) calling_convention "__stdcall" extern_binding("user32", true);
func GetKeyState       (nVirtKey s32) (result u16)                                                      calling_convention "__stdcall" extern_binding("user32", true);
func GetMonitorInfoA   (hMonitor HMONITOR, lpmi MONITORINFO ref) (result s32)                           calling_convention "__stdcall" extern_binding("user32", true);
func GetCursorPos      (lpPoint POINT ref) (result u32)                                                 calling_convention "__stdcall" extern_binding("user32", true);
func MonitorFromPoint  (pt POINT, dwFlags u32) (monitor HMONITOR)                                       calling_convention "__stdcall" extern_binding("user32", true);
func MonitorFromWindow(hwnd HWND, dwFlags u32) (result HMONITOR) calling_convention "__stdcall" extern_binding("user32", true);
func EnumDisplayDevicesA(lpDevice cstring,iDevNum u32, lpDisplayDevice DISPLAY_DEVICEA ref,dwFlagsu32) (result s32) calling_convention "__stdcall" extern_binding("user32", true);
func ScreenToClient    (hWnd HWND, lpPoint POINT ref) (result s32)                                      calling_convention "__stdcall" extern_binding("user32", true);
func ClientToScreen    (hWnd HWND, lpPoint POINT ref) (result s32)                                      calling_convention "__stdcall" extern_binding("user32", true);
func GetWindowPlacement(hWnd HWND, lpwndpl WINDOWPLACEMENT ref) (result s32)                            calling_convention "__stdcall" extern_binding("user32", true);
func SetWindowPlacement(hWnd HWND, lpwndpl WINDOWPLACEMENT ref) (result s32)                            calling_convention "__stdcall" extern_binding("user32", true);
func SetWindowPos(hWnd HWND, hWndInsertAfter HWND, X s32, Y s32, cx s32, cy s32, uFlags u32) (result s32) calling_convention "__stdcall" extern_binding("user32", true);
func GetWindowLongA(hWnd HWND, nIndex s32) (result s32)                                                 calling_convention "__stdcall" extern_binding("user32", true);
func SetWindowLongA(hWnd HWND, nIndex s32, dwNewLong s32) (result s32)                                  calling_convention "__stdcall" extern_binding("user32", true);
func LoadIconA(hInstance HINSTANCE, lpIconName cstring) (icon HICON)                                    calling_convention "__stdcall" extern_binding("user32", true);
func SetClassLongPtrA(hWnd HWND, nIndex s32, dwNewLong s64 ref) (result u64 ref)                        calling_convention "__stdcall" extern_binding("user32", true);


// these actually take LARGE_INTEGER, but its the same as u64
func QueryPerformanceFrequency(lpFrequency u64 ref) (result s32)                                        calling_convention "__stdcall" extern_binding("user32", true);
func QueryPerformanceCounter   (lpCounter u64 ref) (result s32)                                         calling_convention "__stdcall" extern_binding("user32", true);

func MessageBoxExA(hWnd HWND, lpText cstring, lpCaption cstring, uType u32, wLanguageId u16) (result s32) calling_convention "__stdcall" extern_binding("user32", true);
func EnumDisplayMonitors(hdc HDC, lprcClip RECT ref, lpfnEnum MONITORENUMPROC, dwData LPARAM) (result s32)                             calling_convention "__stdcall" extern_binding("user32", true);

func GetDC             (window HWND) (device_context HDC)                                               calling_convention "__stdcall" extern_binding("gdi32", true);
func ReleaseDC         (window HWND, device_context HDC) (result s32)                                   calling_convention "__stdcall" extern_binding("gdi32", true);
func SwapBuffers       (window HWND) (result u32)                                                       calling_convention "__stdcall" extern_binding("gdi32", true);

func GetModuleHandleA  (window HWND) (module HMODULE)                                                   calling_convention "__stdcall" extern_binding("gdi32", true);
func ChoosePixelFormat(hdc HDC, ppfd PIXELFORMATDESCRIPTOR ref) (result s32)                            calling_convention "__stdcall" extern_binding("gdi32", true);
func SetPixelFormat    (hdc HDC, format s32, ppfd PIXELFORMATDESCRIPTOR ref) (result s32)               calling_convention "__stdcall" extern_binding("gdi32", true);
func ShowWindow        (hWnd HWND, nCmdShow s32) (result s32)                                           calling_convention "__stdcall" extern_binding("gdi32", true);
func GetClientRect     (hWnd HWND, lpRect RECT ref) (result s32)                                        calling_convention "__stdcall" extern_binding("gdi32", true);
func GetWindowRect     (hWnd HWND, lpRect RECT ref) (result s32)                                        calling_convention "__stdcall" extern_binding("gdi32", true);
func AdjustWindowRect(lpRect RECT ref,
dwStyle u32,
bMenu
s32) (result s32)                             calling_convention "__stdcall" extern_binding("gdi32", true);

func CreateWindowExA   (dwExStyle u32, lpClassName cstring, lpWindowName cstring, dwStyle u32, X s32, Y s32, nWidth s32, nHeight s32, hWndParent HWND, hMenu HMENU, hInstance HINSTANCE, lpParam u8 ref) (result HWND) calling_convention "__stdcall" extern_binding("user32", true);
func DestroyWindow     (window HWND) (result u32)                                                       calling_convention "__stdcall" extern_binding("gdi32", true);


func THREAD_START_ROUTINE(lpParam u8 ref) (result u32) calling_convention "__stdcall";

func WNDPROC(window HWND, msg u32, w_param WPARAM, l_param LPARAM) (result LRESULT) calling_convention "__stdcall";

func MONITORENUMPROC(unnamedParam1 HMONITOR, unnamedParam2 HDC, unnamedParam3 RECT ref, unnamedParam4 LPARAM) (result s32) calling_convention "__stdcall";

func IsDebuggerPresent() (ok u32) calling_convention "__stdcall" extern_binding("kernel32", true);

func DnsQuery_A(pszName cstring, wType u16, Options u32, pExtra u8 ref, ppQueryResults u8 ref ref, pReserved u8 ref) (status s64) calling_convention "__stdcall" extern_binding("dnsapi", true);
func DnsFree(pData u8 ref, FreeType u32) calling_convention "__stdcall" extern_binding("dnsapi", true);

func DnsRecordListFree(p u8 ref, ignored u32)
{
    DnsFree(p, DnsFreeRecordList);
}

func XInputGetState_type(dwUserIndex u32, pState XINPUT_STATE ref) (state u32) calling_convention "__stdcall";
func XInputGetCapabilities_type(dwUserIndex u32, dwFlags u32, pCapabilities XINPUT_CAPABILITIES ref) (state u32) calling_convention "__stdcall";

type HANDLE    u8 ref;
type HWND      u8 ref;
type HDC       u8 ref;
type HMENU     u8 ref;
type HMODULE   u8 ref;
type HINSTANCE u8 ref;
type HCURSOR   u8 ref;
type HICON     u8 ref;
type HBRUSH    u8 ref;
type HMONITOR  u8 ref;

type WPARAM  u64;
type LPARAM  s64;
type LRESULT s64;

struct POINT
{
    x s32;
    y s32;
}

struct RECT
{
    left   s32;
    top    s32;
    right  s32;
    bottom s32;
}

struct MSG
{
  hwnd     HWND;
  message  u32;
  wParam   WPARAM;
  lParam   LPARAM;
  time     u32;
  pt       POINT;
  // lPrivate u32;
}

struct WNDCLASSA
{
    style         u32;
    lpfnWndProc   WNDPROC;
    cbClsExtra    s32;
    cbWndExtra    s32;
    hInstance     HINSTANCE;
    hIcon         HICON;
    hCursor       HCURSOR;
    hbrBackground HBRUSH;
    lpszMenuName  cstring;
    lpszClassName cstring;
}

struct PIXELFORMATDESCRIPTOR
{
    nSize           u16;
    nVersion        u16;
    dwFlags         u32;
    iPixelType      u8;
    cColorBits      u8;
    cRedBits        u8;
    cRedShift       u8;
    cGreenBits      u8;
    cGreenShift     u8;
    cBlueBits       u8;
    cBlueShift      u8;
    cAlphaBits      u8;
    cAlphaShift     u8;
    cAccumBits      u8;
    cAccumRedBits   u8;
    cAccumGreenBits u8;
    cAccumBlueBits  u8;
    cAccumAlphaBits u8;
    cDepthBits      u8;
    cStencilBits    u8;
    cAuxBuffers     u8;
    iLayerType      u8;
    bReserved       u8;
    dwLayerMask     u32;
    dwVisibleMask   u32;
    dwDamageMask    u32;
}

struct FILETIME
{
    dwLowDateTime  u32;
    dwHighDateTime u32;
}

struct SYSTEMTIME
{
    wYear         u16;
    wMonth        u16;
    wDayOfWeek    u16;
    wDay          u16;
    wHour         u16;
    wMinute       u16;
    wSecond       u16;
    wMilliseconds u16;
}

struct WIN32_FILE_ATTRIBUTE_DATA
{
    dwFileAttributes u32;
    ftCreationTime FILETIME;
    ftLastAccessTime FILETIME;
    ftLastWriteTime FILETIME;
    nFileSizeHigh u32;
    nFileSizeLow  u32;
}

struct MONITORINFO
{
    cbSize    u32;
    rcMonitor RECT;
    rcWork    RECT;
    dwFlags   u32;
}

struct MONITORINFOEXA
{
    expand base MONITORINFO;
    szDevice u8[CCHDEVICENAME];  
}

def CCHDEVICENAME = 32;

struct WINDOWPLACEMENT
{
    length           u32;
    flags            u32;
    showCmd          u32;
    ptMinPosition    POINT;
    ptMaxPosition    POINT;
    rcNormalPosition RECT;
    rcDevice         RECT;
}

struct DISPLAY_DEVICEA
{
    cb           u32;
    DeviceName   u8[32];
    DeviceString u8[128];
    StateFlags   u32;
    DeviceID     u8[128];
    DeviceKey    u8[128];
}

struct XINPUT_STATE
{
    dwPacketNumber u32;
    Gamepad        XINPUT_GAMEPAD;
}

struct XINPUT_GAMEPAD
{
    wButtons      u16;
    bLeftTrigger  u8;
    bRightTrigger u8;
    sThumbLX      s16;
    sThumbLY      s16;
    sThumbRX      s16;
    sThumbRY      s16;
}

struct XINPUT_CAPABILITIES
{
    Type      u8;
    SubType   u8;
    Flags     u16;
    Gamepad   XINPUT_GAMEPAD;
    Vibration XINPUT_VIBRATION;
}

struct XINPUT_VIBRATION
{
    wLeftMotorSpeed  u16;
    wRightMotorSpeed u16;
}

def INVALID_HANDLE_VALUE = (-1) cast(HANDLE);

def CS_OWNDC = 0x0020 cast(u32);

def IDC_ARROW = 32512 cast(u16) cast(cstring);

def COLOR_BACKGROUND = 1 cast(s32);

def CW_USEDEFAULT = 0x80000000 cast(s32);

def WS_OVERLAPPEDWINDOW = 0x00CF0000 cast(u32);
def WS_THICKFRAME       = 0x00040000 cast(u32);

def MEM_COMMIT   = 0x00001000 cast(u32);
def MEM_RESERVE  = 0x00002000 cast(u32);
def MEM_DECOMMIT = 0x00004000 cast(u32);
def MEM_RELEASE  = 0x00008000 cast(u32);

def PAGE_NOACCESS          = 0x01 cast(u32);
def PAGE_EXECUTE           = 0x10 cast(u32);
def PAGE_EXECUTE_READ      = 0x20 cast(u32);
def PAGE_READWRITE         = 0x04 cast(u32);
def PAGE_EXECUTE_READWRITE = 0x40 cast(u32);

def SW_HIDE             = 0 cast(u32);
def SW_SHOWNORMAL       = 1 cast(u32);
def SW_NORMAL           = 1 cast(u32);
def SW_SHOWMINIMIZED    = 2 cast(u32);
def SW_SHOWMAXIMIZED    = 3 cast(u32);
def SW_MAXIMIZE         = 3 cast(u32);
def SW_SHOWNOACTIVATE   = 4 cast(u32);
def SW_SHOW             = 5 cast(u32);
def SW_MINIMIZE         = 6 cast(u32);
def SW_SHOWMINNOACTIVE  = 7 cast(u32);
def SW_SHOWNA           = 8 cast(u32);
def SW_RESTORE          = 9 cast(u32);
def SW_SHOWDEFAULT      = 10 cast(u32);
def SW_FORCEMINIMIZE    = 11 cast(u32);
def SW_MAX              = 11 cast(u32);

def SWP_NOSIZE          = 0x0001 cast(u32);
def SWP_NOMOVE          = 0x0002 cast(u32);
def SWP_NOZORDER        = 0x0004 cast(u32);
def SWP_NOREDRAW        = 0x0008 cast(u32);
def SWP_NOACTIVATE      = 0x0010 cast(u32);
def SWP_FRAMECHANGED    = 0x0020 cast(u32);
def SWP_SHOWWINDOW      = 0x0040 cast(u32);
def SWP_HIDEWINDOW      = 0x0080 cast(u32);
def SWP_NOCOPYBITS      = 0x0100 cast(u32);
def SWP_NOOWNERZORDER   = 0x0200 cast(u32);
def SWP_NOSENDCHANGING  = 0x0400 cast(u32);

def HWND_TOP = 0 cast(HWND);

def GWL_STYLE = -16 cast(s32);

def PM_REMOVE = 1 cast(u32);

def WM_NULL                         = 0x0000 cast(u32);
def WM_CREATE                       = 0x0001 cast(u32);
def WM_DESTROY                      = 0x0002 cast(u32);
def WM_MOVE                         = 0x0003 cast(u32);
def WM_SIZE                         = 0x0005 cast(u32);
def WM_CLOSE                        = 0x0010 cast(u32);
def WM_MENUCHAR                     = 0x0120 cast(u32);
def WM_QUIT                         = 0x0012 cast(u32);

def WM_INPUT                        = 0x00FF cast(u32);
def WM_KEYFIRST                     = 0x0100 cast(u32);
def WM_KEYDOWN                      = 0x0100 cast(u32);
def WM_KEYUP                        = 0x0101 cast(u32);
def WM_CHAR                         = 0x0102 cast(u32);
def WM_DEADCHAR                     = 0x0103 cast(u32);
def WM_SYSKEYDOWN                   = 0x0104 cast(u32);
def WM_SYSKEYUP                     = 0x0105 cast(u32);
def WM_SYSCHAR                      = 0x0106 cast(u32);
def WM_SYSDEADCHAR                  = 0x0107 cast(u32);
def WM_UNICHAR                      = 0x0109 cast(u32);
def WM_KEYLAST                      = 0x0109 cast(u32);
def WM_DEVICECHANGE                 = 0x0219 cast(u32);
def WM_MOUSEWHEEL                   = 0x020A cast(u32);

def SIZE_MAXIMIZED = 2 cast(u32);

def UNICODE_NOCHAR                  = 0xFFFF cast(u32);

def MNC_CLOSE = 1 cast(u32);

def GCLP_HICON = -14 cast(s32);

def PFD_TYPE_RGBA               = 0 cast(u8);
def PFD_MAIN_PLANE              = 0 cast(u8);
def PFD_DOUBLEBUFFER            = 0x00000001 cast(u8);
def PFD_STEREO                  = 0x00000002 cast(u8);
def PFD_DRAW_TO_WINDOW          = 0x00000004 cast(u8);
def PFD_DRAW_TO_BITMAP          = 0x00000008 cast(u8);
def PFD_SUPPORT_GDI             = 0x00000010 cast(u8);
def PFD_SUPPORT_OPENGL          = 0x00000020 cast(u8);
def PFD_GENERIC_FORMAT          = 0x00000040 cast(u8);
def PFD_NEED_PALETTE            = 0x00000080 cast(u8);
def PFD_NEED_SYSTEM_PALETTE     = 0x00000100 cast(u8);
def PFD_SWAP_EXCHANGE           = 0x00000200 cast(u8);
def PFD_SWAP_COPY               = 0x00000400 cast(u8);
def PFD_SWAP_LAYER_BUFFERS      = 0x00000800 cast(u8);
def PFD_GENERIC_ACCELERATED     = 0x00001000 cast(u8);
def PFD_SUPPORT_DIRECTDRAW      = 0x00002000 cast(u8);
def PFD_DIRECT3D_ACCELERATED    = 0x00004000 cast(u8);
def PFD_SUPPORT_COMPOSITION     = 0x00008000 cast(u8);

def GetFileExInfoStandard = 0 cast(s32);

def GENERIC_READ    = 0x80000000 cast(u32);
def GENERIC_WRITE   = 0x40000000 cast(u32);
def GENERIC_EXECUTE = 0x20000000 cast(u32);
def GENERIC_ALL     = 0x10000000 cast(u32);

def FILE_SHARE_READ       = 0x00000001 cast(u32);
def FILE_ATTRIBUTE_NORMAL = 0x00000080 cast(u32);

def CREATE_NEW    = 1 cast(u32);
def CREATE_ALWAYS = 2 cast(u32);
def OPEN_EXISTING = 3 cast(u32);
def OPEN_ALWAYS   = 4 cast(u32);

def VK_LBUTTON    = 0x01 cast(u8);
def VK_RBUTTON    = 0x02 cast(u8);
def VK_MBUTTON    = 0x04 cast(u8);

def VK_SHIFT      = 0x10 cast(u8);
def VK_CONTROL    = 0x11 cast(u8);
def VK_MENU       = 0x12 cast(u8);

def VK_SPACE      = 0x20 cast(u8);
def VK_TAB        = 0x09 cast(u8);
def VK_BACK       = 0x08 cast(u8);
def VK_RETURN     = 0x0D cast(u8);
def VK_ESCAPE     = 0x1B cast(u8);
def VK_DELETE     = 0x2E cast(u8);
def VK_NEXT       = 0x22 cast(u8);
def VK_PRIOR      = 0x21 cast(u8);
def VK_HOME       = 0x24 cast(u8);
def VK_END        = 0x23 cast(u8);
def VK_LEFT       = 0x25 cast(u8);
def VK_RIGHT      = 0x27 cast(u8);
def VK_DOWN       = 0x28 cast(u8);
def VK_UP         = 0x26 cast(u8);

def VK_F1         = 0x70 cast(u8);

def VK_OEM_PLUS   = 	0xBB cast(u8);
def VK_OEM_COMMA  = 	0xBC cast(u8);
def VK_OEM_MINUS 	 = 0xBD cast(u8);
def VK_OEM_PERIOD 	= 0xBE cast(u8);

def MONITOR_DEFAULTTOPRIMARY = 0x00000001 cast(u32);

def STD_INPUT_HANDLE  = -10 cast(u32);
def STD_OUTPUT_HANDLE = -11 cast(u32);
def STD_ERROR_HANDLE  = -12 cast(u32);

def ATTACH_PARENT_PROCESS = -1 cast(u32);

def ERROR_INVALID_HANDLE = 0x6 cast(u32);
def ERROR_ACCESS_DENIED  = 0x5 cast(u32);

def MB_ABORTRETRYIGNORE  = 0x00000002 cast(u32);
def MB_CANCELTRYCONTINUE = 0x00000006 cast(u32);
def MB_HELP              = 0x00004000 cast(u32);
def MB_OK                = 0x00000000 cast(u32);
def MB_OKCANCEL          = 0x00000001 cast(u32);
def MB_RETRYCANCEL       = 0x00000005 cast(u32);
def MB_YESNO             = 0x00000004 cast(u32);
def MB_YESNOCANCEL       = 0x00000003 cast(u32);
def MB_ICONEXCLAMATION   = 0x00000030 cast(u32);

def MB_ICONWARNING       = 0x00000030 cast(u32);
def MB_ICONINFORMATION   = 0x00000040 cast(u32);
def MB_ICONASTERISK      = 0x00000040 cast(u32);
def MB_ICONQUESTION      = 0x00000020 cast(u32);
def MB_ICONSTOP          = 0x00000010 cast(u32);
def MB_ICONERROR         = 0x00000010 cast(u32);
def MB_ICONHAND          = 0x00000010 cast(u32);

def IDABORT    = 3 cast(u32);
def IDCANCEL   = 2 cast(u32);
def IDCONTINUE = 11 cast(u32);
def IDIGNORE   = 5 cast(u32);
def IDNO       = 7 cast(u32);
def IDOK       = 1 cast(u32);
def IDRETRY    = 4 cast(u32);
def IDTRYAGAIN = 10 cast(u32);
def IDYES      = 6 cast(u32);

def CREATE_SUSPENDED = 0x00000004 cast(u32);

def QS_KEY   = 0x0001 cast(u32);
def QS_MOUSE = 0x0006 cast(u32);


def WAIT_ABANDONED = 0x00000080 cast(u32);
def WAIT_OBJECT_0  = 0x00000000 cast(u32);
def WAIT_TIMEOUT   = 0x00000102 cast(u32);
def WAIT_FAILED    = 0xFFFFFFFF cast(u32);

def INFINITE   = 0xFFFFFFFF cast(u32);

def ERROR_SUCCESS        = 0x00 cast(u32);
def ERROR_ALREADY_EXISTS = 0xB7 cast(u32);

def XUSER_MAX_COUNT = 4;
def XINPUT_GAMEPAD_DPAD_UP        	= 0x0001 cast(u16);
def XINPUT_GAMEPAD_DPAD_DOWN      	= 0x0002 cast(u16);
def XINPUT_GAMEPAD_DPAD_LEFT      	= 0x0004 cast(u16);
def XINPUT_GAMEPAD_DPAD_RIGHT     	= 0x0008 cast(u16);
def XINPUT_GAMEPAD_START          	= 0x0010 cast(u16);
def XINPUT_GAMEPAD_BACK 	          = 0x0020 cast(u16);
def XINPUT_GAMEPAD_LEFT_THUMB 	    = 0x0040 cast(u16);
def XINPUT_GAMEPAD_RIGHT_THUMB 	   = 0x0080 cast(u16);
def XINPUT_GAMEPAD_LEFT_SHOULDER 	 = 0x0100 cast(u16);
def XINPUT_GAMEPAD_RIGHT_SHOULDER 	= 0x0200 cast(u16);
def XINPUT_GAMEPAD_A              	= 0x1000 cast(u16);
def XINPUT_GAMEPAD_B              	= 0x2000 cast(u16);
def XINPUT_GAMEPAD_X              	= 0x4000 cast(u16);
def XINPUT_GAMEPAD_Y              	= 0x8000 cast(u16);

def XINPUT_FLAG_GAMEPAD =            0x00000001 cast(u32);

def XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE  = 7849 cast(s16);
def XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE = 8689 cast(s16);
def XINPUT_GAMEPAD_TRIGGER_THRESHOLD    = 30 cast(u8);

def DNS_TYPE_A = 1 cast(u16);

def DNS_QUERY_STANDARD = 0 cast(u32);

def DnsFreeFlat                = 0 cast(u32);
def DnsFreeRecordList          = 1 cast(u32);
def DnsFreeParsedMessageFields = 2 cast(u32);

struct DNS_A_DATA
{
    IpAddress u32;
}

struct DNS_RECORD
{
    pNext DNS_RECORD ref;
    pName u8 ref;
    wType u16;
    wDataLength u16;    // Not referenced for DNS record types
                                            // defined above.
    Flags union
    {
        DW u32;     // flags as DWORD
        S  u32;     // flags as structure
    };

    dwTtl u32 ;
    dwReserved u32;

    //  Record Data

    Data union
    {
        A DNS_A_DATA;

        values u8[56];

        multiline_comment
        {
        DNS_SOA_DATAW       SOA, Soa;
        DNS_PTR_DATAW       PTR, Ptr,
                            NS, Ns,
                            CNAME, Cname,
                            DNAME, Dname,
                            MB, Mb,
                            MD, Md,
                            MF, Mf,
                            MG, Mg,
                            MR, Mr;
        DNS_MINFO_DATAW     MINFO, Minfo,
                            RP, Rp;
        DNS_MX_DATAW        MX, Mx,
                            AFSDB, Afsdb,
                            RT, Rt;
        DNS_TXT_DATAW       HINFO, Hinfo,
                            ISDN, Isdn,
                            TXT, Txt,
                            X25;
        DNS_NULL_DATA       Null;
        DNS_WKS_DATA        WKS, Wks;
        DNS_AAAA_DATA       AAAA;
        DNS_KEY_DATA        KEY, Key;
        DNS_SIG_DATAW       SIG, Sig;
        DNS_ATMA_DATA       ATMA, Atma;
        DNS_NXT_DATAW       NXT, Nxt;
        DNS_SRV_DATAW       SRV, Srv;
        DNS_NAPTR_DATAW     NAPTR, Naptr;
        DNS_OPT_DATA        OPT, Opt;
        DNS_DS_DATA         DS, Ds;
        DNS_RRSIG_DATAW     RRSIG, Rrsig;
        DNS_NSEC_DATAW      NSEC, Nsec;
        DNS_DNSKEY_DATA     DNSKEY, Dnskey;
        DNS_TKEY_DATAW      TKEY, Tkey;
        DNS_TSIG_DATAW      TSIG, Tsig;
        DNS_WINS_DATA       WINS, Wins;
        DNS_WINSR_DATAW     WINSR, WinsR, NBSTAT, Nbstat;
        DNS_DHCID_DATA      DHCID;
        DNS_NSEC3_DATA      NSEC3, Nsec3;
        DNS_NSEC3PARAM_DATA	NSEC3PARAM, Nsec3Param;
        DNS_TLSA_DATA	    TLSA, Tlsa;
        DNS_UNKNOWN_DATA    UNKNOWN, Unknown;
        PBYTE               pDataPtr;
        }
    };
}