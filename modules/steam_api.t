
// Steam API - from steam sdk 157

module steam_api;

type HSteamPipe s32;
type HSteamUser s32;

type SteamAPICall_t u64;
type CSteamID       u64;

def k_uAPICallInvalid = 0x0 cast(SteamAPICall_t);

type ELobbyType u32;
def k_ELobbyTypePrivate     = 0 cast(ELobbyType);
def k_ELobbyTypeFriendsOnly = 1 cast(ELobbyType);
def k_ELobbyTypePublic      = 2 cast(ELobbyType);
def k_ELobbyTypeInvisible   = 3 cast(ELobbyType);

type EResult u32;
def k_EResultNone = 0 cast(EResult);							// no result
def k_EResultOK	= 1 cast(EResult);							// success
def k_EResultFail = 2 cast(EResult);							// generic failure 
def k_EResultNoConnection = 3 cast(EResult);					// no/failed network connection
//	def k_EResultNoConnectionRetry = 4 cast(EResult);				// OBSOLETE - removed
def k_EResultInvalidPassword = 5 cast(EResult);				// password/ticket is invalid
def k_EResultLoggedInElsewhere = 6 cast(EResult);				// same user logged in elsewhere
def k_EResultInvalidProtocolVer = 7 cast(EResult);			// protocol version is incorrect
def k_EResultInvalidParam = 8 cast(EResult);					// a parameter is incorrect
def k_EResultFileNotFound = 9 cast(EResult);					// file was not found
def k_EResultBusy = 10 cast(EResult);							// called method busy - action not taken
def k_EResultInvalidState = 11 cast(EResult);					// called object was in an invalid state
def k_EResultInvalidName = 12 cast(EResult);					// name is invalid
def k_EResultInvalidEmail = 13 cast(EResult);					// email is invalid
def k_EResultDuplicateName = 14 cast(EResult);				// name is not unique
def k_EResultAccessDenied = 15 cast(EResult);					// access is denied
def k_EResultTimeout = 16 cast(EResult);						// operation timed out
def k_EResultBanned = 17 cast(EResult);						// VAC2 banned
def k_EResultAccountNotFound = 18 cast(EResult);				// account not found
def k_EResultInvalidSteamID = 19 cast(EResult);				// steamID is invalid
def k_EResultServiceUnavailable = 20 cast(EResult);			// The requested service is currently unavailable
def k_EResultNotLoggedOn = 21 cast(EResult);					// The user is not logged on
def k_EResultPending = 22 cast(EResult);						// Request is pending (may be in process cast(EResult); or waiting on third party)
def k_EResultEncryptionFailure = 23 cast(EResult);			// Encryption or Decryption failed
def k_EResultInsufficientPrivilege = 24 cast(EResult);		// Insufficient privilege
def k_EResultLimitExceeded = 25 cast(EResult);				// Too much of a good thing
def k_EResultRevoked = 26 cast(EResult);						// Access has been revoked (used for revoked guest passes)
def k_EResultExpired = 27 cast(EResult);						// License/Guest pass the user is trying to access is expired
def k_EResultAlreadyRedeemed = 28 cast(EResult);				// Guest pass has already been redeemed by account cast(EResult); cannot be acked again
def k_EResultDuplicateRequest = 29 cast(EResult);				// The request is a duplicate and the action has already occurred in the past cast(EResult); ignored this time
def k_EResultAlreadyOwned = 30 cast(EResult);					// All the games in this guest pass redemption request are already owned by the user
def k_EResultIPNotFound = 31 cast(EResult);					// IP address not found
def k_EResultPersistFailed = 32 cast(EResult);				// failed to write change to the data store
def k_EResultLockingFailed = 33 cast(EResult);				// failed to acquire access lock for this operation
def k_EResultLogonSessionReplaced = 34 cast(EResult);
def k_EResultConnectFailed = 35 cast(EResult);
def k_EResultHandshakeFailed = 36 cast(EResult);
def k_EResultIOFailure = 37 cast(EResult);
def k_EResultRemoteDisconnect = 38 cast(EResult);
def k_EResultShoppingCartNotFound = 39 cast(EResult);			// failed to find the shopping cart requested
def k_EResultBlocked = 40 cast(EResult);						// a user didn't allow it
def k_EResultIgnored = 41 cast(EResult);						// target is ignoring sender
def k_EResultNoMatch = 42 cast(EResult);						// nothing matching the request found
def k_EResultAccountDisabled = 43 cast(EResult);
def k_EResultServiceReadOnly = 44 cast(EResult);				// this service is not accepting content changes right now
def k_EResultAccountNotFeatured = 45 cast(EResult);			// account doesn't have value cast(EResult); so this feature isn't available
def k_EResultAdministratorOK = 46 cast(EResult);				// allowed to take this action cast(EResult); but only because requester is admin
def k_EResultContentVersion = 47 cast(EResult);				// A Version mismatch in content transmitted within the Steam protocol.
def k_EResultTryAnotherCM = 48 cast(EResult);					// The current CM can't service the user making a request cast(EResult); user should try another.
def k_EResultPasswordRequiredToKickSession = 49 cast(EResult);// You are already logged in elsewhere cast(EResult); this cached credential login has failed.
def k_EResultAlreadyLoggedInElsewhere = 50 cast(EResult);		// You are already logged in elsewhere cast(EResult); you must wait
def k_EResultSuspended = 51 cast(EResult);					// Long running operation (content download) suspended/paused
def k_EResultCancelled = 52 cast(EResult);					// Operation canceled (typically by user: content download)
def k_EResultDataCorruption = 53 cast(EResult);				// Operation canceled because data is ill formed or unrecoverable
def k_EResultDiskFull = 54 cast(EResult);						// Operation canceled - not enough disk space.
def k_EResultRemoteCallFailed = 55 cast(EResult);				// an remote call or IPC call failed
def k_EResultPasswordUnset = 56 cast(EResult);				// Password could not be verified as it's unset server side
def k_EResultExternalAccountUnlinked = 57 cast(EResult);		// External account (PSN cast(EResult); Facebook...) is not linked to a Steam account
def k_EResultPSNTicketInvalid = 58 cast(EResult);				// PSN ticket was invalid
def k_EResultExternalAccountAlreadyLinked = 59 cast(EResult);	// External account (PSN cast(EResult); Facebook...) is already linked to some other account cast(EResult); must explicitly request to replace/delete the link first
def k_EResultRemoteFileConflict = 60 cast(EResult);			// The sync cannot resume due to a conflict between the local and remote files
def k_EResultIllegalPassword = 61 cast(EResult);				// The requested new password is not legal
def k_EResultSameAsPreviousValue = 62 cast(EResult);			// new value is the same as the old one ( secret question and answer )
def k_EResultAccountLogonDenied = 63 cast(EResult);			// account login denied due to 2nd factor authentication failure
def k_EResultCannotUseOldPassword = 64 cast(EResult);			// The requested new password is not legal
def k_EResultInvalidLoginAuthCode = 65 cast(EResult);			// account login denied due to auth code invalid
def k_EResultAccountLogonDeniedNoMail = 66 cast(EResult);		// account login denied due to 2nd factor auth failure - and no mail has been sent - partner site specific
def k_EResultHardwareNotCapableOfIPT = 67 cast(EResult);		// 
def k_EResultIPTInitError = 68 cast(EResult);					// 
def k_EResultParentalControlRestricted = 69 cast(EResult);	// operation failed due to parental control restrictions for current user
def k_EResultFacebookQueryError = 70 cast(EResult);			// Facebook query returned an error
def k_EResultExpiredLoginAuthCode = 71 cast(EResult);			// account login denied due to auth code expired
def k_EResultIPLoginRestrictionFailed = 72 cast(EResult);
def k_EResultAccountLockedDown = 73 cast(EResult);
def k_EResultAccountLogonDeniedVerifiedEmailRequired = 74 cast(EResult);
def k_EResultNoMatchingURL = 75 cast(EResult);
def k_EResultBadResponse = 76 cast(EResult);					// parse failure cast(EResult); missing field cast(EResult); etc.
def k_EResultRequirePasswordReEntry = 77 cast(EResult);		// The user cannot complete the action until they re-enter their password
def k_EResultValueOutOfRange = 78 cast(EResult);				// the value entered is outside the acceptable range
def k_EResultUnexpectedError = 79 cast(EResult);				// something happened that we didn't expect to ever happen
def k_EResultDisabled = 80 cast(EResult);						// The requested service has been configured to be unavailable
def k_EResultInvalidCEGSubmission = 81 cast(EResult);			// The set of files submitted to the CEG server are not valid !
def k_EResultRestrictedDevice = 82 cast(EResult);				// The device being used is not allowed to perform this action
def k_EResultRegionLocked = 83 cast(EResult);					// The action could not be complete because it is region restricted
def k_EResultRateLimitExceeded = 84 cast(EResult);			// Temporary rate limit exceeded cast(EResult); try again later cast(EResult); different from def k_EResultLimitExceeded which may be permanent
def k_EResultAccountLoginDeniedNeedTwoFactor = 85 cast(EResult);	// Need two-factor code to login
def k_EResultItemDeleted = 86 cast(EResult);					// The thing we're trying to access has been deleted
def k_EResultAccountLoginDeniedThrottle = 87 cast(EResult);	// login attempt failed cast(EResult); try to throttle response to possible attacker
def k_EResultTwoFactorCodeMismatch = 88 cast(EResult);		// two factor code mismatch
def k_EResultTwoFactorActivationCodeMismatch = 89 cast(EResult);	// activation code for two-factor didn't match
def k_EResultAccountAssociatedToMultiplePartners = 90 cast(EResult);	// account has been associated with multiple partners
def k_EResultNotModified = 91 cast(EResult);					// data not modified
def k_EResultNoMobileDevice = 92 cast(EResult);				// the account does not have a mobile device associated with it
def k_EResultTimeNotSynced = 93 cast(EResult);				// the time presented is out of range or tolerance
def k_EResultSmsCodeFailed = 94 cast(EResult);				// SMS code failure (no match cast(EResult); none pending cast(EResult); etc.)
def k_EResultAccountLimitExceeded = 95 cast(EResult);			// Too many accounts access this resource
def k_EResultAccountActivityLimitExceeded = 96 cast(EResult);	// Too many changes to this account
def k_EResultPhoneActivityLimitExceeded = 97 cast(EResult);	// Too many changes to this phone
def k_EResultRefundToWallet = 98 cast(EResult);				// Cannot refund to payment method cast(EResult); must use wallet
def k_EResultEmailSendFailure = 99 cast(EResult);				// Cannot send an email
def k_EResultNotSettled = 100 cast(EResult);					// Can't perform operation till payment has settled
def k_EResultNeedCaptcha = 101 cast(EResult);					// Needs to provide a valid captcha
def k_EResultGSLTDenied = 102 cast(EResult);					// a game server login token owned by this token's owner has been banned
def k_EResultGSOwnerDenied = 103 cast(EResult);				// game server owner is denied for other reason (account lock cast(EResult); community ban cast(EResult); vac ban cast(EResult); missing phone)
def k_EResultInvalidItemType = 104 cast(EResult);				// the type of thing we were requested to act on is invalid
def k_EResultIPBanned = 105 cast(EResult);					// the ip address has been banned from taking this action
def k_EResultGSLTExpired = 106 cast(EResult);					// this token has expired from disuse; can be reset for use
def k_EResultInsufficientFunds = 107 cast(EResult);			// user doesn't have enough wallet funds to complete the action
def k_EResultTooManyPending = 108 cast(EResult);				// There are too many of this thing pending already
def k_EResultNoSiteLicensesFound = 109 cast(EResult);			// No site licenses found
def k_EResultWGNetworkSendExceeded = 110 cast(EResult);		// the WG couldn't send a response because we exceeded max network send size
def k_EResultAccountNotFriends = 111 cast(EResult);			// the user is not mutually friends
def k_EResultLimitedUserAccount = 112 cast(EResult);			// the user is limited
def k_EResultCantRemoveItem = 113 cast(EResult);				// item can't be removed
def k_EResultAccountDeleted = 114 cast(EResult);				// account has been deleted
def k_EResultExistingUserCancelledLicense = 115 cast(EResult);	// A license for this already exists cast(EResult); but cancelled
def k_EResultCommunityCooldown = 116 cast(EResult);			// access is denied because of a community cooldown (probably from support profile data resets)
def k_EResultNoLauncherSpecified = 117 cast(EResult);			// No launcher was specified cast(EResult); but a launcher was needed to choose correct realm for operation.
def k_EResultMustAgreeToSSA = 118 cast(EResult);				// User must agree to china SSA or global SSA before login
def k_EResultLauncherMigrated = 119 cast(EResult);			// The specified launcher type is no longer supported; the user should be directed elsewhere
def k_EResultSteamRealmMismatch = 120 cast(EResult);			// The user's realm does not match the realm of the requested resource
def k_EResultInvalidSignature = 121 cast(EResult);			// signature check did not match
def k_EResultParseFailure = 122 cast(EResult);				// Failed to parse input
def k_EResultNoVerifiedPhone = 123 cast(EResult);				// account does not have a verified phone number
def k_EResultInsufficientBattery = 124 cast(EResult);			// user device doesn't have enough battery charge currently to complete the action
def k_EResultChargerRequired = 125 cast(EResult);				// The operation requires a charger to be plugged in cast(EResult); which wasn't present
def k_EResultCachedCredentialInvalid = 126 cast(EResult);		// Cached credential was invalid - user must reauthenticate
def K_EResultPhoneNumberIsVOIP = 127 cast(EResult);			// The phone number provided is a Voice Over IP number


