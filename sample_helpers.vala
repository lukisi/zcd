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
        /* Helper functions to return JSON responses */

        public delegate
         void PrepareJsonNode(Json.Builder b);

        public string prepare_return_value(PrepareJsonNode cb)
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
    }
}

