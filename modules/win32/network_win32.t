
module network;

import win32;
import meta;

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
func setsockopt(s SOCKET, level s32, optname s32, optval u8 ref, optlen s32 ref) (result s32)  calling_convention "__stdcall" extern_binding("Ws2_32", true);
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

def WSAWOULDBLOCK   = 10035 cast(s32);
def WSAEINPROGRESS  = 10036 cast(s32);
def WSAEMSGSIZE     = 10040 cast(s32);
def WSAENETRESET    = 10052 cast(s32);
def WSAECONNABORTED = 10053 cast(s32);
def WSAECONNRESET   = 10054 cast(s32);
def WSAETIMEDOUT    = 10060 cast(s32);
def WSAECONNREFUSED = 10061 cast(s32);

def AF_INET    = 2  cast(u16);
def AF_INET6   = 23 cast(u16);

def INADDR_ANY = 0 cast(u32);
def IN6ADDR_ANY_INIT = [ 0, 0, 0, 0, 0, 0, 0, 0 ] u16[];

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

struct sockaddr_in6
{
    sin6_family   u16;
    sin6_port     u16;
    sin6_flowinfo u32;
    in6_addr      u16[8];
    sin6_scope_id u32;
};

struct sockaddr
{
    sa_family u16;
    sa_data   u8[14];                   // Up to 14 bytes of direct address.
}

// just don't question win32 api :(
struct SOCKADDR_STORAGE
{
  ss_family  s16;
  __ss_pad1  u8[6];
  __ss_align s64;
  __ss_pad2  u8[112];
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
    expand base   platform_network_socket_base;
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
    var listen_socket = platform_network_win32_bind(network, false, address_tag, port);

    var ok = listen(listen_socket.handle, SOMAXCONN_HINT(connection_count)) is_not SOCKET_ERROR;
    require(ok, "listen(...) failed with\nWSAGetLastError(): %i", WSAGetLastError());

    return listen_socket;
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
    result.handle = accepted_socket;
    result.port   = ntohs(address.sin_port);

    var result_address platform_network_address;
    result_address.tag             = platform_network_address_tag.ip_v4;
    result_address.ip_v4.u32_value = address.sin_addr.s_addr;
    result_address.port            = result.port;

    return result, result_address;
}

