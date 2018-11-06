/*
 *  This file is part of Netsukuku.
 *  (c) Copyright 2018 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
 *
 *  Netsukuku is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Netsukuku is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Netsukuku.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gee;
using zcd;
using TaskletSystem;

bool launched;
// Node alpha: pid=1234, I=wlan0
const int PID = 1234;
const string LISTEN_PATHNAME = "recv_1234_wlan0";
const string PSEUDOMAC = "fe:aa:aa:aa:aa:aa";
const string SEND_PATHNAME = "send_1234_wlan0";

void do_peculiar() {
    // wait for "launch()"
    launched = false;
    while (! launched) tasklet.ms_wait(5);
    tasklet.ms_wait(100);

    // message: alpha1
    int packet_id = mymsgs[mynextmsgindex++];
    datagram_dlg.sending_msg(packet_id);
    try {
        send_datagram_system(SEND_PATHNAME, packet_id,
            "{}", my_src_nic, "{}",
            "alpha1", new ArrayList<string>(), true);
    } catch (ZCDError e) {
        error(@"alpha_main: alpha1: $(e.message)");
    }

    // wait 400 ms"
    tasklet.ms_wait(400);
}

void do_peculiar_check() {
    // Implicit check that alpha has been launched.
    // Check that alpha receives ack from beta for its msg:
    int i = events.index_of(">ack_1234001_fe:bb:bb:bb:bb:bb\n");
    assert(i >= 0);
    // Check that alpha doesn't receive its own req:
    i = events.index_of(">req_1234001_alpha1\n");
    assert(i < 0);
    // Check that alpha doesn't receive req from gamma:
    i = events.index_of(">req_890001_gamma1\n");
    assert(i < 0);
/*

alpha events:
>req_567001_launch
>ack_1234001_fe:bb:bb:bb:bb:bb
---------------

beta events:
>ack_567001_fe:cc:cc:cc:cc:cc
>ack_567001_fe:aa:aa:aa:aa:aa
>req_1234001_alpha1
>req_890001_gamma1
---------------

gamma events:
>req_567001_launch
---------------

*/
}

class ServerDatagramDispatcher : Object, IDatagramDispatcher
{
    public void execute(string m_name, Gee.List<string> args, DatagramCallerInfo caller_info)
    {
        string next = "";
        if (verbose) print(@"executing $(m_name)(");
        foreach (string arg in args)
        {
            if (verbose) print(@"$(next)'$(arg)'");
            next = ", ";
        }
        if (verbose) print(")\n");
        if (m_name == "launch") launched = true;
    }
}