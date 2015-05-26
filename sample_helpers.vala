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

using Gee;

namespace AppDomain
{
    namespace ModRpc
    {
        public errordomain HelperDeserializeError {
            GENERIC
        }

        public errordomain HelperNotJsonError {
            GENERIC
        }

        /* Helper functions to build JSON arguments */

        public string prepare_argument(BuildJsonNode cb)
        {
            var b = new Json.Builder();
            b.begin_object();
            b.set_member_name("argument");
            cb(b);
            b.end_object();
            var g = new Json.Generator();
            g.pretty = false;
            g.root = b.get_root();
            return g.to_data(null);
        }

        public string prepare_argument_null()
        {
            return prepare_argument((b) => {
                b.add_null_value();
            });
        }

        public string prepare_argument_int64(int64 i)
        {
            return prepare_argument((b) => {
                b.add_int_value(i);
            });
        }

        public string prepare_argument_double(double d)
        {
            return prepare_argument((b) => {
                b.add_double_value(d);
            });
        }

        public string prepare_argument_boolean(bool b0)
        {
            return prepare_argument((b) => {
                b.add_boolean_value(b0);
            });
        }

        public string prepare_argument_string(string s)
        {
            return prepare_argument((b) => {
                b.add_string_value(s);
            });
        }

        /* Helper functions to read JSON arguments */

        public delegate
         void ReadJsonNode(Json.Reader r) throws HelperDeserializeError;

        public void read_argument(string js, ReadJsonNode cb) throws HelperDeserializeError, HelperNotJsonError
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
            cb(r);
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
            int64? ret = null;
            bool ret_ok = false;
            read_argument(js, (r) => {
                if (r.get_null_value())
                {
                    if (!nullable)
                        throw new HelperDeserializeError.GENERIC(@"argument is not nullable");
                    ret = null;
                    ret_ok = true;
                    return;
                }
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC(@"argument must be a int");
                if (r.get_value().get_value_type() != typeof(int64))
                    throw new HelperDeserializeError.GENERIC(@"argument must be a int");
                ret = r.get_int_value();
                ret_ok = true;
            });
            assert(ret_ok);
            return ret;
        }

        public string? read_argument_string_maybe(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_string(js, true);
        }

        public string read_argument_string_notnull(string js) throws HelperDeserializeError, HelperNotJsonError
        {
            return read_argument_string(js, false);
        }

        internal string? read_argument_string(string js, bool nullable) throws HelperDeserializeError, HelperNotJsonError
        {
            string? ret = null;
            bool ret_ok = false;
            read_argument(js, (r) => {
                if (r.get_null_value())
                {
                    if (!nullable)
                        throw new HelperDeserializeError.GENERIC(@"argument is not nullable");
                    ret = null;
                    ret_ok = true;
                    return;
                }
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC(@"argument must be a string");
                if (r.get_value().get_value_type() != typeof(string))
                    throw new HelperDeserializeError.GENERIC(@"argument must be a string");
                ret = r.get_string_value();
                ret_ok = true;
            });
            assert(ret_ok);
            return ret;
        }

        /* Helper functions to return JSON responses */

        public delegate
         void BuildJsonNode(Json.Builder b);

        public string prepare_return_value(BuildJsonNode cb)
        {
            var b = new Json.Builder();
            b.begin_object();
            b.set_member_name("return-value");
            cb(b);
            b.end_object();
            var g = new Json.Generator();
            g.pretty = false;
            g.root = b.get_root();
            return g.to_data(null);
        }

        public string prepare_return_value_null()
        {
            return prepare_return_value((b) => {
                b.add_null_value();
            });
        }

        public string prepare_return_value_int64(int64 i)
        {
            return prepare_return_value((b) => {
                b.add_int_value(i);
            });
        }

        public string prepare_return_value_double(double d)
        {
            return prepare_return_value((b) => {
                b.add_double_value(d);
            });
        }

        public string prepare_return_value_boolean(bool b0)
        {
            return prepare_return_value((b) => {
                b.add_boolean_value(b0);
            });
        }

        public string prepare_return_value_string(string s)
        {
            return prepare_return_value((b) => {
                b.add_string_value(s);
            });
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

        public void read_return_value
         (string js, ReadJsonNode cb, out string? error_domain, out string? error_code, out string? error_message)
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
                cb(r);
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
            bool ret_ok = false;
            read_return_value(js, (r) => {
                if (!r.get_null_value())
                    throw new HelperDeserializeError.GENERIC(@"return-value must be void");
                ret_ok = true;
            }, out error_domain, out error_code, out error_message);
            if (error_domain == null) assert(ret_ok);
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
            int64? ret = 0;
            bool ret_ok = false;
            read_return_value(js, (r) => {
                if (r.get_null_value())
                {
                    if (!nullable)
                        throw new HelperDeserializeError.GENERIC(@"return-value is not nullable");
                    ret = null;
                    ret_ok = true;
                    return;
                }
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC(@"return-value must be a int");
                if (r.get_value().get_value_type() != typeof(int64))
                    throw new HelperDeserializeError.GENERIC(@"return-value must be a int");
                ret = r.get_int_value();
                ret_ok = true;
            }, out error_domain, out error_code, out error_message);
            if (error_domain == null) assert(ret_ok);
            return ret;
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
            double? ret = 0.0;
            bool ret_ok = false;
            read_return_value(js, (r) => {
                if (r.get_null_value())
                {
                    if (!nullable)
                        throw new HelperDeserializeError.GENERIC(@"return-value is not nullable");
                    ret = null;
                    ret_ok = true;
                    return;
                }
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC(@"return-value must be a double");
                if (r.get_value().get_value_type() != typeof(double))
                    throw new HelperDeserializeError.GENERIC(@"return-value must be a double");
                ret = r.get_double_value();
                ret_ok = true;
            }, out error_domain, out error_code, out error_message);
            if (error_domain == null) assert(ret_ok);
            return ret;
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
            bool? ret = false;
            bool ret_ok = false;
            read_return_value(js, (r) => {
                if (r.get_null_value())
                {
                    if (!nullable)
                        throw new HelperDeserializeError.GENERIC(@"return-value is not nullable");
                    ret = null;
                    ret_ok = true;
                    return;
                }
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC(@"return-value must be a boolean");
                if (r.get_value().get_value_type() != typeof(bool))
                    throw new HelperDeserializeError.GENERIC(@"return-value must be a boolean");
                ret = r.get_boolean_value();
                ret_ok = true;
            }, out error_domain, out error_code, out error_message);
            if (error_domain == null) assert(ret_ok);
            return ret;
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

        internal string? read_return_value_string
            (string js, bool nullable, out string? error_domain, out string? error_code, out string? error_message)
            throws HelperDeserializeError, HelperNotJsonError
        {
            string? ret = "";
            bool ret_ok = false;
            read_return_value(js, (r) => {
                if (r.get_null_value())
                {
                    if (!nullable)
                        throw new HelperDeserializeError.GENERIC(@"return-value is not nullable");
                    ret = null;
                    ret_ok = true;
                    return;
                }
                if (!r.is_value())
                    throw new HelperDeserializeError.GENERIC(@"return-value must be a string");
                if (r.get_value().get_value_type() != typeof(string))
                    throw new HelperDeserializeError.GENERIC(@"return-value must be a string");
                ret = r.get_string_value();
                ret_ok = true;
            }, out error_domain, out error_code, out error_message);
            if (error_domain == null) assert(ret_ok);
            return ret;
        }
    }
}