def k_nSteamNetworkingSend_Unreliable = 0 cast(s32);
def k_nSteamNetworkingSend_NoNagle    = 1 cast(s32);
def k_nSteamNetworkingSend_NoDelay    = 4 cast(s32);
def k_nSteamNetworkingSend_Reliable   = 8 cast(s32);
def k_nSteamNetworkingSend_AutoRestartBrokenSession = 32 cast(s32);

// WARNING: these probably do not work yet in the current compiler
def k_nSteamNetworkingSend_UnreliableNoNagle = k_nSteamNetworkingSend_Unreliable bit_or k_nSteamNetworkingSend_NoNagle cast(s32);
def k_nSteamNetworkingSend_UnreliableNoDelay = k_nSteamNetworkingSend_Unreliable bit_or k_nSteamNetworkingSend_NoDelay bit_or k_nSteamNetworkingSend_NoNagle cast(s32);
def k_nSteamNetworkingSend_ReliableNoNagle   = k_nSteamNetworkingSend_Reliable   bit_or k_nSteamNetworkingSend_NoNagle cast(s32);

def k_steamIDNil = 0 cast(CSteamID);

def k_iSteamMatchmakingCallbacks = 500 cast(u32);
def k_iSteamUtilsCallbacks       = 700 cast(u32);

