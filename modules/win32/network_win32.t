
module network;

import win32;

func WSAStartup(wVersionRequired u16, lpWSAData WSADATA ref) (result s32) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func WSACleanup() (result s32) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func WSAGetLastError() (error s32) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func __WSAFDIsSet(s SOCKET, set fd_set ref) (result s32) calling_convention "__stdcall" extern_binding("Ws2_32", true);

func socket(af s32, type s32, protocol s32) (result SOCKET) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func closesocket(s SOCKET) (result s32) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func bind(s SOCKET, name sockaddr ref, namelen s32) (result s32) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func listen(s SOCKET, backlog s32) (result s32) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func select(nfds s32, readfds fd_set ref, writefds fd_set ref, exceptfds fd_set ref, timeout timeval ref) (result s32) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func accept(s SOCKET, addr sockaddr ref, addrlen s32 ref) (result SOCKET) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func connect(s SOCKET, name sockaddr ref, namelen s32)  (result s32) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func sendto(s SOCKET, buf u8 ref, len s32, flags s32, to sockaddr ref, tolen s32) (send_byte_count s32) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func recvfrom(s SOCKET, buf u8 ref, len s32, flags s32, from sockaddr ref, fromlen s32 ref) (receive_byte_count s32) calling_convention "__stdcall" extern_binding("Ws2_32", true);
func ioctlsocket(s SOCKET, cmd s32, argp u32 ref) (result s32)  calling_convention "__stdcall" extern_binding("Ws2_32", true);
func getsockopt(s SOCKET, level s32, optname s32, optval u8 ref, optlen s32 ref) (result s32)  calling_convention "__stdcall" extern_binding("Ws2_32", true);
func getsockname(s SOCKET, name sockaddr ref, namelen s32 ref) (result s32)  calling_convention "__stdcall" extern_binding("Ws2_32", true);

def SOMAXCONN = 0x7fffffff cast(s32);

func SOMAXCONN_HINT(b s32) (result s32)
{
    return -b;
}

type SOCKET u64;

def SOCKET_ERROR   = -1 cast(s32);
def INVALID_SOCKET = bit_not 0 cast(SOCKET);

def SOL_SOCKET = 0xFFFF cast(s32);

def SO_ERROR   = 0x1007 cast(s32);

def WSADESCRIPTION_LEN = 256;
def WSASYS_STATUS_LEN  = 128;

def WSAEINPROGRESS     = 10036 cast(s32);
def WSAENETRESET       = 10052 cast(s32);
def WSAECONNABORTED    = 10053 cast(s32);
def WSAECONNRESET      = 10054 cast(s32);
def WSAETIMEDOUT       = 10060 cast(s32);
def WSAECONNREFUSED    = 10061 cast(s32);

def AF_INET    = 2 cast(u16);
def INADDR_ANY = 0 cast(u32);
def SOCK_STREAM = 1 cast(s32);              // stream socket
def SOCK_DGRAM  = 2 cast(s32);               // datagram socket
def IPPROTO_TCP = 6 cast(s32);    // tcp
def IPPROTO_PUP = 12 cast(s32);             // pup
def IPPROTO_UDP = 17 cast(s32);              // user datagram protocol

def FIONBIO = 0x8004667e cast(s32);

struct WSADATA
{
    wVersion       u16;
    wHighVersion   u16;
    iMaxSockets    u16;
    iMaxUdpDg      u16;
    lpVendorInfo   u8 ref;
    szDescription  u8[WSADESCRIPTION_LEN+1];
    szSystemStatus u8[WSASYS_STATUS_LEN+1];
}

struct sockaddr_in
{
    sin_family u16;
    sin_port   u16;
    sin_addr   IN_ADDR;
    sin_zero   u8[8];
}

struct sockaddr
{
    sa_family u16;
    sa_data   u8[14];                   // Up to 14 bytes of direct address.
}

type IN_ADDR union
{
    expand S_un_b struct
    {
        s_b1 u8;
        s_b2 u8;
        s_b3 u8;
        s_b4 u8;
    };

    expand S_un_w struct
    {
        s_w1 u16;
        s_w2 u16;
    };

    s_addr u32;
};

def FD_SETSIZE = 64;

