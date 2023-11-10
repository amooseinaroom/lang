
module audio;

import platform;
import fmod_audio;

struct audio_system
{
    fmod FMOD_SYSTEM ref;
}

struct audio_sound
{
    fmod FMOD_SOUND ref;
    looping b8;
}

struct audio_track
{
    fmod FMOD_CHANNEL ref;
}

struct audio_group
{
    fmod FMOD_CHANNELGROUP ref;
}

func init(audio audio_system ref)
{
    fmod_require(FMOD_System_Create(audio.fmod ref, FMOD_VERSION));
    fmod_require(FMOD_System_Init(audio.fmod, 512, FMOD_INIT_NORMAL, null));
}

func frame(audio audio_system ref)
{
    fmod_require(FMOD_System_Update(audio.fmod));
}

func load(audio audio_system ref, path cstring, looping = false) (sound audio_sound)
{
    var sound FMOD_SOUND ref;
    
    var mode = FMOD_LOOP_OFF;
    if looping
        mode = FMOD_LOOP_NORMAL;
    
    fmod_require(FMOD_System_CreateSound(audio.fmod, path, mode, null, sound ref));
    
    return { sound, looping } audio_sound;
}

func create_group(audio audio_system ref) (group audio_group)
{
    var group FMOD_CHANNELGROUP ref;
    fmod_require(FMOD_System_CreateChannelGroup(audio.fmod, null, group ref));
    return { group } audio_group;
}

func play(audio audio_system ref, group = {} audio_group, sound audio_sound, do_loop b8 = false, volume = 1.0, pitch = 1.0) (track audio_track)
{
    assert(not do_loop or sound.looping, "sound needs to me loaded with looping = true");
    
    var channel FMOD_CHANNEL ref;
    fmod_require(FMOD_System_PlaySound(audio.fmod, sound.fmod, group.fmod, do_loop cast(FMOD_BOOL), channel ref));
    fmod_require(FMOD_Channel_SetVolume(channel, volume));
    fmod_require(FMOD_Channel_SetPitch(channel, pitch));
    
    if do_loop
    {
        fmod_require(FMOD_Channel_SetLoopCount(channel, -1));
        fmod_require(FMOD_Channel_SetPaused(channel, false cast(FMOD_BOOL)));
    }
    
    return { channel } audio_track;
}

func stop_loop(audio audio_system ref, track audio_track ref)
{
    //fmod_require(FMOD_Channel_Stop(track.fmod));
    fmod_require(FMOD_Channel_SetLoopCount(track.fmod, 0));
    track.fmod = null;
}

func is_valid(audio audio_system ref, track audio_track) (ok b8)
{
    var is_playing FMOD_BOOL;
    // this is such a bad function, basically returns all kinds of reasons why the sound is no longer valid,
    // but we only care if it is valid or not
    var result = FMOD_Channel_IsPlaying(track.fmod, is_playing ref);
    if result is_not FMOD_RESULT.FMOD_OK
        return false;
        
    return is_playing;
}

func set_pause(audio audio_system ref, group audio_group ref, is_paused b8)
{
    fmod_require(FMOD_Channel_SetPaused(group.fmod, is_paused cast(FMOD_BOOL)));
}

func clear(audio audio_system ref, group audio_group ref)
{
    fmod_require(FMOD_ChannelGroup_Stop(group.fmod));
}

func fmod_require(result FMOD_RESULT, result_text = get_call_argument_text(result), location = get_call_location())
{
    require(result is FMOD_RESULT.FMOD_OK, result_text, location, "FMOD_RESULT is %", result);
}