type EChatMemberStateChange u32;
def k_EChatMemberStateChangeEntered      = 0x0001 cast(EChatMemberStateChange); // This user has joined or is joining the lobby.
def k_EChatMemberStateChangeLeft         = 0x0002 cast(EChatMemberStateChange); // This user has left or is leaving the lobby.
def k_EChatMemberStateChangeDisconnected = 0x0004 cast(EChatMemberStateChange); // User disconnected without leaving the lobby first.
def k_EChatMemberStateChangeKicked       = 0x0008 cast(EChatMemberStateChange); // The user has been kicked.
def k_EChatMemberStateChangeBanned       = 0x0010 cast(EChatMemberStateChange); // The user has been kicked and banned.

enum steam_callback_type u32
{
	LobbyEnter_t            = k_iSteamMatchmakingCallbacks + 4;
	LobbyDataUpdate_t       = k_iSteamMatchmakingCallbacks + 5;
	LobbyChatUpdate_t       = k_iSteamMatchmakingCallbacks + 6;
	LobbyMatchList_t        = k_iSteamMatchmakingCallbacks + 10;
	LobbyCreated_t          = k_iSteamMatchmakingCallbacks + 13;
	
	SteamAPICallCompleted_t = k_iSteamUtilsCallbacks + 3;	
}