struct fd_set
{
    fd_count u32;                  // how many are SET?
    fd_array SOCKET[FD_SETSIZE];   // an array of SOCKETs
}

func FD_CLR(fd SOCKET, set fd_set ref)
{
    loop var i; set.fd_count
    {
        if set.fd_array[i] is fd
        {
            while i < set.fd_count - 1
            {
                set.fd_array[i] = set.fd_array[i + 1];
                i += 1;
            }

            set.fd_count -= 1;
            break;
        }
    }
}

func FD_SET(fd SOCKET, set fd_set ref)
{
    var found = false;
    loop var i; set.fd_count
    {
        if set.fd_array[i] is fd
        {
            found = true;
            break;
        }
    }

    if not found
    {
        assert(set.fd_count < set.fd_array.count); // bold move
        set.fd_array[set.fd_count] = fd;
        set.fd_count += 1;
    }
}

func FD_ISSET(fd SOCKET, set fd_set ref) (ok b8)
{
    return __WSAFDIsSet(fd, set);
}

struct timeval
{
    tv_sec  s32;
    tv_usec s32;
};

struct platform_network_socket
{
    expand base platform_network_address;
    handle SOCKET;
}

struct platform_network
{
    is_init b8;
}

func platform_network_init platform_network_init_type
{
    if network.is_init
        return;

    var wsa_data WSADATA;
    var result = WSAStartup(2 bit_shift_left 8 bit_or 2, wsa_data ref);
    require(not result, "WSAStartup(2 bit_shift_left 8 bit_or 2, wsa_data ref) failed with Error: %", result);
    network.is_init = true;
}

func platform_network_shutdown platform_network_shutdown_type
{
    if not network.is_init
        return;

    require(WSACleanup() is_not SOCKET_ERROR, "WSAGetLastError(): %", WSAGetLastError());
    network.is_init = false;
}

func platform_network_is_valid platform_network_is_valid_type
{
    return test_socket.handle is_not 0;
}

func platform_network_listen platform_network_listen_type
{
    var listen_socket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    require(listen_socket is_not INVALID_SOCKET, "socket(AF_INET, SOCK_STREAM, IPPROTO_TCP) failed with Error: %i", WSAGetLastError());

    var address sockaddr_in;
    address.sin_family      = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port        = htons(port);
    require( bind(listen_socket, address ref cast(sockaddr ref), type_byte_count(sockaddr_in)) is_not SOCKET_ERROR, "WSAGetLastError(): %", WSAGetLastError() );

    require( listen(listen_socket, SOMAXCONN_HINT(connection_count)) is_not SOCKET_ERROR, "WSAGetLastError(): %i", WSAGetLastError() );

    var result platform_network_socket;
    result.handle = listen_socket;
    result.port  = port;

    return result;
}

func platform_network_accept platform_network_accept_type
{
    var read_sockets fd_set;
    FD_SET(listen_socket.handle, read_sockets ref);

    if timeout_milliseconds is_not platform_network_timeout_milliseconds_block
    {
        var timeout timeval;
        timeout.tv_sec  = timeout_milliseconds / 1000;
        timeout.tv_usec = (timeout_milliseconds mod 1000) * 1000;
        var result = select(0, read_sockets ref, null, null, timeout ref);

        // timeout, return nothing
        if not result
            return {} platform_network_socket;

        require(result is_not SOCKET_ERROR, "select(0, read_sockets ref, null, null, timeout ref) failed with WSAGetLastError(): %", WSAGetLastError());
    }
    else
    {
        require(select(0, read_sockets ref, null, null, null) is_not SOCKET_ERROR, "WSAGetLastError(): %", WSAGetLastError());
    }

    var address sockaddr_in;
    var address_byte_count = type_byte_count(sockaddr_in) cast(s32);
    var accepted_socket = accept(listen_socket.handle, address ref cast(sockaddr ref), address_byte_count ref);
    require(accepted_socket is_not INVALID_SOCKET, "accept(listen_socket.handle, address ref cast(SOCKADDR ref), address_byte_count ref) failed with WSAGetLastError(): %", WSAGetLastError());

    var result platform_network_socket;
    result.handle       = accepted_socket;
    result.ip.u32_value = address.sin_addr.s_addr;
    result.port         = ntohs(address.sin_port);

    return result;
}

