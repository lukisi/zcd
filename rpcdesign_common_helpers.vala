/*
 *  This file is part of Netsukuku.
 *  (c) Copyright 2015 Luca Dionisi aka lukisi <luca.dionisi@gmail.com>
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

void make_common_helpers(Gee.List<Root> roots, Gee.List<Exception> errors)
{
    string contents = prettyformat("""
using Gee;

namespace zcd
{
    namespace ModRpc
    {
        public errordomain HelperDeserializeError {
            GENERIC
        }

        public errordomain HelperNotJsonError {
            GENERIC
        }

        /* Internal Helper functions to build JSON element */

        internal interface IJsonBuilderElement : Object {
            public abstract void execute(Json.Builder b);
        }

        internal class JsonBuilderNull : Object, IJsonBuilderElement
        {
            public JsonBuilderNull() {}
            public void execute(Json.Builder b) {
                b.add_null_value();
            }
        }

        internal class JsonBuilderInt64 : Object, IJsonBuilderElement
        {
            private int64 i;
            public JsonBuilderInt64(int64 i) {
                this.i = i;
            }
            public void execute(Json.Builder b) {
                b.add_int_value(i);
            }
        }

        internal class JsonBuilderDouble : Object, IJsonBuilderElement
        {
            private double d;
            public JsonBuilderDouble(double d) {
                this.d = d;
            }
            public void execute(Json.Builder b) {
                b.add_double_value(d);
            }
        }

        internal class JsonBuilderBool : Object, IJsonBuilderElement
        {
            private bool b0;
            public JsonBuilderBool(bool b0) {
                this.b0 = b0;
            }
            public void execute(Json.Builder b) {
                b.add_boolean_value(b0);
            }
        }

        internal class JsonBuilderString : Object, IJsonBuilderElement
        {
            private string s;
            public JsonBuilderString(string s) {
                this.s = s;
            }
            public void execute(Json.Builder b) {
                b.add_string_value(s);
            }
        }

        internal class JsonBuilderBinary : Object, IJsonBuilderElement
        {
            private string s;
            public JsonBuilderBinary(uint8[] buf) {
                s = Base64.encode((uchar[])buf);
            }
            public void execute(Json.Builder b) {
                b.add_string_value(s);
            }
        }

        internal class JsonBuilderObject : Object, IJsonBuilderElement
        {
            private Object obj;
            public JsonBuilderObject(Object obj) {
                this.obj = obj;
            }
            public void execute(Json.Builder b) {
                b.begin_object();
                b.set_member_name("typename");
                b.add_string_value(obj.get_type().name());
                b.set_member_name("value");
                Json.Node* obj_n = Json.gobject_serialize(obj);
                b.add_value(obj_n);
                b.end_object();
            }
        }

        internal class JsonBuilderArray : Object, IJsonBuilderElement
        {
            private ArrayList<IJsonBuilderElement> lst;
            public JsonBuilderArray(Gee.List<IJsonBuilderElement> lst) {
                this.lst = new ArrayList<IJsonBuilderElement>();
                this.lst.add_all(lst);
            }
            public void execute(Json.Builder b) {
                b.begin_array();
                foreach (IJsonBuilderElement el in lst)
                {
                    el.execute(b);
                }
                b.end_array();
            }
        }

        /* Internal Helper functions to read JSON element */

        internal interface IJsonReaderElement : Object {
            public abstract void execute(Json.Reader r) throws HelperDeserializeError;
        }

        internal class JsonReaderVoid : Object, IJsonReaderElement
        {
            public bool ret_ok;
            public JsonReaderVoid() {
                ret_ok = false;
            }
            public void execute(Json.Reader r) throws HelperDeserializeError {
                if (!r.get_null_value())
                    throw new HelperDeserializeError.GENERIC("element must be void");
                ret_ok = true;
            }
        }

        internal class JsonReaderInt64 : Object, IJsonReaderElement
        {
            public bool ret_ok;
            public bool nullable;
            public int64? ret;
            public JsonReaderInt64(bool nullable) {
                ret_ok = false;
                this.nullable = nullable;
            }
            public void execute(Json.Reader r) throws HelperDeserializeError {
                if (r.get_null_value())
                {
                    if (!nullable)
                        throw new HelperDeserializeError.GENERIC("element is not nullable");
                    ret = null;
                    ret_ok = true;
                    return;
                }
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC("element must be a int");
                if (r.get_value().get_value_type() != typeof(int64))
                    throw new HelperDeserializeError.GENERIC("element must be a int");
                ret = r.get_int_value();
                ret_ok = true;
            }
        }

        internal class JsonReaderDouble : Object, IJsonReaderElement
        {
            public bool ret_ok;
            public bool nullable;
            public double? ret;
            public JsonReaderDouble(bool nullable) {
                ret_ok = false;
                this.nullable = nullable;
            }
            public void execute(Json.Reader r) throws HelperDeserializeError {
                if (r.get_null_value())
                {
                    if (!nullable)
                        throw new HelperDeserializeError.GENERIC("element is not nullable");
                    ret = null;
                    ret_ok = true;
                    return;
                }
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC("element must be a double");
                if (r.get_value().get_value_type() != typeof(double))
                    throw new HelperDeserializeError.GENERIC("element must be a double");
                ret = r.get_double_value();
                ret_ok = true;
            }
        }

        internal class JsonReaderBool : Object, IJsonReaderElement
        {
            public bool ret_ok;
            public bool nullable;
            public bool? ret;
            public JsonReaderBool(bool nullable) {
                ret_ok = false;
                this.nullable = nullable;
            }
            public void execute(Json.Reader r) throws HelperDeserializeError {
                if (r.get_null_value())
                {
                    if (!nullable)
                        throw new HelperDeserializeError.GENERIC("element is not nullable");
                    ret = null;
                    ret_ok = true;
                    return;
                }
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC("element must be a boolean");
                if (r.get_value().get_value_type() != typeof(bool))
                    throw new HelperDeserializeError.GENERIC("element must be a boolean");
                ret = r.get_boolean_value();
                ret_ok = true;
            }
        }

        internal class JsonReaderString : Object, IJsonReaderElement
        {
            public bool ret_ok;
            public bool nullable;
            public string? ret;
            public JsonReaderString(bool nullable) {
                ret_ok = false;
                this.nullable = nullable;
            }
            public void execute(Json.Reader r) throws HelperDeserializeError {
                if (r.get_null_value())
                {
                    if (!nullable)
                        throw new HelperDeserializeError.GENERIC("element is not nullable");
                    ret = null;
                    ret_ok = true;
                    return;
                }
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC("element must be a string");
                if (r.get_value().get_value_type() != typeof(string))
                    throw new HelperDeserializeError.GENERIC("element must be a string");
                ret = r.get_string_value();
                ret_ok = true;
            }
        }

        internal delegate unowned Json.Node JsonExecPath(Json.Node root);
        internal class JsonReaderObject : Object, IJsonReaderElement
        {
            public bool ret_ok;
            public Type expected_type;
            public bool nullable;
            private bool is_null;
            private Type type;
            public JsonReaderObject(Type expected_type, bool nullable) {
                ret_ok = false;
                this.expected_type = expected_type;
                this.nullable = nullable;
            }
            public void execute(Json.Reader r) throws HelperDeserializeError {
                if (r.get_null_value())
                {
                    if (!nullable)
                        throw new HelperDeserializeError.GENERIC("element is not nullable");
                    is_null = true;
                    ret_ok = true;
                    return;
                }
                if (!r.is_object())
                    throw new HelperDeserializeError.GENERIC("element must be an object");
                string typename;
                if (!r.read_member("typename"))
                    throw new HelperDeserializeError.GENERIC("element must have typename");
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC("typename must be a string");
                if (r.get_value().get_value_type() != typeof(string))
                    throw new HelperDeserializeError.GENERIC("typename must be a string");
                typename = r.get_string_value();
                r.end_member();
                type = Type.from_name(typename);
                if (type == 0)
                    throw new HelperDeserializeError.GENERIC(@"typename '$(typename)' unknown class");
                if (!type.is_a(expected_type))
                    throw new HelperDeserializeError.GENERIC(@"typename '$(typename)' is not a '$(expected_type.name())'");
                if (!r.read_member("value"))
                    throw new HelperDeserializeError.GENERIC("element must have value");
                r.end_member();
                is_null = false;
                ret_ok = true;
            }
            public Object? deserialize_or_null(string js, JsonExecPath exec_path) throws HelperDeserializeError
            {
                assert(ret_ok);
                if (is_null) return null;
                // find node, copy tree, deserialize
                Json.Parser p = new Json.Parser();
                try {
                    p.load_from_data(js);
                } catch (Error e) {
                    error(@"Parser error: This string should have been already parsed: $(e.message) - '$(js)'");
                }
                unowned Json.Node p_root = p.get_root();
                unowned Json.Node p_value = exec_path(p_root).get_object().get_member("value");
                Json.Node cp_value = p_value.copy();
                return Json.gobject_deserialize(type, cp_value);
            }
        }

        internal delegate void JsonReadElement(Json.Reader r, int index) throws HelperDeserializeError;
        internal class JsonReaderArray<T> : Object, IJsonReaderElement
        {
            public bool ret_ok;
            public Gee.List<T> ret;
            private unowned JsonReadElement cb;
            public JsonReaderArray() {
                ret_ok = false;
                ret = new ArrayList<T>();
            }
            public void init(JsonReadElement cb) {
                this.cb = cb;
            }
            public void execute(Json.Reader r) throws HelperDeserializeError {
                if (r.get_null_value())
                    throw new HelperDeserializeError.GENERIC("element is not nullable");
                if (!r.is_array())
                    throw new HelperDeserializeError.GENERIC("element must be an array");
                int l = r.count_elements();
                for (int j = 0; j < l; j++)
                {
                    r.read_element(j);
                    cb(r, j);
                    r.end_element();
                }
                ret_ok = true;
            }
        }

        /* Helper functions to build JSON arguments */

        internal string prepare_argument(IJsonBuilderElement cb)
        {
            var b = new Json.Builder();
            b.begin_object();
            b.set_member_name("argument");
            cb.execute(b);
            b.end_object();
            var g = new Json.Generator();
            g.pretty = false;
            g.root = b.get_root();
            return g.to_data(null);
        }

        public string prepare_argument_null()
        {
            return prepare_argument(new JsonBuilderNull());
        }

        public string prepare_argument_int64(int64 i)
        {
            return prepare_argument(new JsonBuilderInt64(i));
        }

        public string prepare_argument_double(double d)
        {
            return prepare_argument(new JsonBuilderDouble(d));
        }

        public string prepare_argument_boolean(bool b0)
        {
            return prepare_argument(new JsonBuilderBool(b0));
        }

        public string prepare_argument_string(string s)
        {
            return prepare_argument(new JsonBuilderString(s));
        }

        public string prepare_argument_binary(uint8[] buf)
        {
            return prepare_argument(new JsonBuilderBinary(buf));
        }

        public string prepare_argument_object(Object obj)
        {
            return prepare_argument(new JsonBuilderObject(obj));
        }

        public string prepare_argument_array_of_object(Gee.List<Object> lst)
        {
            ArrayList<IJsonBuilderElement> lst_b = new ArrayList<IJsonBuilderElement>();
            foreach (Object obj in lst) lst_b.add(new JsonBuilderObject(obj));
            JsonBuilderArray b = new JsonBuilderArray(lst_b);
            return prepare_argument(b);
        }

        public string prepare_argument_array_of_int64(Gee.List<int64?> lst)
        {
            ArrayList<IJsonBuilderElement> lst_b = new ArrayList<IJsonBuilderElement>();
            foreach (int64? val in lst)
            {
                if (val == null) error("MOD-RPC: null not allowed in array");
                lst_b.add(new JsonBuilderInt64(val));
            }
            JsonBuilderArray b = new JsonBuilderArray(lst_b);
            return prepare_argument(b);
        }

        public string prepare_argument_array_of_string(Gee.List<string> lst)
        {
            ArrayList<IJsonBuilderElement> lst_b = new ArrayList<IJsonBuilderElement>();
            foreach (string val in lst) lst_b.add(new JsonBuilderString(val));
            JsonBuilderArray b = new JsonBuilderArray(lst_b);
            return prepare_argument(b);
        }

        /* Helper functions to read JSON arguments */

        internal void read_argument(string js, IJsonReaderElement cb) throws HelperDeserializeError, HelperNotJsonError
        {
            Json.Parser p = new Json.Parser();
            try {
                p.load_from_data(js);
            } catch (Error e) {
                throw new HelperNotJsonError.GENERIC(e.message);
            }
            Json.Reader r = new Json.Reader(p.get_root());
            if (!r.is_object())
                throw new HelperDeserializeError.GENERIC(@"root JSON node must be an object");
            if (!r.read_member("argument"))
                throw new HelperDeserializeError.GENERIC(@"root JSON node must have argument");
            cb.execute(r);
            r.end_member();
        }

        public int64? read_argument_int64_maybe(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_int64(js, true);
        }

        public int64 read_argument_int64_notnull(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_int64(js, false);
        }

        internal int64? read_argument_int64(string js, bool nullable) throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderInt64 cb = new JsonReaderInt64(nullable);
            read_argument(js, cb);
            assert(cb.ret_ok);
            return cb.ret;
        }

        public double? read_argument_double_maybe(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_double(js, true);
        }

        public double read_argument_double_notnull(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_double(js, false);
        }

        internal double? read_argument_double(string js, bool nullable) throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderDouble cb = new JsonReaderDouble(nullable);
            read_argument(js, cb);
            assert(cb.ret_ok);
            return cb.ret;
        }

        public bool? read_argument_bool_maybe(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_bool(js, true);
        }

        public bool read_argument_bool_notnull(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_bool(js, false);
        }

        internal bool? read_argument_bool(string js, bool nullable) throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderBool cb = new JsonReaderBool(nullable);
            read_argument(js, cb);
            assert(cb.ret_ok);
            return cb.ret;
        }

        public string? read_argument_string_maybe(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_string(js, true);
        }

        public string read_argument_string_notnull(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_string(js, false);
        }

        public uint8[]? read_argument_binary_maybe(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            string? s = read_argument_string(js, true);
            if (s == null) return null;
            uint8[] buf = (uint8[])Base64.decode(s);
            return buf;
        }

        public uint8[] read_argument_binary_notnull(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            string s = read_argument_string(js, false);
            uint8[] buf = (uint8[])Base64.decode(s);
            return buf;
        }

        internal string? read_argument_string(string js, bool nullable) throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderString cb = new JsonReaderString(nullable);
            read_argument(js, cb);
            assert(cb.ret_ok);
            return cb.ret;
        }

        public Object? read_argument_object_maybe(Type expected_type, string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_object(expected_type, js, true);
        }

        public Object read_argument_object_notnull(Type expected_type, string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_object(expected_type, js, false);
        }

        internal Object? read_argument_object
         (Type expected_type, string js, bool nullable)
         throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderObject cb = new JsonReaderObject(expected_type, nullable);
            read_argument(js, cb);
            assert(cb.ret_ok);
            return cb.deserialize_or_null(js, (root) => {
                return root.get_object().get_member("argument");
            });
        }

        public Gee.List<Object> read_argument_array_of_object
            (Type expected_type, string js)
            throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderArray<Object> cb = new JsonReaderArray<Object>();
            cb.init((r, j) => {
                JsonReaderObject cb2 = new JsonReaderObject(expected_type, false);
                cb2.execute(r);
                Object el = cb2.deserialize_or_null(js, (root) => {
                    return root.get_object().get_member("argument")
                                .get_array().get_element(j);
                });
                cb.ret.add(el);
            });
            read_argument(js, cb);
            assert(cb.ret_ok);
            return cb.ret;
        }

        public Gee.List<int64?> read_argument_array_of_int64(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderArray<int64?> cb = new JsonReaderArray<int64?>();
            cb.init((r, j) => {
                JsonReaderInt64 cb2 = new JsonReaderInt64(false);
                cb2.execute(r);
                cb.ret.add(cb2.ret);
            });
            read_argument(js, cb);
            assert(cb.ret_ok);
            return cb.ret;
        }

        public Gee.List<string> read_argument_array_of_string(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderArray<string> cb = new JsonReaderArray<string>();
            cb.init((r, j) => {
                JsonReaderString cb2 = new JsonReaderString(false);
                cb2.execute(r);
                cb.ret.add(cb2.ret);
            });
            read_argument(js, cb);
            assert(cb.ret_ok);
            return cb.ret;
        }

        /* Helper functions to return JSON responses */

        internal string prepare_return_value(IJsonBuilderElement cb)
        {
            var b = new Json.Builder();
            b.begin_object();
            b.set_member_name("return-value");
            cb.execute(b);
            b.end_object();
            var g = new Json.Generator();
            g.pretty = false;
            g.root = b.get_root();
            return g.to_data(null);
        }

        public string prepare_return_value_null()
        {
            return prepare_return_value(new JsonBuilderNull());
        }

        public string prepare_return_value_int64(int64 i)
        {
            return prepare_return_value(new JsonBuilderInt64(i));
        }

        public string prepare_return_value_double(double d)
        {
            return prepare_return_value(new JsonBuilderDouble(d));
        }

        public string prepare_return_value_boolean(bool b0)
        {
            return prepare_return_value(new JsonBuilderBool(b0));
        }

        public string prepare_return_value_string(string s)
        {
            return prepare_return_value(new JsonBuilderString(s));
        }

        public string prepare_return_value_binary(uint8[] buf)
        {
            return prepare_return_value(new JsonBuilderBinary(buf));
        }

        public string prepare_return_value_object(Object obj)
        {
            return prepare_return_value(new JsonBuilderObject(obj));
        }

        public string prepare_return_value_array_of_object(Gee.List<Object> lst)
        {
            ArrayList<IJsonBuilderElement> lst_b = new ArrayList<IJsonBuilderElement>();
            foreach (Object obj in lst) lst_b.add(new JsonBuilderObject(obj));
            JsonBuilderArray b = new JsonBuilderArray(lst_b);
            return prepare_return_value(b);
        }

        public string prepare_return_value_array_of_int64(Gee.List<int64?> lst)
        {
            ArrayList<IJsonBuilderElement> lst_b = new ArrayList<IJsonBuilderElement>();
            foreach (int64? val in lst)
            {
                if (val == null) error("MOD-RPC: null not allowed in array");
                lst_b.add(new JsonBuilderInt64(val));
            }
            JsonBuilderArray b = new JsonBuilderArray(lst_b);
            return prepare_return_value(b);
        }

        public string prepare_return_value_array_of_string(Gee.List<string> lst)
        {
            ArrayList<IJsonBuilderElement> lst_b = new ArrayList<IJsonBuilderElement>();
            foreach (string val in lst) lst_b.add(new JsonBuilderString(val));
            JsonBuilderArray b = new JsonBuilderArray(lst_b);
            return prepare_return_value(b);
        }

        public string prepare_error(string domain, string code, string message)
        {
            var b = new Json.Builder();
            b.begin_object()
                .set_member_name("error-domain").add_string_value(domain)
                .set_member_name("error-code").add_string_value(code)
                .set_member_name("error-message").add_string_value(message)
            .end_object();
            var g = new Json.Generator();
            g.pretty = false;
            g.root = b.get_root();
            return g.to_data(null);
        }

        /* Helper functions to read JSON responses */

        internal void read_return_value
         (string js, IJsonReaderElement cb, out string? error_domain, out string? error_code, out string? error_message)
         throws HelperDeserializeError, HelperNotJsonError
        {
            Json.Parser p = new Json.Parser();
            try {
                p.load_from_data(js);
            } catch (Error e) {
                throw new HelperNotJsonError.GENERIC(e.message);
            }
            Json.Reader r = new Json.Reader(p.get_root());
            if (!r.is_object())
                throw new HelperDeserializeError.GENERIC(@"root JSON node must be an object");
            string[] members = r.list_members();
            if ("return-value" in members)
            {
                error_domain = null;
                error_code = null;
                error_message = null;
                r.read_member("return-value");
                cb.execute(r);
                r.end_member();
            }
            else if (("error-domain" in members) && ("error-code" in members) && ("error-message" in members))
            {
                r.read_member("error-domain");
                if (r.get_null_value())
                    throw new HelperDeserializeError.GENERIC(@"error-domain is not nullable");
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC(@"error-domain must be a string");
                if (r.get_value().get_value_type() != typeof(string))
                    throw new HelperDeserializeError.GENERIC(@"error-domain must be a string");
                error_domain = r.get_string_value();
                r.end_member();
                r.read_member("error-code");
                if (r.get_null_value())
                    throw new HelperDeserializeError.GENERIC(@"error-code is not nullable");
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC(@"error-code must be a string");
                if (r.get_value().get_value_type() != typeof(string))
                    throw new HelperDeserializeError.GENERIC(@"error-code must be a string");
                error_code = r.get_string_value();
                r.end_member();
                r.read_member("error-message");
                if (r.get_null_value())
                    throw new HelperDeserializeError.GENERIC(@"error-message is not nullable");
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC(@"error-message must be a string");
                if (r.get_value().get_value_type() != typeof(string))
                    throw new HelperDeserializeError.GENERIC(@"error-message must be a string");
                error_message = r.get_string_value();
                r.end_member();
            }
            else
            {
                throw new HelperDeserializeError.GENERIC(@"root JSON node must have return-value or error-*");
            }
        }

        public void read_return_value_void
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderVoid cb = new JsonReaderVoid();
            read_return_value(js, cb, out error_domain, out error_code, out error_message);
            if (error_domain == null) assert(cb.ret_ok);
            return;
        }

        public int64? read_return_value_int64_maybe
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            return read_return_value_int64(js, true, out error_domain, out error_code, out error_message);
        }

        public int64 read_return_value_int64_notnull
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            return read_return_value_int64(js, false, out error_domain, out error_code, out error_message);
        }

        internal int64? read_return_value_int64
            (string js, bool nullable, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderInt64 cb = new JsonReaderInt64(nullable);
            read_return_value(js, cb, out error_domain, out error_code, out error_message);
            if (error_domain == null) assert(cb.ret_ok);
            return cb.ret;
        }

        public double? read_return_value_double_maybe
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            return read_return_value_double(js, true, out error_domain, out error_code, out error_message);
        }

        public double read_return_value_double_notnull
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            return read_return_value_double(js, false, out error_domain, out error_code, out error_message);
        }

        internal double? read_return_value_double
            (string js, bool nullable, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderDouble cb = new JsonReaderDouble(nullable);
            read_return_value(js, cb, out error_domain, out error_code, out error_message);
            if (error_domain == null) assert(cb.ret_ok);
            return cb.ret;
        }

        public bool? read_return_value_bool_maybe
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            return read_return_value_bool(js, true, out error_domain, out error_code, out error_message);
        }

        public bool read_return_value_bool_notnull
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            return read_return_value_bool(js, false, out error_domain, out error_code, out error_message);
        }

        internal bool? read_return_value_bool
            (string js, bool nullable, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderBool cb = new JsonReaderBool(nullable);
            read_return_value(js, cb, out error_domain, out error_code, out error_message);
            if (error_domain == null) assert(cb.ret_ok);
            return cb.ret;
        }

        public string? read_return_value_string_maybe
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            return read_return_value_string(js, true, out error_domain, out error_code, out error_message);
        }

        public string read_return_value_string_notnull
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            return read_return_value_string(js, false, out error_domain, out error_code, out error_message);
        }

        public uint8[]? read_return_value_binary_maybe
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            string? s = read_return_value_string(js, true, out error_domain, out error_code, out error_message);
            if (s == null) return null;
            uint8[] buf = (uint8[])Base64.decode(s);
            return buf;
        }

        public uint8[] read_return_value_binary_notnull
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            string s = read_return_value_string(js, false, out error_domain, out error_code, out error_message);
            uint8[] buf = (uint8[])Base64.decode(s);
            return buf;
        }

        internal string? read_return_value_string
            (string js, bool nullable, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderString cb = new JsonReaderString(nullable);
            read_return_value(js, cb, out error_domain, out error_code, out error_message);
            if (error_domain == null) assert(cb.ret_ok);
            return cb.ret;
        }

        public Object? read_return_value_object_maybe
            (Type expected_type, string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            return read_return_value_object(expected_type, js, true, out error_domain, out error_code, out error_message);
        }

        public Object read_return_value_object_notnull
            (Type expected_type, string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            return read_return_value_object(expected_type, js, false, out error_domain, out error_code, out error_message);
        }

        internal Object? read_return_value_object
            (Type expected_type, string js, bool nullable, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderObject cb = new JsonReaderObject(expected_type, nullable);
            read_return_value(js, cb, out error_domain, out error_code, out error_message);
            if (error_domain == null)
            {
                assert(cb.ret_ok);
                return cb.deserialize_or_null(js, (root) => {
                    return root.get_object().get_member("return-value");
                });
            }
            return null;
        }

        public Gee.List<Object> read_return_value_array_of_object
            (Type expected_type, string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderArray<Object> cb = new JsonReaderArray<Object>();
            cb.init((r, j) => {
                JsonReaderObject cb2 = new JsonReaderObject(expected_type, false);
                cb2.execute(r);
                Object el = cb2.deserialize_or_null(js, (root) => {
                    return root.get_object().get_member("return-value")
                                .get_array().get_element(j);
                });
                cb.ret.add(el);
            });
            read_return_value(js, cb, out error_domain, out error_code, out error_message);
            if (error_domain == null)
            {
                assert(cb.ret_ok);
                return cb.ret;
            }
            return cb.ret;
        }

        public Gee.List<int64?> read_return_value_array_of_int64
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderArray<int64?> cb = new JsonReaderArray<int64?>();
            cb.init((r, j) => {
                JsonReaderInt64 cb2 = new JsonReaderInt64(false);
                cb2.execute(r);
                cb.ret.add(cb2.ret);
            });
            read_return_value(js, cb, out error_domain, out error_code, out error_message);
            if (error_domain == null)
            {
                assert(cb.ret_ok);
                return cb.ret;
            }
            return cb.ret;
        }

        public Gee.List<string> read_return_value_array_of_string
            (string js, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderArray<string> cb = new JsonReaderArray<string>();
            cb.init((r, j) => {
                JsonReaderString cb2 = new JsonReaderString(false);
                cb2.execute(r);
                cb.ret.add(cb2.ret);
            });
            read_return_value(js, cb, out error_domain, out error_code, out error_message);
            if (error_domain == null)
            {
                assert(cb.ret_ok);
                return cb.ret;
            }
            return cb.ret;
        }

        /* Helper functions to build JSON unicastid and broadcastid */

        public string prepare_direct_object(Object obj)
        {
            IJsonBuilderElement cb = new JsonBuilderObject(obj);
            var b = new Json.Builder();
            cb.execute(b);
            var g = new Json.Generator();
            g.pretty = false;
            g.root = b.get_root();
            return g.to_data(null);
        }

        /* Helper functions to read JSON unicastid and broadcastid */

        internal void read_direct(string js, IJsonReaderElement cb) throws HelperDeserializeError, HelperNotJsonError
        {
            Json.Parser p = new Json.Parser();
            try {
                p.load_from_data(js);
            } catch (Error e) {
                throw new HelperNotJsonError.GENERIC(e.message);
            }
            Json.Reader r = new Json.Reader(p.get_root());
            cb.execute(r);
        }

        public Object read_direct_object_notnull(Type expected_type, string js) throws HelperDeserializeError, HelperNotJsonError
        {
            JsonReaderObject cb = new JsonReaderObject(expected_type, false);
            read_direct(js, cb);
            assert(cb.ret_ok);
            return cb.deserialize_or_null(js, (root) => {
                return root;
            });
        }
    }
}
    """);
    write_file("common_helpers.vala", contents);
}