// see documentation of CreateLobby
def steam_max_lobby_member_count = 250 cast(s32);

struct SteamAPICallCompleted_t
{
	m_hAsyncCall SteamAPICall_t;
	m_iCallback  s32;
	m_cubParam   u32;
}

struct CallbackMsg_t
{
	m_hSteamUser HSteamUser; // Specific user to whom this callback applies.
	m_iCallback  s32; // Callback identifier.  (Corresponds to the k_iCallback enum in the callback structure.)
	m_pubParam   u8 ref; // Points to the callback structure
	m_cubParam   s32; // Size of the data pointed to by m_pubParam
}

struct LobbyMatchList_t
{	
	m_nLobbiesMatching u32;		// Number of lobbies that matched search criteria and we have SteamIDs for
}

struct LobbyEnter_t
{	
	m_ulSteamIDLobby u64;							// SteamID of the Lobby you have entered
	m_rgfChatPermissions u32;						// Permissions of the current user
	m_bLocked b8;										// If true, then only invited users may join
	m_EChatRoomEnterResponse u32;	// EChatRoomEnterResponse
}

struct LobbyCreated_t
{	
	m_eResult EResult;		// k_EResultOK - the lobby was successfully created
							// k_EResultNoConnection - your Steam client doesn't have a connection to the back-end
							// k_EResultTimeout - you the message to the Steam servers, but it didn't respond
							// k_EResultFail - the server responded, but with an unknown internal error
							// k_EResultAccessDenied - your game isn't set to allow lobbies, or your client does haven't rights to play the game
							// k_EResultLimitExceeded - your game client has created too many lobbies

	m_ulSteamIDLobby u64;		// chat room, zero if failed
}

