extends Node
class_name UDPSender

var udp_server : PacketPeerUDP = PacketPeerUDP.new()

func init_sender():
	udp_server.set_broadcast_enabled(true)
	
func sendto(addr:String, port:int, message:String):
	udp_server.set_dest_address(addr, port)
	udp_server.put_packet(message.to_utf8_buffer())

