#encoding: utf-8
import socket
import json


class sender:

    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    PORT = 4001
    HOST = '255.255.255.255'

    def __init__(self, HOST_IP, PORT):
        self.HOST = HOST_IP
        PORT = PORT
        self.s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        self.s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR, 1)

    def send(self, message):
        self.s.sendto(json.dumps(message).encode('utf-8'),
         (self.HOST, self.PORT))