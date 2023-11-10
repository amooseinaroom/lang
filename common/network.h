
#pragma once

#include <winsock2.h>
#include <windows.h>

#include "platform.h"

#pragma comment(lib, "Ws2_32.lib")

union platform_network_ip
{
    u8  u8_values[4];
    u32 u32_value;
};

struct platform_socket
{
    SOCKET handle;
    platform_network_ip ip;
    u16                 port;
};

struct platform_network
{
    u32 ignored;
};

void platform_network_init(platform_network *network)
{
    WSADATA wsa_data;
    
    auto result = WSAStartup(MAKEWORD(2,2), &wsa_data);
    require(!result, "WSAStartup(MAKEWORD(2,2), &wsa_data) failed with Error: %i", result);
}

void platform_network_finish(platform_network *network)
{
    require( WSACleanup() != SOCKET_ERROR, "WSAGetLastError(): %i", WSAGetLastError() );
}

platform_socket platform_network_listen(u16 port, u32 connection_count)
{
    SOCKET handle = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    require(handle != INVALID_SOCKET, "socket(AF_INET, SOCK_STREAM, IPPROTO_TCP) failed with Error: %i", WSAGetLastError());
    
    sockaddr_in address = {};
    address.sin_family      = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port        = htons(port);
    require( bind(handle, (SOCKADDR *) &address, sizeof(address)) != SOCKET_ERROR, "WSAGetLastError(): %i", WSAGetLastError() );
    
    require( listen(handle, SOMAXCONN_HINT(connection_count)) != SOCKET_ERROR, "WSAGetLastError(): %i", WSAGetLastError() );
    
    platform_socket socket = {};
    socket.handle = handle;
    socket.port   = port;
    
    return socket;
}

const u32 platform_network_timeout_milliseconds_block = -1;

platform_socket platform_network_accept(platform_socket *listen_socket, u32 timeout_milliseconds)
{
    fd_set read_sockets;
    FD_ZERO(&read_sockets);
    FD_SET(listen_socket->handle, &read_sockets);
    
    if (timeout_milliseconds != platform_network_timeout_milliseconds_block)
    {
        timeval timeout = {};
        timeout.tv_sec  = timeout_milliseconds / 1000;
        timeout.tv_usec = (timeout_milliseconds % 1000) * 1000;
        auto result = select(0, &read_sockets, null, null, &timeout);
        
        // timeout, return nothing
        if (!result)
            return {};
        
        require(result != SOCKET_ERROR, "select(0, &read_sockets, null, null, &timeout) failed with WSAGetLastError(): %i", WSAGetLastError() );
    }
    else
    {
        require( select(0, &read_sockets, null, null, null) != SOCKET_ERROR, "WSAGetLastError(): %i", WSAGetLastError() );
    }

    sockaddr_in address;
    int address_byte_count = sizeof(address);
    SOCKET accepted_socket = accept(listen_socket->handle, (SOCKADDR *) &address, &address_byte_count);
    require( accepted_socket != INVALID_SOCKET, "accept(listen_socket->handle, (SOCKADDR *) &address, sizeof(address)) failed with WSAGetLastError(): %i", WSAGetLastError() );
    
    platform_socket socket = {};
    socket.handle       = accepted_socket;
    socket.ip.u32_value = address.sin_addr.s_addr;
    socket.port         = ntohs(address.sin_port);
    
    return socket;
}

platform_socket platform_network_connect_begin(platform_network_ip ip, u16 port)
{
    SOCKET handle = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    require(handle != INVALID_SOCKET, "socket(AF_INET, SOCK_STREAM, IPPROTO_TCP) failed with Error: %i", WSAGetLastError());
   
    sockaddr_in address = {};
    address.sin_family      = AF_INET;
    address.sin_addr.s_addr = ip.u32_value;
    address.sin_port        = htons(port);
    auto result = connect(handle, (SOCKADDR *) &address, sizeof(address));
    if (result == SOCKET_ERROR)
    {
        auto error = WSAGetLastError();
        if (error == WSAECONNREFUSED)
        {
            closesocket(handle);
            return {};
        }
        
        require(false, "connect(handle, (SOCKADDR *) &address, sizeof(address)) failed with WSAGetLastError(): %i", error);
    }
    
    platform_socket socket = {};
    socket.handle = handle;
    socket.ip     = ip;
    socket.port   = port;

    return socket;
}

