extends Node
class_name UDPReceiver

var udp_listener : PacketPeerUDP = PacketPeerUDP.new()

func init_receiver():
	udp_listener.bind(4001, "0.0.0.0", 65536)
	
func receive():
	if udp_listener.get_available_packet_count() > 0:
		return udp_listener.get_packet()
	else:
		return null
