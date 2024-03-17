

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

type platform_network_ip_v4 union
{
    expand u8_values u8[4];
    expand u32_value u32;
};

type platform_network_ip_v6 union
{
    expand u64_values u64[2];
    expand u16_values u16[8];
};

enum platform_network_address_tag u8
{
    invalid;
    ip_v4;
    ip_v6;
}

// this is 3 u64 big :(
struct platform_network_address
{
    tag  platform_network_address_tag;
    port u16;

    expand tags union
    {
        ip_v4 platform_network_ip_v4;
        ip_v6 platform_network_ip_v6;
    };
}

struct platform_network_socket_base
{
    port        u16;
    address_tag platform_network_address_tag;
    is_udp      b8;
}

enum platform_network_result u8
{
    ok; // kinda sad ok is 0 :(

    // recoverable errors

    // close socket and try reconnect
    error_connection_closed;

    // receive buffer is too small
    error_buffer_to_small_for_message;

    // unrecoverable errors

    // trying to reach an ipv6 address, while only supporting ipv4 locally
    error_local_ipv4_can_not_reach_remote_ipv6;
}

def platform_network_timeout_milliseconds_zero =   0 cast(u32);
def platform_network_timeout_milliseconds_block = -1 cast(u32);

func platform_network_init_type(network platform_network ref);
func platform_network_shutdown_type(network platform_network ref);
func platform_network_is_valid_type(test_socket platform_network_socket) (ok b8);

// TCP
func platform_network_listen_type(network platform_network ref, address_tag platform_network_address_tag, port u16, connection_count u32) (result platform_network_socket);
func platform_network_accept_type(network platform_network ref, listen_socket platform_network_socket ref, timeout_milliseconds = platform_network_timeout_milliseconds_block) (accepted_socket platform_network_socket, address platform_network_address);
func platform_network_connect_begin_type(network platform_network ref, expand address platform_network_address) (ok b8, connect_socket platform_network_socket);
func platform_network_connect_end_type(network platform_network ref, connect_socket platform_network_socket ref, timeout_milliseconds = platform_network_timeout_milliseconds_block) (ok b8);
func platform_network_connect_type(network platform_network ref, expand address platform_network_address, timeout_milliseconds = platform_network_timeout_milliseconds_block) (ok b8, connect_socket platform_network_socket);
func platform_network_disconnect_type(network platform_network ref, connect_socket platform_network_socket ref, timeout_milliseconds = platform_network_timeout_milliseconds_block) (ok b8);

func platform_network_connect platform_network_connect_type
{
    var result = platform_network_connect_begin(network, address);
    if not result.ok or not platform_network_connect_end(network, result.connect_socket ref, timeout_milliseconds)
        return false, {} platform_network_socket;

    return true, result.connect_socket;
}

// UDP
func platform_network_peer_open_type(network platform_network ref, address_tag platform_network_address_tag, port u16 = 0) (udp_socket platform_network_socket);
func platform_network_peer_close_type(network platform_network ref, udp_socket platform_network_socket ref);

func platform_network_send_type(network platform_network ref, send_socket platform_network_socket, address = {} platform_network_address, data u8[], timeout_milliseconds = platform_network_timeout_milliseconds_block) (result platform_network_result);

// if has_data is true and buffer_used_byte_count is 0 just continue polling
func platform_network_receive_type(network platform_network ref, receive_socket platform_network_socket, buffer u8[], buffer_used_byte_count usize ref, timeout_milliseconds = platform_network_timeout_milliseconds_block) (result platform_network_result, has_data b8, address platform_network_address);

func platform_network_query_dns_type(network platform_network ref, name string) (ok b8, address platform_network_address);

func is(left platform_network_address, right platform_network_address) (ok b8)
{
    return (left.tag is right.tag) and (left.port is right.port) and (left.ip_v6.u64_values[0] is right.ip_v6.u64_values[0]) and (left.ip_v6.u64_values[1] is right.ip_v6.u64_values[1]);
}

func is_not(left platform_network_address, right platform_network_address) (ok b8)
{
    return not (left is right);
}

func htons(ip_v6 u16[8]) (result u16[8])
{
    loop var i; 8
        ip_v6[i] = htons(ip_v6[i]);

    return ip_v6;
}

func ntohs(ip_v6 u16[8]) (result u16[8])
{
    return htons(ip_v6);
}