func platform_network_connect_begin platform_network_connect_begin_type
{
    assert(address.tag is platform_network_address_tag.ip_v4);

    var handle = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    require(handle is_not INVALID_SOCKET, "socket(AF_INET, SOCK_STREAM, IPPROTO_TCP) failed with Error: %", WSAGetLastError());

    var is_non_blocking u32 = 1;
    ioctlsocket(handle, FIONBIO, is_non_blocking ref);

    var address_in sockaddr_in;
    address_in.sin_family      = AF_INET;
    address_in.sin_addr.s_addr = address.ip_v4.u32_value;
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

func platform_network_win32_bind(network platform_network ref, is_udp b8, address_tag platform_network_address_tag, port u16) (udp_socket platform_network_socket)
{
    var family s32;

    var address_union SOCKADDR_STORAGE;
    var address = address_union ref cast(sockaddr ref);
    var address_byte_count s32;

    switch address_tag
    case platform_network_address_tag.ip_v4
    {
        family = AF_INET;

        var address_in = address_union ref cast(sockaddr_in ref);
        address_in.sin_family      = AF_INET;
        address_in.sin_addr.s_addr = INADDR_ANY;
        address_in.sin_port        = htons(port);

        address_byte_count = type_byte_count(sockaddr_in);
    }
    case platform_network_address_tag.ip_v6
    {
        family = AF_INET6;

        var address_in = address_union ref cast(sockaddr_in6 ref);
        address_in.sin6_family = AF_INET6;
        address_in.in6_addr    = IN6ADDR_ANY_INIT;
        address_in.sin6_port   = htons(port);

        address_byte_count = type_byte_count(sockaddr_in6);
    }
    else
    {
        assert(false);
    }

    var handle SOCKET;
    if is_udp
        handle = socket(family, SOCK_DGRAM, IPPROTO_UDP);
    else
        handle= socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

    require(handle is_not INVALID_SOCKET, "socket(...) failed with Error: %", WSAGetLastError());

    var is_non_blocking u32 = 1;
    ioctlsocket(handle, FIONBIO, is_non_blocking ref);

    var ok = bind(handle, address, address_byte_count) is_not SOCKET_ERROR;
    require(ok, "WSAGetLastError(): %", WSAGetLastError());

    if not port
    {
        // var address_byte_count = type_byte_count(sockaddr_in) cast(s32);
        if not getsockname(handle, address, address_byte_count ref)
        {
            switch address_tag
            case platform_network_address_tag.ip_v4
                port = htons(address cast(sockaddr_in ref).sin_port);
            case platform_network_address_tag.ip_v6
                port = htons(address cast(sockaddr_in6 ref).sin6_port);

            assert(port);
        }
    }

    var result platform_network_socket;
    result.address_tag = address_tag;
    result.port   = port;
    result.handle = handle;
    result.is_udp = is_udp;

    return result;
}

func platform_network_peer_open platform_network_peer_open_type
{
    var bind_socket = platform_network_win32_bind(network, true, address_tag, port);
    return bind_socket;
}

func platform_network_peer_close platform_network_peer_close_type
{
    assert(udp_socket.is_udp);
    require(not closesocket(udp_socket.handle), "WSA Error Code: %", WSAGetLastError());
    udp_socket deref = {} platform_network_socket;
}

func platform_network_send platform_network_send_type
{
    assert(send_socket.address_tag is address.tag);
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

    var address_union SOCKADDR_STORAGE;
    var send_address = address_union ref cast(sockaddr ref);
    var send_address_byte_count s32;

    switch address.tag
    case platform_network_address_tag.ip_v4
    {
        var address_in = address_union ref cast(sockaddr_in ref);
        address_in.sin_family      = AF_INET;
        address_in.sin_addr.s_addr = address.ip_v4.u32_value;
        address_in.sin_port        = htons(address.port);
        send_address_byte_count = type_byte_count(sockaddr_in);
    }
    case platform_network_address_tag.ip_v6
    {
        var address_in = address_union ref cast(sockaddr_in6 ref);
        address_in.sin6_family = AF_INET6;
        address_in.in6_addr    = htons(address.ip_v6.u16_values);
        address_in.sin6_port   = htons(address.port);
        send_address_byte_count = type_byte_count(sockaddr_in6);
    }
    else
    {
        assert(false);
    }

    var send_count = sendto(send_socket.handle, data.base, data.count cast(s32), 0, send_address, send_address_byte_count);
    if send_count is SOCKET_ERROR
    {
        var error = WSAGetLastError();
        switch error
        case WSAECONNRESET, WSAECONNABORTED
            return false;
        // TODO: WSAWOULDBLOCK can still occur for non blocking sockets, even when select says it is ready
        case WSAWOULDBLOCK
            return true;

        require(false, "send(socket.handle, data.base, data.count cast(s32), 0) failed with WSAGetLastError(): %", error);
    }

    assert(send_count cast(usize) is data.count);

    return true;
}

func platform_network_receive platform_network_receive_type
{
    var read_sockets fd_set;
    FD_SET(receive_socket.handle, read_sockets ref);

    if timeout_milliseconds is_not platform_network_timeout_milliseconds_block
    {
        var timeout timeval;
        timeout.tv_sec  = timeout_milliseconds / 1000;
        timeout.tv_usec = (timeout_milliseconds mod 1000) * 1000;
        var result = select(0, read_sockets ref, null, null, timeout ref);

        // timeout, return nothing
        if not result
            return true, false, {} platform_network_address;

        if result is SOCKET_ERROR
        {
            var error = WSAGetLastError();
            if error is WSAEINPROGRESS
                return true, false, {} platform_network_address;

            require(false, "select(0, read_sockets ref, null, null, timeout ref) failed with WSAGetLastError(): %", error);
        }
    }
    else
    {
        require(select(0, read_sockets ref, null, null, null) is_not SOCKET_ERROR, "WSAGetLastError(): %", WSAGetLastError());
    }

    buffer_used_byte_count deref = 0;

    var address_union SOCKADDR_STORAGE;
    var receive_address = address_union ref cast(sockaddr ref);
    var receive_address_byte_count s32;

    switch receive_socket.address_tag
    case platform_network_address_tag.ip_v4
    {
        // var address_in = address_union ref cast(sockaddr_in ref);
        // address_in.sin_family      = AF_INET;
        // address_in.sin_addr.s_addr = address.ip_v4.u32_value;
        // address_in.sin_port        = htons(address.port);
        receive_address_byte_count = type_byte_count(sockaddr_in);
    }
    case platform_network_address_tag.ip_v6
    {
        // var address_in = address_union ref cast(sockaddr_in6 ref);
        // address_in.sin6_family = AF_INET6;
        // address_in.in6_addr    = htons(address.ip_v6).u16_values;
        // address_in.sin6_port   = htons(address.port);
        receive_address_byte_count = type_byte_count(sockaddr_in6);
    }
    else
    {
        assert(false);
    }

    var receive_count = recvfrom(receive_socket.handle, (buffer.base + buffer_used_byte_count deref), (buffer.count - buffer_used_byte_count deref) cast(s32), 0, receive_address, receive_address_byte_count ref);
    if receive_count is SOCKET_ERROR
    {
        var error = WSAGetLastError();

        // with UDP, we don nonet have connections that could fail,
        // but win32 will indicate if a udp "connection" is lost running locally
        // UDP sockets can just ignore ok value :(

        switch error
        // HACK: udp sockets ignore this message
        case WSAECONNRESET, WSAECONNABORTED
            return receive_socket.is_udp, receive_socket.is_udp, {} platform_network_address;
        // HACK: WSAEMSGSIZE indicates buffer is too small, we drop those messages
        case WSAEMSGSIZE
        {
            assert(0);
            return true, true, {} platform_network_address;
        }

        require(false, "recv(socket.handle, (buffer.base + byte_offset deref), (buffer.count - byte_offset deref) cast(s32), 0) failed with WSAGetLastError(): %", error);
    }

    buffer_used_byte_count deref += receive_count cast(usize);

    var address platform_network_address;
    address.tag = receive_socket.address_tag;

    switch receive_socket.address_tag
    case platform_network_address_tag.ip_v4
    {
        var address_in = address_union ref cast(sockaddr_in ref);
        assert(address_in.sin_family is AF_INET);
        address.ip_v4.u32_value = address_in.sin_addr.s_addr;
        address.port            = htons(address_in.sin_port);
    }
    case platform_network_address_tag.ip_v6
    {
        var address_in = address_union ref cast(sockaddr_in6 ref);
        assert(address_in.sin6_family is AF_INET6);
        address.ip_v6.u16_values = htons(address_in.in6_addr);
        address.port             = htons(address_in.sin6_port);
    }

    return true, true, address;
}

func platform_network_query_dns platform_network_query_dns_type
{
    var records DNS_RECORD ref;
    var name_buffer u8[512];
    var cname = as_cstring(name_buffer, name);

    var ok = false;
    var address platform_network_address;

    var dns_server DNS_ADDR;
    {
        var address platform_network_address;
        address.tag = platform_network_address_tag.ip_v4;
        address.ip_v4 = [ 1, 1, 1, 1 ] platform_network_ip_v4;
        write_sockaddress(value_to_u8_array(dns_server), address);
    }

    if false
    {
        var name_buffer u16[512];
        var wname = win32_utf8_to_wstring(name_buffer, name);

        var dns_servers DNS_ADDR[1];

        {
            var address platform_network_address;
            address.tag = platform_network_address_tag.ip_v4;
            address.ip_v4 = [ 1, 1, 1, 1 ] platform_network_ip_v4;
            write_sockaddress(value_to_u8_array(dns_servers[0]), address);
        }

        var dns_server_arrray DNS_ADDR_ARRAY;
        dns_server_arrray.MaxCount  = type_byte_count(DNS_ADDR_ARRAY);
        dns_server_arrray.AddrCount = dns_servers.count cast(u32);
        dns_server_arrray.Family    = AF_INET; // servers can be ip4?
        dns_server_arrray.AddrArray = dns_servers.base;

        var request DNS_QUERY_REQUEST;
        request.Version      = DNS_QUERY_REQUEST_VERSION1;
        request.QueryName    = wname.base;
        request.QueryType    = DNS_TYPE_AAAA;
        request.QueryOptions = DNS_QUERY_BYPASS_CACHE;
        request.pDnsServerList = null; // dns_server_arrray ref;

        var result  DNS_QUERY_RESULT;
        result.Version = DNS_QUERY_REQUEST_VERSION1;

        var status = DnsQueryEx(request ref, result ref, null);
        require((status is ERROR_SUCCESS) or (status is DNS_INFO_NO_RECORDS));
    }

    {
        var status = DnsQuery_A(cname, DNS_TYPE_AAAA, DNS_QUERY_BYPASS_CACHE, dns_server ref, records cast(u8 ref) ref, null);
        require((status is ERROR_SUCCESS) or (status is DNS_INFO_NO_RECORDS));
        var iterator = records;

        if iterator
        {
            address.tag   = platform_network_address_tag.ip_v6;
            address.ip_v6 = iterator.Data.AAAA.IP6Qword.base cast(platform_network_ip_v6 ref) deref;
            address.ip_v6.u16_values = htons(address.ip_v6.u16_values);
            ok = true;
        }

        DnsRecordListFree(records, 0);
    }

    // check ip v4
    if not ok
    {
        var status = DnsQuery_A(cname, DNS_TYPE_A, DNS_QUERY_BYPASS_CACHE, dns_server ref, records cast(u8 ref) ref, null);
        require((status is ERROR_SUCCESS) or (status is DNS_INFO_NO_RECORDS));
        var iterator = records;

        if iterator
        {
            address.tag   = platform_network_address_tag.ip_v4;
            address.ip_v4 = iterator.Data.A.IpAddress ref cast(platform_network_ip_v4 ref) deref;
            ok = true;
        }

        DnsRecordListFree(records, 0);
    }

    return ok, address;
}


// func platform_network_query_dns_ip_v6 platform_network_query_dns_ip_v6_type
// {
//     var records DNS_RECORD ref;
//     var name_buffer u8[512];
//     var status = DnsQuery_A(as_cstring(name_buffer, name), DNS_TYPE_AAAA, DNS_QUERY_STANDARD, null, records cast(u8 ref) ref, null);
//     var iterator = records;
//
//     var ip platform_network_ip_v6;
//     if iterator
//         ip = iterator.Data.AAAA.IP6Qword.base cast(platform_network_ip_v6 ref) deref;
//
//     DnsRecordListFree(records, 0);
//
//     return iterator is_not null, ip;
// }

func write_sockaddress(buffer u8[], address platform_network_address) (byte_count s32)
{
    var byte_count s32;
    switch address.tag
    case platform_network_address_tag.ip_v4
    {
        byte_count = type_byte_count(sockaddr_in);
        assert(byte_count <= buffer.count);

        var address_in = buffer.base cast(sockaddr_in ref);
        address_in.sin_family      = AF_INET;
        address_in.sin_addr.s_addr = address.ip_v4.u32_value;
        address_in.sin_port        = htons(address.port);

    }
    case platform_network_address_tag.ip_v6
    {
        byte_count = type_byte_count(sockaddr_in6);
        assert(byte_count <= buffer.count);

        var address_in = buffer.base cast(sockaddr_in6 ref);
        address_in.sin6_family = AF_INET6;
        address_in.in6_addr    = htons(address.ip_v6.u16_values);
        address_in.sin6_port   = htons(address.port);
    }
    else
    {
        assert(false);
    }

    return byte_count;
}