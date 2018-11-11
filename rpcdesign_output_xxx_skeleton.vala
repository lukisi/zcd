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

void output_xxx_skeleton(Root r, Gee.List<Exception> errors)
{
    /*
     * start flow:
            string contents = prettyformat("""
     * break flow:
            """);
            contents += prettyformat("""
     * reopen flow:
            contents += prettyformat("""
            """);
     * insert variable:
            """ + @"$(j)" + """
    */
    string contents = prettyformat("""
using Gee;
using TaskletSystem;

namespace SampleRpc
{
    """);
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
    string s_if = "if";
    foreach (ModuleRemote mo in r.modules)
    {
        contents += prettyformat("""
        """ + @"$(s_if)" + """ (m_name.has_prefix("""" + @"$(r.rootname)" + """.""" + @"$(mo.modname)" + """."))
        {
        """);
        string s_if2 = "if";
        foreach (Method me in mo.methods)
        {
            contents += prettyformat(
@"          $(s_if2) (m_name == \"$(r.rootname).$(mo.modname).$(me.name)\")");
            contents += prettyformat("""
            {
                if (args.size != """ + @"$(me.args.size)" + """) throw new InSkeletonDeserializeError.GENERIC(@"Wrong number of arguments for $(m_name)");

            """);
            if (me.args.size > 0)
            {
                contents += prettyformat("""
                // arguments:
                """);
                for (int j = 0; j < me.args.size; j++)
                {
                    Argument arg = me.args[j];
                    contents += prettyformat(
@"              $(arg.argclass) arg$(j);");
                }
                contents += prettyformat("""
                // position:
                int j = 0;
                """);
                for (int j = 0; j < me.args.size; j++)
                {
                    Argument arg = me.args[j];
                    contents += prettyformat("""
                {
                    // deserialize arg""" + @"$(j) ($(arg.argclass) $(arg.argname))" + """
                    string arg_name = """ + @"\"$(arg.argname)\"" + """;
                    string doing = @"Reading argument '$(arg_name)' for $(m_name)";
                    try {
                    """);
                    switch (arg.argclass)
                    {
                        case "string":
                            contents += prettyformat("""
                        arg""" + @"$(j)" + """ = read_argument_string_notnull(args[j]);
                            """);
                            break;
                        case "string?":
                            contents += prettyformat("""
                        arg""" + @"$(j)" + """ = read_argument_string_maybe(args[j]);
                            """);
                            break;
                        case "bool":
                            contents += prettyformat("""
                        arg""" + @"$(j)" + """ = read_argument_bool_notnull(args[j]);
                            """);
                            break;
                        case "bool?":
                            contents += prettyformat("""
                        arg""" + @"$(j)" + """ = read_argument_bool_maybe(args[j]);
                            """);
                            break;
                        case "int":
                            contents += prettyformat("""
                        int64 val;
                        val = read_argument_int64_notnull(args[j]);
                        if (val > int.MAX || val < int.MIN)
                            throw new InSkeletonDeserializeError.GENERIC(@"$(doing): argument overflows size of int");
                        arg""" + @"$(j)" + """ = (int)val;
                            """);
                            break;
                        case "int64":
                            contents += prettyformat("""
                        int64 val;
                        val = read_argument_int64_notnull(args[j]);
                        arg""" + @"$(j)" + """ = (int)val;
                            """);
                            break;
                        case "uint16":
                            contents += prettyformat("""
                        int64 val;
                        val = read_argument_int64_notnull(args[j]);
                        if (val > uint16.MAX || val < uint16.MIN)
                            throw new InSkeletonDeserializeError.GENERIC(@"$(doing): argument overflows size of uint16");
                        arg""" + @"$(j)" + """ = (uint16)val;
                            """);
                            break;
                        case "int?":
                            error("not implemented yet");
                        case "Gee.List<int>":
                            contents += prettyformat("""
                        Gee.List<int64?> values;
                        values = read_argument_array_of_int64(args[j]);
                        arg""" + @"$(j)" + """ = new ArrayList<int>();
                        foreach (int64 val in values)
                        {
                            if (val > int.MAX || val < int.MIN)
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): argument overflows size of int");
                            arg""" + @"$(j)" + """.add((int)val);
                        }
                            """);
                            break;
                        default:
                            if (type_is_basic(arg.argclass)) error(@"not implemented yet $(arg.argclass)");
                            if (arg.argclass.has_prefix("Gee.List<"))
                            {
                                if (arg.argclass.has_suffix("?")) error(@"not supported nullable list: $(arg.argclass)");
                                if (arg.argclass.has_suffix("?>")) error(@"not supported list of nullable: $(arg.argclass)");
                                if (!arg.argclass.has_suffix(">")) error(@"not supported type: $(arg.argclass)");
                                string eltype = arg.argclass.substring(9, arg.argclass.length-10);
                                contents += prettyformat("""
                        Gee.List<Object> values;
                        values = read_argument_array_of_object(typeof(""" + eltype + """), args[j]);
                        foreach (Object val in values) if (val is ISerializable)
                            if (!((ISerializable)val).check_deserialization())
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): instance of $(val.get_type().name()) has not been fully deserialized");
                        arg""" + @"$(j)" + """ = (Gee.List<""" + eltype + """>)values;
                                """);
                            }
                            else if (arg.argclass.has_suffix("?"))
                            {
                                string eltype = arg.argclass.substring(0, me.returntype.length-1);
                                contents += prettyformat("""
                        Object? val;
                        val = read_argument_object_maybe(typeof(""" + eltype + """), args[j]);
                        if (val == null)
                        {
                            arg""" + @"$(j)" + """ = null;
                        }
                        else
                        {
                            if (val is ISerializable)
                                if (!((ISerializable)val).check_deserialization())
                                    throw new InSkeletonDeserializeError.GENERIC(@"$(doing): instance of $(val.get_type().name()) has not been fully deserialized");
                            arg""" + @"$(j)" + """ = (""" + eltype + """)val;
                        }
                                """);
                            }
                            else
                            {
                                contents += prettyformat("""
                        Object val;
                        val = read_argument_object_notnull(typeof(""" + arg.argclass + """), args[j]);
                        if (val is ISerializable)
                            if (!((ISerializable)val).check_deserialization())
                                throw new InSkeletonDeserializeError.GENERIC(@"$(doing): instance of $(val.get_type().name()) has not been fully deserialized");
                        arg""" + @"$(j)" + """ = (""" + arg.argclass + """)val;
                                """);
                            }
                            break;
                    }
                    contents += prettyformat("""
                    } catch (HelperNotJsonError e) {
                        critical(@"Error parsing JSON for argument: $(e.message)");
                        critical(@" method-name: $(m_name)");
                        error(@" argument #$(j): $(args[j])");
                    } catch (HelperDeserializeError e) {
                        throw new InSkeletonDeserializeError.GENERIC(@"$(doing): $(e.message)");
                    }
                    j++;
                }
                    """);
                }
            }
            contents += prettyformat("""

            """);
            string try_indent = "";
            if (me.errors.size > 0)
            {
                try_indent = "    ";
                contents += prettyformat("""
                try {
                """);
            }
            string args_call = "(";
            for (int j = 0; j < me.args.size; j++) args_call += @"arg$(j), ";
            args_call += "caller_info)";
            string method_call = @"$(r.rootname).$(mo.modname).$(me.name)$(args_call);";
            switch (me.returntype)
            {
                case "void":
                    contents += prettyformat("""
                """ + try_indent + method_call + """
                """ + try_indent + """ret = prepare_return_value_null();
                    """);
                    break;
                case "string":
                    contents += prettyformat("""
                """ + try_indent + """string result = """ + method_call + """
                """ + try_indent + """ret = prepare_return_value_string(result);
                    """);
                    break;
                case "string?":
                    contents += prettyformat("""
                """ + try_indent + """string? result = """ + method_call + """
                """ + try_indent + """if (result == null) ret = prepare_return_value_null();
                """ + try_indent + """else ret = prepare_return_value_string(result);
                    """);
                    break;
                case "int":
                    contents += prettyformat("""
                """ + try_indent + """int result = """ + method_call + """
                """ + try_indent + """ret = prepare_return_value_int64(result);
                    """);
                    break;
                case "int?":
                    contents += prettyformat("""
                """ + try_indent + """int? result = """ + method_call + """
                """ + try_indent + """if (result == null) ret = prepare_return_value_null();
                """ + try_indent + """else ret = prepare_return_value_int64(result);
                    """);
                    break;
                case "uint16":
                    contents += prettyformat("""
                """ + try_indent + """uint16 result = """ + method_call + """
                """ + try_indent + """ret = prepare_return_value_int64(result);
                    """);
                    break;
                case "uint16?":
                    contents += prettyformat("""
                """ + try_indent + """uint16? result = """ + method_call + """
                """ + try_indent + """if (result == null) ret = prepare_return_value_null();
                """ + try_indent + """else ret = prepare_return_value_int64(result);
                    """);
                    break;
                case "bool":
                    contents += prettyformat("""
                """ + try_indent + """bool result = """ + method_call + """
                """ + try_indent + """ret = prepare_return_value_boolean(result);
                    """);
                    break;
                case "bool?":
                    contents += prettyformat("""
                """ + try_indent + """bool? result = """ + method_call + """
                """ + try_indent + """if (result == null) ret = prepare_return_value_null();
                """ + try_indent + """else ret = prepare_return_value_boolean(result);
                    """);
                    break;
                case "Gee.List<string>":
                    contents += prettyformat("""
                """ + try_indent + """Gee.List<string> result = """ + method_call + """
                """ + try_indent + """ret = prepare_return_value_array_of_string(result);
                    """);
                    break;
                default:
                    if (type_is_basic(me.returntype)) error(@"not implemented yet $(me.returntype)");
                    if (me.returntype.has_prefix("Gee.List<"))
                    {
                        if (me.returntype.has_suffix("?")) error(@"not supported nullable list: $(me.returntype)");
                        if (me.returntype.has_suffix("?>")) error(@"not supported list of nullable: $(me.returntype)");
                        if (!me.returntype.has_suffix(">")) error(@"not supported type: $(me.returntype)");
                        contents += prettyformat("""
                """ + try_indent + me.returntype + """ result = """ + method_call + """
                """ + try_indent + """ret = prepare_return_value_array_of_object(result);
                        """);
                    }
                    else if (me.returntype.has_suffix("?"))
                    {
                        contents += prettyformat("""
                """ + try_indent + me.returntype + """ result = """ + method_call + """
                """ + try_indent + """if (result == null) ret = prepare_return_value_null();
                """ + try_indent + """else ret = prepare_return_value_object(result);
                        """);
                    }
                    else
                    {
                        contents += prettyformat("""
                """ + try_indent + me.returntype + """ result = """ + method_call + """
                """ + try_indent + """ret = prepare_return_value_object(result);
                        """);
                    }
                    break;
            }
            if (me.errors.size > 0)
            {
                foreach (Exception err in me.errors)
                {
                    contents += prettyformat("""
                } catch (""" + err.errdomain + """ e) {
                    string code = "";
                    """);
                    foreach (string code in err.errcodes)
                    {
                        contents += prettyformat(
@"                      if (e is $(err.errdomain).$(code)) code = \"$(code)\";");
                        }
                        contents += prettyformat("""
                    assert(code != "");
                    ret = prepare_error(""" + @"\"$(err.errdomain)\"" + """, code, e.message);
                    """);
                }
                contents += prettyformat("""
                }
                """);
            }
            contents += prettyformat("""
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
}
    """);
    write_file(@"$(r.rootname)_skeleton.vala", contents);
}