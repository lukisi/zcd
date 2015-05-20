/*
 *  This file is part of Netsukuku.
 *  Copyright (C) 2015 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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

using Tasklets;
using Gee;
using AppDomain;

void main(string[] args)
{
    assert(Tasklet.init());
    string prgname = args[0];
    if (prgname.has_suffix("server"))
    {}
    else if (prgname.has_suffix("client"))
    {
        client(args[1], 60296);
    }
    else if (prgname.has_suffix("both"))
    {}
    assert(Tasklet.kill());
}

void client(string peer_ip, uint16 peer_port)
{
    //AppTcpClient c = ModRpc.tcp_client();
}



