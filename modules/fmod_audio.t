
module fmod_audio;

def FMOD_VERSION = 0x00020209 cast(u32);

func FMOD_System_Create(system FMOD_SYSTEM ref ref, headerversion u32) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_System_Init(system FMOD_SYSTEM ref, maxchannels s32, flags FMOD_INITFLAGS, extradriverdata u8 ref) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_System_Release(system FMOD_SYSTEM ref) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_System_Update(system FMOD_SYSTEM ref) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_System_CreateSound(system FMOD_SYSTEM ref, name_or_data cstring, mode FMOD_MODE, exinfo FMOD_CREATESOUNDEXINFO ref, sound FMOD_SOUND ref ref) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_System_PlaySound(system FMOD_SYSTEM ref, sound FMOD_SOUND ref, channelgroup FMOD_CHANNELGROUP ref, paused FMOD_BOOL, channel FMOD_CHANNEL ref ref) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_Channel_IsPlaying(channel FMOD_CHANNEL ref, is_playing FMOD_BOOL ref) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_Channel_Stop(channel FMOD_CHANNEL ref) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_Channel_SetPitch(channel FMOD_CHANNEL ref, pitch f32) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_Channel_SetVolume(channel FMOD_CHANNEL ref, volume f32) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_Channel_SetLoopCount(channel FMOD_CHANNEL ref, loopcount s32) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_Channel_SetPaused(channel FMOD_CHANNEL ref, paused FMOD_BOOL) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_System_CreateChannelGroup(system FMOD_SYSTEM ref, name cstring, channelgroup FMOD_CHANNELGROUP ref ref) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_ChannelGroup_Stop(channelgroup FMOD_CHANNELGROUP ref) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

func FMOD_ChannelGroup_SetPaused(channelgroup FMOD_CHANNELGROUP ref, paused FMOD_BOOL) (result FMOD_RESULT) calling_convention "__stdcall" extern_binding("fmod_vc", true);

// opaque structures, only used via reference
type FMOD_SYSTEM       u8;
type FMOD_SOUND        u8;
type FMOD_CHANNEL      u8;
type FMOD_CHANNELGROUP u8;

// not opaque, but not used yet
type FMOD_CREATESOUNDEXINFO u8;

type FMOD_BOOL s32;

