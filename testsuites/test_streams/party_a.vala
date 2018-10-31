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

IListenerHandle party_a_s;

void party_a_body() {
    IStreamDelegate stream_dlg = new ServerStreamDelegate();
    IErrorHandler error_handler = new ServerErrorHandler("for stream_system_listen conn_10_1_1_1");
    party_a_s = stream_system_listen("conn_10_1_1_1", stream_dlg, error_handler);
    if (verbose) print("party a is listening.\n");
    //

    tasklet.ms_wait(3000);
    party_a_s.kill();
    if (verbose) print("party a has done waiting. :(\n");
}

void party_a_cleanup() {
    party_a_s.kill();
    if (verbose) print("party a has been shut down correctly.\n");
}

class ServerErrorHandler : Object, IErrorHandler
{
    private string name;
    public ServerErrorHandler(string name)
    {
        this.name = name;
    }

    public void error_handler(Error e)
    {
        error(@"ServerErrorHandler '$(name)': $(e.message)");
    }
}

class ServerStreamDelegate : Object, IStreamDelegate
{
    public IStreamDispatcher? get_dispatcher(StreamCallerInfo caller_info)
    {
        assert(caller_info.listener is StreamSystemListener);
        StreamSystemListener _listener = (StreamSystemListener)caller_info.listener;
        if (verbose) print(@"_listener.listen_pathname = '$(_listener.listen_pathname)'.\n");
        if (verbose) print(@"caller_info.source_id = '$(caller_info.source_id)'.\n");
        if (verbose) print(@"caller_info.src_nic = '$(caller_info.src_nic)'.\n");
        if (verbose) print(@"caller_info.unicast_id = '$(caller_info.unicast_id)'.\n");
        if (verbose) print(@"caller_info.m_name = '$(caller_info.m_name)'.\n");
        if (verbose) print(@"caller_info.wait_reply = $(caller_info.wait_reply ? "TRUE" : "FALSE").\n");
        // use cases:
        if (caller_info.m_name == "wrong") return null;
        if (caller_info.m_name == "void" || caller_info.m_name == "test1") return new ServerStreamDispatcher();
        error("not implemented yet");
    }
}

class ServerStreamDispatcher : Object, IStreamDispatcher
{
    public string execute(string m_name, Gee.List<string> args, StreamCallerInfo caller_info)
    {
        string next = "";
        if (verbose) print(@"party_a executing $(m_name)(");
        foreach (string arg in args)
        {
            if (verbose) print(@"$(next)'$(arg)'");
            next = ", ";
        }
        if (verbose) print(")\n");
        if (m_name == "void") return "";
        return "{}";
    }
}