struct LobbyChatUpdate_t
{	
    m_ulSteamIDLobby        u64;			// Lobby ID
	m_ulSteamIDUserChanged  u64;		// user who's status in the lobby just changed - can be recipient
	m_ulSteamIDMakingChange u64;		// Chat member who made the change (different from SteamIDUserChange if kicking, muting, etc.)
										// for example, if one user kicks another from the lobby, this will be set to the id of the user who initiated the kick
	m_rgfChatMemberStateChange u32;	// bitfield of EChatMemberStateChange values
}

struct LobbyDataUpdate_t
{	
	m_ulSteamIDLobby  u64;		// steamID of the Lobby
	m_ulSteamIDMember u64;		// steamID of the member whose data changed, or the room itself
	m_bSuccess        u8;		// true if we lobby data was successfully changed; 
								// will only be false if RequestLobbyData() was called on a lobby that no longer exists
}

func SteamAPI_Init() (ok b8) calling_convention "__cdecl" extern_binding("steam_api64", true);
func SteamAPI_Shutdown() calling_convention "__cdecl" extern_binding("steam_api64", true);

func SteamAPI_GetHSteamPipe() (pipe HSteamPipe) calling_convention "__cdecl" extern_binding("steam_api64", true);
func SteamAPI_ManualDispatch_Init() calling_convention "__cdecl" extern_binding("steam_api64", true);
func SteamAPI_ManualDispatch_RunFrame(hSteamPipe HSteamPipe) calling_convention "__cdecl" extern_binding("steam_api64", true);
func SteamAPI_ManualDispatch_GetNextCallback(hSteamPipe HSteamPipe, pCallbackMsg CallbackMsg_t ref) (ok b8) calling_convention "__cdecl" extern_binding("steam_api64", true);
func SteamAPI_ManualDispatch_FreeLastCallback(hSteamPipe HSteamPipe) calling_convention "__cdecl" extern_binding("steam_api64", true);
func SteamAPI_ManualDispatch_GetAPICallResult(hSteamPipe HSteamPipe, hSteamAPICall SteamAPICall_t, pCallback u8 ref, cubCallback s32, iCallbackExpected s32, pbFailed b8 ref) (ok b8) calling_convention "__cdecl" extern_binding("steam_api64", true);

// wrappers compiled into steam.lib
// Interfacer->Method(...) => InterfaceMethod(...)

func SteamUserGetSteamID() (id CSteamID) extern_binding("steam", false);

func SteamFriendsGetFriendPersonaName(user_id CSteamID) (name cstring) extern_binding("steam", false);

func SteamMatchmakingRequestLobbyList() (call SteamAPICall_t) extern_binding("steam", false);
func SteamMatchmakingCreateLobby(lobby_type ELobbyType, max_member_count s32) (call SteamAPICall_t) extern_binding("steam", false);
func SteamMatchmakingJoinLobby(lobby_id CSteamID) (call SteamAPICall_t) extern_binding("steam", false);
func SteamMatchmakingLeaveLobby(lobby_id CSteamID) extern_binding("steam", false);
func SteamMatchmakingGetNumLobbyMembers(lobby_id CSteamID) (member_count s32) extern_binding("steam", false);
func SteamMatchmakingGetLobbyMemberByIndex(lobby_id CSteamID, member_index s32) (id CSteamID) extern_binding("steam", false);
func SteamMatchmakingGetLobbyByIndex(lobby_index s32) (lobby_id CSteamID) extern_binding("steam", false);

// alternative wrapper

// same SteamMatchmaking()->GetLobbyMemberData but using u8_array for data
func steam_matchmaking_set_lobby_member_data(lobby_id CSteamID, key cstring, data u8[]) extern_binding("steam", false);

// same SteamMatchmaking()->SetLobbyMemberData but using u8_array buffer that gets filled
func steam_matchmaking_get_lobby_member_data(lobby_id CSteamID, user_id CSteamID, buffre u8[], key cstring) (data u8[]) extern_binding("steam", false);

// same as SteamNetworkingMessages()->SendMessageToUser but using CSteamID instead of SteamNetworkingIdentity and u8_array for data
func steam_network_send(user_id CSteamID, data u8[], send_flags s32, remote_channel s32 = 0) extern_binding("steam", false);

// same as SteamNetworkingMessages()->ReceiveMessagesOnChannel but receives only one message and writes it into the provided buffer
func steam_network_receive(local_channel s32 = 0, buffer u8[]) (id CSteamID, data u8[]) extern_binding("steam", false);