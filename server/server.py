# author: Cassidy Johnson
# purpose: a server to sit between the two devices using the imessage whiteboard extension
# notes: does it still work if user's ip changes mid-session?

import sys
import socket
import threading

# global data storage 
global_data = list()

# global list of users' info, stored in tuples like this: (user_ip, port)
users_ips = set()
users_ips_ports = dict()

# global hash of (ip, port):thread
addr_thread_hash = dict()

#def export(addr_tuple):
	# make a pdf
	# send it to them in an email? iMessage? get their permission to put it in their iOS file system on the device?

def send_changes_to_users(s, addr_tuple, message):
    if len(addr_tuple) != 2:
        raise RuntimeError

    print("I'm sending changes to these users: ")
    for i in users_ip:
        if i == addr_tuple:
            continue

        addr = (ip, users_ips_ports[i])
        s.sendto(message, i)
        print(str(i))

def listen(conn, addr):
    global global_data

    print("Created a new thread for user at " + str(addr))
    while 1:
        data = conn.recv(4096)

        if data:
            print("I received a message from " + str(addr))
            if addr in users_ip_ports.get_items():
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
                send_changes_to_users(conn, addr, data)
    

def serve():
    # create a socket
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    my_ip = ''
    my_port = 9998
    s.bind((my_ip, my_port))

    # for now, only allow 2 users to connect at a time
    s.listen() 

    while 1:
        conn, addr = s.accept()

        # add the new user to the set of users
        users_ip.add(addr[0])
        users_ips_ports[addr[0]] = addr[1]
        print("Adding a new user\n")

        # make a new thread for this user
        new_thread = threading.Thread(target=listen, args=(conn, addr,))
        addr_thread_hash[addr] = new_thread
    
        new_thread.start()
    s.close()


if __name__ == '__main__':
    print("starting server")
    serve()


