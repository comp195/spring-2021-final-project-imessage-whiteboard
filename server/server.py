# author: Cassidy Johnson
# purpose: a server to sit between the two devices using the imessage whiteboard extension
# notes: does it still work if user's ip changes mid-session?

import sys
import socket
import threading

# global data storage 
global_data = list()

# global list of users' info, stored in tuples like this: (user_ip, port)
users = set()

# global hash of (ip, port):thread
addr_thread_hash = dict()

#def export(addr_tuple):
	# make a pdf
	# send it to them in an email? iMessage? get their permission to put it in their iOS file system on the device?

def send_changes_to_users(s, addr_tuple):
	if len(addr_tuple) != 2:
		raise RuntimeError

	# server sends changes to all other clients
	message = b'Message to update stuff'

	# below I'm sending a string, but we will really be sending the data from the global_data list
	for i in users:
		if i == addr_tuple:
			continue
		s.sendto(message, i)

def listen(conn, addr):
	while 1:
		data, addr = conn.recvfrom(1024)
		print("I received a message from " + str(addr))
		if addr in users:
			print("The message is " + str(data))

			if data == b'LEAVE':
				# remove them from the addr_thread_hash and join the thread
				try:
					print("This user is leaving")
					thread_id = addr_thread_hash[addr]
					del(addr_thread_hash[addr])
					sys.exit() # use this to join the thread from within the thread
				except KeyError:
					print("Couldn't find the user who was trying to leave the session")	
					continue
				
			global_data.append(data)
			send_changes_to_users(conn, addr)
	

def serve():
	# create a socket
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	my_ip = '127.0.0.1'
	my_port = 9998
	s.bind((my_ip, my_port))

	# for now, only allow 2 users to connect at a time
	s.listen(2) 

	while 1:
		conn, addr = s.accept()

		# add the new user to the set of users
		users.add(addr)
		print("Adding a new user\n")

		# make a new thread for this user
		new_thread = threading.Thread(target=listen, args=(conn, addr,))
		addr_thread_hash[addr] = new_thread

	s.close()


if __name__ == '__main__':
	serve()


