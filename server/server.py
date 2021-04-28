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

# global hash of users' ips:ports
users_ips_ports = dict()

# global hash of participant uuid:ip
uuid_hash = dict()

# global hash of (ip, port):thread
addr_thread_hash = dict()

# global hash of ip:socket
socket_hash = dict()

#def export(addr_tuple):
	# make a pdf
	# send it to them in an email? iMessage? get their permission to put it in their iOS file system on the device?

def send_changes_to_user(addr_tuple, send_to_this_ip, message):
    if len(addr_tuple) != 2:
        raise RuntimeError

    addr = (send_to_this_ip, users_ips_ports[send_to_this_ip])
    s = socket_hash[send_to_this_ip]
    s.sendto(message, addr)
    print("I'm sending changes to these users: ")
    print(addr)

def listen(conn, addr):
    global global_data

    print("Created a new thread for user at " + str(addr))
    while 1:
        data = conn.recv(4096)

        if data:
            print("I received a message from " + str(addr))
            if addr in users_ips_ports.items():
                print("The message is " + str(data))

                data_arr = data.split(b'\t')
                if len(data) > 5:
                    if data_arr[0] == b'HELLO':
                        my_id = data_arr[1]
                        their_id = data_arr[2]
                        uuid_hash[my_id] = addr[0]
                        print(my_id)
                        print("new user")

                elif data == b'LEAVE':
                    # remove them from the addr_thread_hash and join the thread
                    try:
                        print("This user is leaving")
                        thread_id = addr_thread_hash[addr]
                        del(addr_thread_hash[addr])
                        users_ips.remove(addr[0])
                        del(users_ips_ports[addr[0]])
                        del(socket_hash[addr[0]])
                        sys.exit() # use this to join the thread from within the thread
                    except KeyError:
                        print("Couldn't find the user who was trying to leave the session")	
                        continue
                
                # get the UUID of the other person in the imessage session
                message_arr = data.split(b'\t')
                uuid = message_arr[1]

                # find the ip that corresponds to that uuid
                try:
                    send_to_this_ip = uuid_hash[uuid]
                except KeyError:
                    continue
                global_data.append(data)
                send_changes_to_user(addr, send_to_this_ip, data)
    

def serve():
    # create a socket
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    my_ip = ''
    my_port = 9998
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((my_ip, my_port))

    # for now, only allow 2 users to connect at a time
    s.listen() 

    while 1:
        conn, addr = s.accept()

        # add the new user to the set of users
        users_ips.add(addr[0])
        users_ips_ports[addr[0]] = addr[1]
        print("Adding a new user\n")

        # make a new thread for this user
        new_thread = threading.Thread(target=listen, args=(conn, addr,))
        socket_hash[addr[0]] = conn
        addr_thread_hash[addr] = new_thread
    
        new_thread.start()

        if len(addr_thread_hash) == 0:
            break

    s.close()


if __name__ == '__main__':
    print("starting server")
    serve()


