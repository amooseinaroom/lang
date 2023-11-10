
#include "steam_api.h"

typedef unsigned char      u8;
typedef unsigned int       u32;
typedef unsigned long long u64;
typedef u8 b8;

typedef int       s32;

// assuming x64
typedef u64 usize;

typedef char * cstring;

#define carray_count(static_array) ( sizeof(static_array) / sizeof(*(static_array)) )

#define require(x) if (!(x)) { *(int *) 0 = 0; }

#if _DEBUG
#define assert(x) require(x)
#else
#define assert(x) 
#endif

// same size as CSteamID, but we can't use CSteamID directly since it's a c++ class and we want a C interface
typedef u64 steam_id;

extern "C" {

const int steam_max_lobby_member_count = 250;

struct u8_array
{
	usize count;
	u8    *base;	
};

typedef u8_array string;

struct steam_network_receive_result
{
	steam_id id;
	u8_array data;	
};

// wrapper

#define SteamMatchmakingRequestLobbyList_signature SteamAPICall_t SteamMatchmakingRequestLobbyList()
SteamMatchmakingRequestLobbyList_signature;

#define SteamMatchmakingCreateLobby_signature SteamAPICall_t SteamMatchmakingCreateLobby(ELobbyType lobby_type, s32 max_member_count)
SteamMatchmakingCreateLobby_signature;

#define SteamMatchmakingJoinLobby_signature SteamAPICall_t SteamMatchmakingJoinLobby(steam_id lobby_id)
SteamMatchmakingJoinLobby_signature;

#define SteamMatchmakingLeaveLobby_signature void SteamMatchmakingLeaveLobby(steam_id lobby_id)
SteamMatchmakingLeaveLobby_signature;

#define SteamUserGetSteamID_signature steam_id SteamUserGetSteamID()
SteamUserGetSteamID_signature;

#define SteamMatchmakingGetNumLobbyMembers_signature s32 SteamMatchmakingGetNumLobbyMembers(steam_id lobby_id)
SteamMatchmakingGetNumLobbyMembers_signature;

#define SteamMatchmakingGetLobbyMemberByIndex_signature steam_id SteamMatchmakingGetLobbyMemberByIndex(steam_id lobby_id, s32 member_index)
SteamMatchmakingGetLobbyMemberByIndex_signature;

#define SteamMatchmakingGetLobbyByIndex_signature steam_id SteamMatchmakingGetLobbyByIndex(s32 lobby_index)
SteamMatchmakingGetLobbyByIndex_signature;

#define SteamFriendsGetFriendPersonaName_signature char * SteamFriendsGetFriendPersonaName(steam_id user_id)
SteamFriendsGetFriendPersonaName_signature;

// alternative wrapper

// data needs to be 0 terminated
#define steam_matchmaking_set_lobby_member_data_signature void steam_matchmaking_set_lobby_member_data(steam_id lobby_id, cstring key, u8_array data)
steam_matchmaking_set_lobby_member_data_signature;

#define steam_matchmaking_get_lobby_member_data_signature u8_array steam_matchmaking_get_lobby_member_data(steam_id lobby_id, steam_id user_id, u8_array buffer, cstring key)
steam_matchmaking_get_lobby_member_data_signature;

// same as SteamNetworkingMessagesSendMessageToUser but using CSteamID instead of SteamNetworkingIdentity and u8_array for data
#define steam_network_send_signature void steam_network_send(steam_id user_id, u8_array data, s32 send_flags, s32 remote_channel)
steam_network_send_signature;

// same as SteamNetworkingMessages()->ReceiveMessagesOnChannel but receives only one message and writes it into the provided buffer
#define steam_network_receive_signature steam_network_receive_result steam_network_receive(s32 local_channel, u8_array buffer)
steam_network_receive_signature;

}

// implementation

SteamUserGetSteamID_signature
{
	CSteamID id = SteamUser()->GetSteamID();
	return *(steam_id *) &id;
}

