# author: Cassidy Johnson
# purpose: a sample client file that creates 2 clients, both connecting to server.py

import socket

def connect():
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	s.connect(('127.0.0.1', 9998))

	message = b'hello'
	s.sendto(message, ('127.0.0.1', 9998))

	message = b'hi'
	s.sendto(message, ('127.0.0.1', 9998))

	while 1:
		received = s.recv(1024)
		if received == b'Message to update stuff':
			# leave
			message = b'LEAVE'
			s.sendto(message, ('127.0.0.1', 9998))
			break
	s.close()

if __name__ == '__main__':
	connect()