func platform_network_connect_begin platform_network_connect_begin_type
{
    var handle = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    require(handle is_not INVALID_SOCKET, "socket(AF_INET, SOCK_STREAM, IPPROTO_TCP) failed with Error: %", WSAGetLastError());

    var is_non_blocking u32 = 1;
    ioctlsocket(handle, FIONBIO, is_non_blocking ref);

    var address_in sockaddr_in;
    address_in.sin_family      = AF_INET;
    address_in.sin_addr.s_addr = address.ip.u32_value;
    address_in.sin_port        = htons(address.port);
    if connect(handle, address ref cast(sockaddr ref), type_byte_count(sockaddr_in)) is SOCKET_ERROR
    {
        var error = WSAGetLastError();
        if (error is WSAECONNREFUSED) or (error is WSAETIMEDOUT)
        {
            closesocket(handle);
            return false, {} platform_network_socket;
        }

        require(error is_not WSAETIMEDOUT, "connect(handle, address ref cast(SOCKADDR ref), type_byte_count(SOCKADDR_IN))", "failed with WSAGetLastError(): %", error);
    }

    var result platform_network_socket;
    result.handle = handle;
    result.ip     = address.ip;
    result.port   = address.port;

    return true, result;
}

func platform_network_connect_end platform_network_connect_end_type
{
    assert(connect_socket.handle);

    var write_sockets fd_set;
    FD_SET(connect_socket.handle, write_sockets ref);

    if timeout_milliseconds is_not platform_network_timeout_milliseconds_block
    {
        var timeout timeval;
        timeout.tv_sec  = timeout_milliseconds / 1000;
        timeout.tv_usec = (timeout_milliseconds mod 1000) * 1000;
        var result = select(0, null, write_sockets ref, null, timeout ref);

        // timeout, return nothing
        if not result
        {
            closesocket(connect_socket.handle);
            connect_socket deref = {} platform_network_socket;
            return false;
        }

        require(result is_not SOCKET_ERROR, "select(0, null, write_sockets ref, null, timeout ref) failed with WSAGetLastError(): %", WSAGetLastError());
    }
    else
    {
        require(select(0, null, write_sockets ref, null, null) is_not SOCKET_ERROR, "WSAGetLastError(): %", WSAGetLastError());
    }

    return true;
}

func platform_network_disconnect platform_network_disconnect_type
{
    assert(platform_network_is_valid(connect_socket deref));

    var error = closesocket(connect_socket.handle);
    connect_socket deref = {} platform_network_socket;

    return true;
}

func platform_network_bind platform_network_bind_type
{
    var handle = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    require(handle is_not INVALID_SOCKET, "socket(AF_INET, SOCK_STREAM, IPPROTO_UDP) failed with Error: %", WSAGetLastError());

    var is_non_blocking u32 = 1;
    ioctlsocket(handle, FIONBIO, is_non_blocking ref);

    var address sockaddr_in;
    address.sin_family      = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port        = htons(port);
    require( bind(handle, address ref cast(sockaddr ref), type_byte_count(sockaddr_in)) is_not SOCKET_ERROR, "WSAGetLastError(): %", WSAGetLastError() );

    if not port
    {
        var address_byte_count = type_byte_count(sockaddr_in) cast(s32);
        if not getsockname(handle, address ref cast(sockaddr ref), address_byte_count ref)
        {
            port = htons(address.sin_port);
            assert(port);
        }
    }

    var result platform_network_socket;
    result.handle = handle;
    result.port   = port;

    return result;
}