enum FMOD_RESULT u32
{
    FMOD_OK;
    FMOD_ERR_BADCOMMAND;
    FMOD_ERR_CHANNEL_ALLOC;
    FMOD_ERR_CHANNEL_STOLEN;
    FMOD_ERR_DMA;
    FMOD_ERR_DSP_CONNECTION;
    FMOD_ERR_DSP_DONTPROCESS;
    FMOD_ERR_DSP_FORMAT;
    FMOD_ERR_DSP_INUSE;
    FMOD_ERR_DSP_NOTFOUND;
    FMOD_ERR_DSP_RESERVED;
    FMOD_ERR_DSP_SILENCE;
    FMOD_ERR_DSP_TYPE;
    FMOD_ERR_FILE_BAD;
    FMOD_ERR_FILE_COULDNOTSEEK;
    FMOD_ERR_FILE_DISKEJECTED;
    FMOD_ERR_FILE_EOF;
    FMOD_ERR_FILE_ENDOFDATA;
    FMOD_ERR_FILE_NOTFOUND;
    FMOD_ERR_FORMAT;
    FMOD_ERR_HEADER_MISMATCH;
    FMOD_ERR_HTTP;
    FMOD_ERR_HTTP_ACCESS;
    FMOD_ERR_HTTP_PROXY_AUTH;
    FMOD_ERR_HTTP_SERVER_ERROR;
    FMOD_ERR_HTTP_TIMEOUT;
    FMOD_ERR_INITIALIZATION;
    FMOD_ERR_INITIALIZED;
    FMOD_ERR_INTERNAL;
    FMOD_ERR_INVALID_FLOAT;
    FMOD_ERR_INVALID_HANDLE;
    FMOD_ERR_INVALID_PARAM;
    FMOD_ERR_INVALID_POSITION;
    FMOD_ERR_INVALID_SPEAKER;
    FMOD_ERR_INVALID_SYNCPOINT;
    FMOD_ERR_INVALID_THREAD;
    FMOD_ERR_INVALID_VECTOR;
    FMOD_ERR_MAXAUDIBLE;
    FMOD_ERR_MEMORY;
    FMOD_ERR_MEMORY_CANTPOINT;
    FMOD_ERR_NEEDS3D;
    FMOD_ERR_NEEDSHARDWARE;
    FMOD_ERR_NET_CONNECT;
    FMOD_ERR_NET_SOCKET_ERROR;
    FMOD_ERR_NET_URL;
    FMOD_ERR_NET_WOULD_BLOCK;
    FMOD_ERR_NOTREADY;
    FMOD_ERR_OUTPUT_ALLOCATED;
    FMOD_ERR_OUTPUT_CREATEBUFFER;
    FMOD_ERR_OUTPUT_DRIVERCALL;
    FMOD_ERR_OUTPUT_FORMAT;
    FMOD_ERR_OUTPUT_INIT;
    FMOD_ERR_OUTPUT_NODRIVERS;
    FMOD_ERR_PLUGIN;
    FMOD_ERR_PLUGIN_MISSING;
    FMOD_ERR_PLUGIN_RESOURCE;
    FMOD_ERR_PLUGIN_VERSION;
    FMOD_ERR_RECORD;
    FMOD_ERR_REVERB_CHANNELGROUP;
    FMOD_ERR_REVERB_INSTANCE;
    FMOD_ERR_SUBSOUNDS;
    FMOD_ERR_SUBSOUND_ALLOCATED;
    FMOD_ERR_SUBSOUND_CANTMOVE;
    FMOD_ERR_TAGNOTFOUND;
    FMOD_ERR_TOOMANYCHANNELS;
    FMOD_ERR_TRUNCATED;
    FMOD_ERR_UNIMPLEMENTED;
    FMOD_ERR_UNINITIALIZED;
    FMOD_ERR_UNSUPPORTED;
    FMOD_ERR_VERSION;
    FMOD_ERR_EVENT_ALREADY_LOADED;
    FMOD_ERR_EVENT_LIVEUPDATE_BUSY;
    FMOD_ERR_EVENT_LIVEUPDATE_MISMATCH;
    FMOD_ERR_EVENT_LIVEUPDATE_TIMEOUT;
    FMOD_ERR_EVENT_NOTFOUND;
    FMOD_ERR_STUDIO_UNINITIALIZED;
    FMOD_ERR_STUDIO_NOT_LOADED;
    FMOD_ERR_INVALID_STRING;
    FMOD_ERR_ALREADY_LOCKED;
    FMOD_ERR_NOT_LOCKED;
    FMOD_ERR_RECORD_DISCONNECTED;
    FMOD_ERR_TOOMANYSAMPLES;
}

type FMOD_STUDIO_INITFLAGS u32;
def FMOD_STUDIO_INIT_NORMAL                = 0x00000000 cast(FMOD_STUDIO_INITFLAGS);
def FMOD_STUDIO_INIT_LIVEUPDATE            = 0x00000001 cast(FMOD_STUDIO_INITFLAGS);
def FMOD_STUDIO_INIT_ALLOW_MISSING_PLUGINS = 0x00000002 cast(FMOD_STUDIO_INITFLAGS);
def FMOD_STUDIO_INIT_SYNCHRONOUS_UPDATE    = 0x00000004 cast(FMOD_STUDIO_INITFLAGS);
def FMOD_STUDIO_INIT_DEFERRED_CALLBACKS    = 0x00000008 cast(FMOD_STUDIO_INITFLAGS);
def FMOD_STUDIO_INIT_LOAD_FROM_UPDATE      = 0x00000010 cast(FMOD_STUDIO_INITFLAGS);
def FMOD_STUDIO_INIT_MEMORY_TRACKING       = 0x00000020 cast(FMOD_STUDIO_INITFLAGS);

