

module network;

import platform;

// defined in plaform specific file
// struct platform_network_socket
// struct platform_network

func htons(value u16) (result u16)
{
    return (value bit_shift_right 8) bit_or (value bit_shift_left 8);
}

func ntohs(value u16) (result u16)
{
    return htons(value);
}

type platform_network_ip union 
{
    expand u8_values u8[4];
    expand u32_value u32;
};

struct platform_network_address
{       
    ip   platform_network_ip;
    port u16;    
}

struct platform_network_socket_base
{
    address platform_network_address;
}

def platform_network_timeout_milliseconds_zero =   0 cast(u32);
def platform_network_timeout_milliseconds_block = -1 cast(u32);

func platform_network_init_type(network platform_network ref);
func platform_network_shutdown_type(network platform_network ref);
func platform_network_is_valid_type(test_socket platform_network_socket) (ok b8);
func platform_network_listen_type(network platform_network ref, port u16, connection_count u32) (result platform_network_socket);
func platform_network_accept_type(network platform_network ref, listen_socket platform_network_socket ref, timeout_milliseconds = platform_network_timeout_milliseconds_block) (result platform_network_socket);
func platform_network_connect_begin_type(network platform_network ref, ip platform_network_ip, port u16) (ok b8, connect_socket platform_network_socket);
func platform_network_connect_end_type(network platform_network ref, connect_socket platform_network_socket ref, timeout_milliseconds = platform_network_timeout_milliseconds_block) (ok b8);
func platform_network_connect_type(network platform_network ref, ip platform_network_ip, port u16, timeout_milliseconds = platform_network_timeout_milliseconds_block) (ok b8, connect_socket platform_network_socket);
func platform_network_disconnect_type(network platform_network ref, connect_socket platform_network_socket ref, timeout_milliseconds = platform_network_timeout_milliseconds_block) (ok b8);
func platform_network_bind_type(network platform_network ref, port u16 = 0) (udp_socket platform_network_socket);
func platform_network_send_type(network platform_network ref, send_socket platform_network_socket, ip = {} platform_network_ip, port u16 = 0, data u8[], timeout_milliseconds = platform_network_timeout_milliseconds_block) (ok b8);
func platform_network_receive_type(network platform_network ref, receive_socket platform_network_socket, buffer u8[], buffer_used_byte_count usize ref, timeout_milliseconds = platform_network_timeout_milliseconds_block) (ok b8, ip platform_network_ip, port u16);

func platform_network_connect platform_network_connect_type
{
    var result = platform_network_connect_begin(network, ip, port);                
    if not result.ok or not platform_network_connect_end(network, result.connect_socket ref, timeout_milliseconds)
        return false, {} platform_network_socket;

    return true, result.connect_socket;
}
