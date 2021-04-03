# author: Cassidy Johnson
# purpose: a sample client file that creates 2 clients, both connecting to server.py

import socket

def connect():
	with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
		s.connect(('54.243.90.219', 9998))

		message = b'hello'
		s.sendall(message)

		message = b'hi'
		s.sendto(message, ('54.243.90.219', 9998))

		while 1:
			received = s.recv(1024)
			if received == b'Message to update stuff':
				# leave
				message = b'LEAVE'
				s.sendto(message, ('54.243.90.219', 9998))
				break
		s.close()

if __name__ == '__main__':
	connect()
