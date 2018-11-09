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

void output_api(Gee.List<Root> roots, Gee.List<Exception> errors)
{
    string contents = prettyformat("""
using Gee;

namespace SampleRpc
{
    public errordomain StubError
    {
        DID_NOT_WAIT_REPLY,
        GENERIC
    }

    public errordomain DeserializeError
    {
        GENERIC
    }

    public interface IErrorHandler : Object
    {
        public abstract void error_handler(Error e);
    }

    public interface IDelegate : Object
    {
    """);
    foreach (Root r in roots)
    {
        contents += prettyformat("""
        public abstract Gee.List<I""" + @"$(r.rootclass)" + """Skeleton> get_""" + @"$(r.rootname)" + """_set(CallerInfo caller);
        """);
    }
    contents += prettyformat("""
    }

    public interface IListenerHandle : Object
    {
        public abstract void kill();
    }

    public interface ISerializable : Object
    {
        public abstract bool check_deserialization();
    }
}
    """);
    write_file("api.vala", contents);
}