func platform_network_send platform_network_send_type
{
    var write_sockets fd_set;
    FD_SET(send_socket.handle, write_sockets ref);

    var timeout timeval;
    var timeout_ref timeval ref;

    if timeout_milliseconds is_not platform_network_timeout_milliseconds_block
    {
        timeout.tv_sec  = timeout_milliseconds / 1000;
        timeout.tv_usec = (timeout_milliseconds mod 1000) * 1000;
        timeout_ref = timeout ref;
    }

    var result = select(0, null, write_sockets ref, null, timeout_ref);//is_not SOCKET_ERROR, "WSAGetLastError(): %", WSAGetLastError());

    // timeout, return nothing
    if not result
    {
        assert(0, "not implemented");
    }

    if result is SOCKET_ERROR
    {
        var error s32;
        var error_byte_count s32 = type_byte_count(s32);
        if getsockopt(send_socket.handle, SOL_SOCKET, SO_ERROR, error ref, error_byte_count ref) is SOCKET_ERROR
        {
            require(false, "select failed, WSAGetLastError(): %", WSAGetLastError());
            return false;
        }
    }

    var address_in sockaddr_in;
    var send_address sockaddr ref;
    var send_address_byte_count s32;

    if address.ip.u32_value
    {
        address_in.sin_family      = AF_INET;
        address_in.sin_addr.s_addr = address.ip.u32_value;
        address_in.sin_port        = htons(address.port);

        send_address = address_in ref cast(sockaddr ref);
        send_address_byte_count = type_byte_count(sockaddr_in);
    }

    var send_count = sendto(send_socket.handle, data.base, data.count cast(s32), 0, send_address, send_address_byte_count);
    if send_count is SOCKET_ERROR
    {
        var error = WSAGetLastError();
        if (error is WSAECONNRESET) or (error is WSAECONNABORTED)
            return false;

        require(false, "send(socket.handle, data.base, data.count cast(s32), 0) failed with WSAGetLastError(): %", error);
    }
    assert(send_count cast(usize) is data.count);

    return true;
}

func platform_network_receive platform_network_receive_type
{
    var read_sockets fd_set;
    FD_SET(receive_socket.handle, read_sockets ref);

     var ip platform_network_ip;
     var port u16;

    if timeout_milliseconds is_not platform_network_timeout_milliseconds_block
    {
        var timeout timeval;
        timeout.tv_sec  = timeout_milliseconds / 1000;
        timeout.tv_usec = (timeout_milliseconds mod 1000) * 1000;
        var result = select(0, read_sockets ref, null, null, timeout ref);

        // timeout, return nothing
        if not result
            return true, ip, port;

        if result is SOCKET_ERROR
        {
            var error = WSAGetLastError();
            if error is WSAEINPROGRESS
                return true, ip, port;

            require(false, "select(0, read_sockets ref, null, null, timeout ref) failed with WSAGetLastError(): %", error);
        }
    }
    else
    {
        require(select(0, read_sockets ref, null, null, null) is_not SOCKET_ERROR, "WSAGetLastError(): %", WSAGetLastError());
    }

    var address_in sockaddr_in;
    var receive_address = address_in ref cast(sockaddr ref);
    var receive_address_byte_count s32 = type_byte_count(sockaddr_in);

    var receive_count = recvfrom(receive_socket.handle, (buffer.base + buffer_used_byte_count deref), (buffer.count - buffer_used_byte_count deref) cast(s32), 0, receive_address, receive_address_byte_count ref);
    if receive_count is SOCKET_ERROR
    {
        var error = WSAGetLastError();
        // with UDP, we don't have connections that could fail,
        // but win32 will indicate if a udp "connection" is lost running locally
        // UDP sockets can just ignore ok value :(
        if (error is WSAECONNRESET) or (error is WSAECONNABORTED)
            return false, ip, port;

        require(false, "recv(socket.handle, (buffer.base + byte_offset deref), (buffer.count - byte_offset deref) cast(s32), 0) failed with WSAGetLastError(): %", error);
    }

    buffer_used_byte_count deref += receive_count cast(usize);

    ip.u32_value = address_in.sin_addr.s_addr;
    port = htons(address_in.sin_port);

    return true, ip, port;
}

func platform_network_query_dns_ip platform_network_query_dns_ip_type
{
    var records DNS_RECORD ref;
    var name_buffer u8[512];
    var status = DnsQuery_A(as_cstring(name_buffer, name), DNS_TYPE_A, DNS_QUERY_STANDARD, null, records cast(u8 ref) ref, null);
    var iterator = records;

    var ip platform_network_ip;
    if iterator
        ip = iterator.Data.A.IpAddress ref cast(platform_network_ip ref) deref;

    DnsRecordListFree(records, 0);

    return iterator is_not null, ip;
}