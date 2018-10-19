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
using TaskletSystem;

namespace zcd
{
    public errordomain ZCDError {
        GENERIC
    }

    public interface IErrorHandler : Object
    {
        public abstract void error_handler(Error e);
    }

    public interface IStreamDispatcher : Object
    {
        public abstract string execute(string m_name, Gee.List<string> args, StreamCallerInfo caller_info);
    }

    public interface IStreamDelegate : Object
    {
        public abstract IStreamDispatcher? get_dispatcher(StreamCallerInfo caller_info);
    }

    public interface IDatagramDispatcher : Object
    {
        public abstract void execute(string m_name, List<string> args, DatagramCallerInfo caller_info);
    }

    public interface IDatagramDelegate : Object
    {
        public abstract bool is_my_own_message(int packet_id);
        public abstract IDatagramDispatcher? get_dispatcher(DatagramCallerInfo caller_info);
        public abstract void got_ack(int packet_id, string ack_mac);
    }

    public interface IListenerHandle : Object
    {
        public abstract void kill();
    }
}