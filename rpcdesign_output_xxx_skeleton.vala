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

void output_xxx_skeleton(Gee.List<Root> roots, Gee.List<Exception> errors, string xxx)
{
    string contents = prettyformat("""
using Gee;
using TaskletSystem;

namespace SampleRpc
{
    """);
    foreach (Root r in roots)
    {
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
    public interface I""" + @"$(mo.modclass)" + """Skeleton : Object
    {
            """);
            foreach (Method me in mo.methods)
            {
                string signature = @"$(me.returntype) $(me.name)(";
                foreach (Argument arg in me.args)
                {
                    signature += @"$(arg.argclass) $(arg.argname), ";
                }
                signature += "CallerInfo? caller=null)";
                if (!me.errors.is_empty)
                {
                    signature += " throws ";
                    string next = "";
                    foreach (Exception exc in me.errors)
                    {
                        signature += @"$(next)$(exc.errdomain)";
                        next = ", ";
                    }
                }
                contents += prettyformat("""
        public abstract """ + @"$(signature)" + """;
                """);
            }
        contents += prettyformat("""
    }

        """);
        }
        contents += prettyformat("""
    public interface I""" + @"$(r.rootclass)" + """Skeleton : Object
    {
        """);
        foreach (ModuleRemote mo in r.modules)
        {
            contents += prettyformat("""
        protected abstract unowned I""" + @"$(mo.modclass)" + """Skeleton """ + @"$(mo.modname)" + """_getter();
        public I""" + @"$(mo.modclass)" + """Skeleton """ + @"$(mo.modname)" + """ {get {return """ + @"$(mo.modname)" + """_getter();}}
            """);
        }
        contents += prettyformat("""
    }

        """);
    }
    contents += prettyformat("""
    internal errordomain InSkeletonDeserializeError {
        GENERIC
    }
    """);
    foreach (Root r in roots)
    {
        contents += prettyformat("""

    internal class """ + @"$(r.rootclass)" + """StreamDispatcher : Object, zcd.IStreamDispatcher
    {
        public """ + @"$(r.rootclass)" + """StreamDispatcher(I""" + @"$(r.rootclass)" + """Skeleton """ + @"$(r.rootname)" + """)
        {
            this.""" + @"$(r.rootname)" + """ = """ + @"$(r.rootname)" + """;
        }
        private I""" + @"$(r.rootclass)" + """Skeleton """ + @"$(r.rootname)" + """;

        public string execute(string m_name, Gee.List<string> args, zcd.StreamCallerInfo caller_info)
        {
            StreamCallerInfo mod_caller_info;
            try {
                mod_caller_info = new StreamCallerInfo(caller_info);
            } catch (HelperDeserializeError e) {
                warning(@"Error deserializing parts of zcd.StreamCallerInfo: $(e.message)");
                tasklet.exit_tasklet();
            }
            try {
                return """ + @"$(r.rootname)" + """_dispatcher_execute_rpc(""" + @"$(r.rootname)" + """, m_name, args, mod_caller_info);
            } catch(InSkeletonDeserializeError e) {
                return prepare_error("DeserializeError", "GENERIC", e.message);
            }
        }
    }

    internal class """ + @"$(r.rootclass)" + """DatagramDispatcher : Object, zcd.IDatagramDispatcher
    {
        public """ + @"$(r.rootclass)" + """DatagramDispatcher(Gee.List<I""" + @"$(r.rootclass)" + """Skeleton> """ + @"$(r.rootname)" + """_set)
        {
            this.""" + @"$(r.rootname)" + """_set = """ + @"$(r.rootname)" + """_set;
        }
        private Gee.List<I""" + @"$(r.rootclass)" + """Skeleton> """ + @"$(r.rootname)" + """_set;

        public void execute(string m_name, Gee.List<string> args, zcd.DatagramCallerInfo caller_info)
        {
            assert(! """ + @"$(r.rootname)" + """_set.is_empty);
            foreach (var """ + @"$(r.rootname)" + """ in """ + @"$(r.rootname)" + """_set)
            {
                tasklet.spawn(new DispatchTasklet(""" + @"$(r.rootname)" + """, m_name, args, caller_info));
            }
        }

        private class DispatchTasklet : Object, ITaskletSpawnable
        {
            public DispatchTasklet(I""" + @"$(r.rootclass)" + """Skeleton """ + @"$(r.rootname)" + """, string m_name, Gee.List<string> args, zcd.DatagramCallerInfo caller_info)
            {
                this.""" + @"$(r.rootname)" + """ = """ + @"$(r.rootname)" + """;
                this.m_name = m_name;
                this.args = args;
                this.caller_info = caller_info;
            }
            private I""" + @"$(r.rootclass)" + """Skeleton """ + @"$(r.rootname)" + """;
            private string m_name;
            private Gee.List<string> args;
            private zcd.DatagramCallerInfo caller_info;
            public void* func()
            {
                DatagramCallerInfo mod_caller_info;
                try {
                    mod_caller_info = new DatagramCallerInfo(caller_info);
                } catch (HelperDeserializeError e) {
                    warning(@"Error deserializing parts of zcd.DatagramCallerInfo: $(e.message)");
                    tasklet.exit_tasklet();
                }
                try {
                    """ + @"$(r.rootname)" + """_dispatcher_execute_rpc(""" + @"$(r.rootname)" + """, m_name, args, mod_caller_info);
                } catch(InSkeletonDeserializeError e) {
                }
                return null;
            }
        }
    }

    internal string """ + @"$(r.rootname)" + """_dispatcher_execute_rpc(
        I""" + @"$(r.rootclass)" + """Skeleton """ + @"$(r.rootname)" + """,
        string m_name, Gee.List<string> args, CallerInfo mod_caller_info)
        throws InSkeletonDeserializeError
    {
        string ret;
        """);
        // """ + @"$(r.rootclass)" + """
        // """ + @"$(r.rootname)" + """
        string s_if = "if";
        foreach (ModuleRemote mo in r.modules)
        {
            // """ + @"$(mo.modclass)" + """
            // """ + @"$(mo.modname)" + """
            contents += prettyformat("""
        if (m_name.has_prefix("""" + @"$(r.rootname)" + """.""" + @"$(mo.modname)" + """."))
        {
            """);
            string s_if2 = "if";
            foreach (Method me in mo.methods)
            {
                // """ + @"$(me.returntype)" + """
                // """ + @"$(me.name)" + """
                // """ + @"$(me.args)" + """
                // """ + @"$(me.errors)" + """
                contents += prettyformat("""
            if (m_name == "node.neighborhood_manager.here_i_am")
            {
                if (args.size != 3) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

                // arguments:
                INeighborhoodNodeIDMessage arg0;
                string arg1;
                string arg2;
                // position:
                int j = 0;
                {
                    // deserialize arg0 (INeighborhoodNodeIDMessage my_id)
                    string arg_name = "my_id";
                    string doing = @"Reading argument '$(arg_name)' for $(m_name)";
                    try {
                        Object val;
                        val = read_argument_object_notnull(typeof(INeighborhoodNodeIDMessage), args[j]);
                        if (val is ISerializable)
                            if (!((ISerializable)val).check_deserialization())
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): instance of $(val.get_type().name()) has not been fully deserialized");
                        arg0 = (INeighborhoodNodeIDMessage)val;
                    } catch (HelperNotJsonError e) {
                        error(@"Error parsing JSON for argument: $(e.message)" +
                              @" method-name: $(m_name)" +
                              @" argument #$(j): $(args[j])");
                    } catch (HelperDeserializeError e) {
                        throw new InSkeletonDeserializeError.GENERIC(@"$(doing): $(e.message)");
                    }
                    j++;
                }
                {
                    // deserialize arg1 (string my_mac)
                    string arg_name = "my_mac";
                    string doing = @"Reading argument '$(arg_name)' for $(m_name)";
                    try {
                        arg1 = read_argument_string_notnull(args[j]);
                    } catch (HelperNotJsonError e) {
                        error(@"Error parsing JSON for argument: $(e.message)" +
                              @" method-name: $(m_name)" +
                              @" argument #$(j): $(args[j])");
                    } catch (HelperDeserializeError e) {
                        throw new InSkeletonDeserializeError.GENERIC(@"$(doing): $(e.message)");
                    }
                    j++;
                }
                {
                    // deserialize arg2 (string my_nic_addr)
                    string arg_name = "my_nic_addr";
                    string doing = @"Reading argument '$(arg_name)' for $(m_name)";
                    try {
                        arg2 = read_argument_string_notnull(args[j]);
                    } catch (HelperNotJsonError e) {
                        error(@"Error parsing JSON for argument: $(e.message)" +
                              @" method-name: $(m_name)" +
                              @" argument #$(j): $(args[j])");
                    } catch (HelperDeserializeError e) {
                        throw new InSkeletonDeserializeError.GENERIC(@"$(doing): $(e.message)");
                    }
                    j++;
                }

                node.neighborhood_manager.here_i_am(arg0, arg1, arg2, mod_caller_info);
                ret = prepare_return_value_null();
            }
                """);
                s_if2 = "else if";
            }
            contents += prettyformat("""
            else
            {
                throw new InSkeletonDeserializeError.GENERIC(@"Unknown method in """ + @"$(r.rootname)" + """.""" + @"$(mo.modname)" + """: \"$(m_name)\"");
            }
        }
            """);
            s_if = "else if";
        }
        contents += prettyformat("""
        else
        {
            throw new InSkeletonDeserializeError.GENERIC(@"Unknown module in """ + @"$(r.rootname)" + """: \"$(m_name)\"");
        }
        return ret;
    }
        """);
    }
    contents += prettyformat("""
}
    """);
    write_file(@"$(xxx)_skeleton.vala", contents);
}