bool platform_network_connect_end(platform_socket *connect_socket, u32 timeout_milliseconds)
{
    assert(connect_socket->handle);
    
    fd_set write_sockets;
    FD_ZERO(&write_sockets);
    FD_SET(connect_socket->handle, &write_sockets);
    
    if (timeout_milliseconds != platform_network_timeout_milliseconds_block)
    {
        timeval timeout = {};
        timeout.tv_sec  = timeout_milliseconds / 1000;
        timeout.tv_usec = (timeout_milliseconds % 1000) * 1000;
        auto result = select(0, null, &write_sockets, null, &timeout);
        
        // timeout, return nothing
        if (!result)
        {
            closesocket(connect_socket->handle);
            *connect_socket = {};
            return false;
        }
        
        require(result != SOCKET_ERROR, "select(0, null, &write_sockets, null, &timeout) failed with WSAGetLastError(): %i", WSAGetLastError() );
    }
    else
    {
        require( select(0, null, &write_sockets, null, null) != SOCKET_ERROR, "WSAGetLastError(): %i", WSAGetLastError() );
    }
    
    return true;
}
    
platform_socket platform_network_connect(platform_network_ip ip, u16 port, u32 timeout_milliseconds)
{
    auto socket = platform_network_connect_begin(ip, port);
    platform_network_connect_end(&socket, timeout_milliseconds);
    
    return socket;
}

bool platform_network_send(platform_socket *socket, u8_array data, u32 timeout_milliseconds =  platform_network_timeout_milliseconds_block)
{
    fd_set write_sockets;
    FD_ZERO(&write_sockets);
    FD_SET(socket->handle, &write_sockets);
    
    if (timeout_milliseconds != platform_network_timeout_milliseconds_block)
    {
        timeval timeout = {};
        timeout.tv_sec  = timeout_milliseconds / 1000;
        timeout.tv_usec = (timeout_milliseconds % 1000) * 1000;
        auto result = select(0, null, &write_sockets, null, &timeout);
        
        // timeout, return nothing
        if (!result)
        {
           assert(0);
        }
        
        require(result != SOCKET_ERROR, "select(0, null, &write_sockets, null, &timeout) failed with WSAGetLastError(): %i", WSAGetLastError() );
    }
    else
    {
        require( select(0, null, &write_sockets, null, null) != SOCKET_ERROR, "WSAGetLastError(): %i", WSAGetLastError() );
    }
    
    int send_count = send(socket->handle, (char *) data.base, (int) data.count, 0);
    if (send_count == SOCKET_ERROR)
    {
        auto error = WSAGetLastError();
        if (error == WSAECONNRESET)
            return false;
        
        require(false, "send(socket->handle, (char *) data.base, (int) data.count, 0) failed with WSAGetLastError(): %i", error);
    }
    assert(send_count == data.count);
    
    return true;
}

bool platform_network_receive(u8_array buffer, usize *byte_offset, platform_socket *socket, u32 timeout_milliseconds)
{
    fd_set read_sockets;
    FD_ZERO(&read_sockets);
    FD_SET(socket->handle, &read_sockets);
    
    if (timeout_milliseconds != platform_network_timeout_milliseconds_block)
    {
        timeval timeout = {};
        timeout.tv_sec  = timeout_milliseconds / 1000;
        timeout.tv_usec = (timeout_milliseconds % 1000) * 1000;
        auto result = select(0, &read_sockets, null, null, &timeout);
        
        // timeout, return nothing
        if (!result)
            return true;
        
        require(result != SOCKET_ERROR, "select(0, &read_sockets, null, null, &timeout) failed with WSAGetLastError(): %i", WSAGetLastError() );
    }
    else
    {
        require( select(0, &read_sockets, null, null, null) != SOCKET_ERROR, "WSAGetLastError(): %i", WSAGetLastError() );
    }
    
    int receive_count = recv(socket->handle, (char *) buffer.base + *byte_offset, (int) (buffer.count - *byte_offset), 0);
    if (receive_count == SOCKET_ERROR)
    {
        auto error = WSAGetLastError();
        if (error == WSAECONNRESET)
            return false;
        
        require(false, "recv(socket->handle, (char *) buffer.base + *byte_offset, (int) (buffer.count - *byte_offset), 0) failed with WSAGetLastError(): %i", error);
    }
    
    *byte_offset += receive_count;
    
    return true;
}