type FMOD_INITFLAGS u32;
def FMOD_INIT_NORMAL                     = 0x00000000 cast(FMOD_INITFLAGS);
def FMOD_INIT_STREAM_FROM_UPDATE         = 0x00000001 cast(FMOD_INITFLAGS);
def FMOD_INIT_MIX_FROM_UPDATE            = 0x00000002 cast(FMOD_INITFLAGS);
def FMOD_INIT_3D_RIGHTHANDED             = 0x00000004 cast(FMOD_INITFLAGS);
def FMOD_INIT_CLIP_OUTPUT                = 0x00000008 cast(FMOD_INITFLAGS);
def FMOD_INIT_CHANNEL_LOWPASS            = 0x00000100 cast(FMOD_INITFLAGS);
def FMOD_INIT_CHANNEL_DISTANCEFILTER     = 0x00000200 cast(FMOD_INITFLAGS);
def FMOD_INIT_PROFILE_ENABLE             = 0x00010000 cast(FMOD_INITFLAGS);
def FMOD_INIT_VOL0_BECOMES_VIRTUAL       = 0x00020000 cast(FMOD_INITFLAGS);
def FMOD_INIT_GEOMETRY_USECLOSEST        = 0x00040000 cast(FMOD_INITFLAGS);
def FMOD_INIT_PREFER_DOLBY_DOWNMIX       = 0x00080000 cast(FMOD_INITFLAGS);
def FMOD_INIT_THREAD_UNSAFE              = 0x00100000 cast(FMOD_INITFLAGS);
def FMOD_INIT_PROFILE_METER_ALL          = 0x00200000 cast(FMOD_INITFLAGS);
def FMOD_INIT_MEMORY_TRACKING            = 0x00400000 cast(FMOD_INITFLAGS);

type FMOD_MODE u32;
def FMOD_DEFAULT                    = 0x00000000 cast(FMOD_MODE);
def FMOD_LOOP_OFF                   = 0x00000001 cast(FMOD_MODE);
def FMOD_LOOP_NORMAL                = 0x00000002 cast(FMOD_MODE);
def FMOD_LOOP_BIDI                  = 0x00000004 cast(FMOD_MODE);
def FMOD_2D                         = 0x00000008 cast(FMOD_MODE);
def FMOD_3D                         = 0x00000010 cast(FMOD_MODE);
def FMOD_CREATESTREAM               = 0x00000080 cast(FMOD_MODE);
def FMOD_CREATESAMPLE               = 0x00000100 cast(FMOD_MODE);
def FMOD_CREATECOMPRESSEDSAMPLE     = 0x00000200 cast(FMOD_MODE);
def FMOD_OPENUSER                   = 0x00000400 cast(FMOD_MODE);
def FMOD_OPENMEMORY                 = 0x00000800 cast(FMOD_MODE);
def FMOD_OPENMEMORY_POINT           = 0x10000000 cast(FMOD_MODE);
def FMOD_OPENRAW                    = 0x00001000 cast(FMOD_MODE);
def FMOD_OPENONLY                   = 0x00002000 cast(FMOD_MODE);
def FMOD_ACCURATETIME               = 0x00004000 cast(FMOD_MODE);
def FMOD_MPEGSEARCH                 = 0x00008000 cast(FMOD_MODE);
def FMOD_NONBLOCKING                = 0x00010000 cast(FMOD_MODE);
def FMOD_UNIQUE                     = 0x00020000 cast(FMOD_MODE);
def FMOD_3D_HEADRELATIVE            = 0x00040000 cast(FMOD_MODE);
def FMOD_3D_WORLDRELATIVE           = 0x00080000 cast(FMOD_MODE);
def FMOD_3D_INVERSEROLLOFF          = 0x00100000 cast(FMOD_MODE);
def FMOD_3D_LINEARROLLOFF           = 0x00200000 cast(FMOD_MODE);
def FMOD_3D_LINEARSQUAREROLLOFF     = 0x00400000 cast(FMOD_MODE);
def FMOD_3D_INVERSETAPEREDROLLOFF   = 0x00800000 cast(FMOD_MODE);
def FMOD_3D_CUSTOMROLLOFF           = 0x04000000 cast(FMOD_MODE);
def FMOD_3D_IGNOREGEOMETRY          = 0x40000000 cast(FMOD_MODE);
def FMOD_IGNORETAGS                 = 0x02000000 cast(FMOD_MODE);
def FMOD_LOWMEM                     = 0x08000000 cast(FMOD_MODE);
def FMOD_VIRTUAL_PLAYFROMSTART      = 0x80000000 cast(FMOD_MODE);