/*
 *  This file is part of Netsukuku.
 *  (c) Copyright 2014 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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
using Tasklets;

void main(string[] args)
{
    assert(Tasklet.init());
    try {
        ServerStreamSocket s = new ServerStreamSocket((uint16)int.parse(args[2]), 10, args[1]);
        while (true)
        {
            IConnectedStreamSocket c = s.accept();
            break;
        }
    } catch (Error e) {
        error(e.message);
    }
    assert(Tasklet.kill());
}