SteamMatchmakingRequestLobbyList_signature
{
	SteamAPICall_t call = SteamMatchmaking()->RequestLobbyList();
	return call;
}

SteamMatchmakingGetLobbyByIndex_signature
{
	CSteamID lobby_id = SteamMatchmaking()->GetLobbyByIndex(lobby_index);
	return *(steam_id *) &lobby_id;
}

SteamMatchmakingCreateLobby_signature
{
	assert(max_member_count <= steam_max_lobby_member_count);
	SteamAPICall_t call = SteamMatchmaking()->CreateLobby(lobby_type, max_member_count);
	return call;
}

SteamMatchmakingJoinLobby_signature
{
	SteamAPICall_t call = SteamMatchmaking()->JoinLobby(*(CSteamID *) &lobby_id);
	return call;
}

SteamMatchmakingLeaveLobby_signature
{
	SteamMatchmaking()->LeaveLobby(*(CSteamID *) &lobby_id);
}

SteamMatchmakingGetNumLobbyMembers_signature
{
	CSteamID id = *(CSteamID *) &lobby_id;
	s32 member_count = SteamMatchmaking()->GetNumLobbyMembers(id);
	return member_count;
}

SteamMatchmakingGetLobbyMemberByIndex_signature
{
	CSteamID id = *(CSteamID *) &lobby_id;
	CSteamID user_id = SteamMatchmaking()->GetLobbyMemberByIndex(lobby_id, member_index);	
	return *(steam_id *) &user_id;
}

SteamFriendsGetFriendPersonaName_signature
{
	char *name = (char *) SteamFriends()->GetFriendPersonaName(*(CSteamID *) &user_id);
	return name;
}

steam_matchmaking_set_lobby_member_data_signature
{	
	assert(data.count);

	// make shure all bytes are send
	for (u32 i = 0; i < data.count - 1; i++)
	{
		assert(data.base[i] != 0);
	}

	assert(data.base[data.count - 1] == 0);

	SteamMatchmaking()->SetLobbyMemberData(*(CSteamID *) &lobby_id, key, (cstring) data.base);
}

steam_matchmaking_get_lobby_member_data_signature
{	
	cstring data = (cstring) SteamMatchmaking()->GetLobbyMemberData(*(CSteamID *) &lobby_id, *(CSteamID *) &user_id, key);
	assert(data);

	u8_array result = { 0, buffer.base };
	while (*data)
	{
		assert(result.count < buffer.count);
		result.base[result.count] = *data;
		result.count++;
		data++;
	}

	// all bytes received
	assert(result.count == buffer.count);

	return result;
}

steam_network_send_signature
{	
	SteamNetworkingIdentity destination_identity;
	destination_identity.SetSteamID(*(CSteamID *) &user_id);

	EResult result = SteamNetworkingMessages()->SendMessageToUser(destination_identity, data.base, (u32) data.count, send_flags, remote_channel);

	// not sure how to handle errors

	if (result == k_EResultNoConnection)
		SteamNetworkingMessages()->CloseSessionWithUser(destination_identity);			
	
#if 0
	switch (result)
	{
	case k_EResultOK:
	case k_EResultIgnored:
	case k_EResultLimitExceeded:
	case k_EResultConnectFailed:
	{	
	} break;

	case k_EResultNoConnection:
	{
		SteamNetworkingMessages()->CloseSessionWithUser(destination_identity);		
	} break;

	default:
		assert(false);
	}
#endif
}

steam_network_receive_signature
{
	steam_network_receive_result result = {};

	SteamNetworkingMessage_t *message;
	int message_count = SteamNetworkingMessages()->ReceiveMessagesOnChannel(local_channel, &message, 1);
	if (message_count)
	{
		assert(message->m_cbSize <= buffer.count);
		memcpy(buffer.base, message->m_pData, message->m_cbSize);

		CSteamID source_id = message->m_identityPeer.GetSteamID();
		result.data.base  = buffer.base;
		result.data.count = message->m_cbSize;
		result.id = *(steam_id *) &source_id;

		message->Release();
	}

	return result;
}