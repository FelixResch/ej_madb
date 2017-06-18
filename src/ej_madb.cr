require "./ej_madb/*"

require "kemal"
require "json"
require "kemal-session"
require "kemal-watcher"
require "mysql"
require "openssl"

serve_static({"dir_listing" => true, "gzip" => true})

Session.config do |config|
  Session.config.secret = "my_super_secret12"
end

db = EjMadb::DATABASE

digest_sha512 = OpenSSL::Digest.new("SHA512")

class UserStorableObject
  JSON.mapping({
    id: Int32,
    firstname: String,
    lastname: String,
    group_name: String,
    base_group_id: Int32
  })
  include Session::StorableObject

  def initialize(@id : Int32, @firstname : String, @lastname : String, @group_name : String, @base_group_id : Int32); end
end

class MemberLogin
    DB.mapping({
                member: { type: Int32, key: "ml_member" },
                username: { type: String, key: "ml_username" },
                password: {type: String, "key": "ml_password" },
                digest_hash: { type: String, "key": "ml_digest_hash" },
                firstname: { type: String, key: "m_firstname" },
                lastname: { type: String, key: "m_lastname" },
                base_group: { type: Int32, key: "m_base_group" },
                group_name: { type: String, key: "g_name" }
            })
    
    def initialize(@member : Int32, @username : String, @password : Bytes, @digest_hash : Bytes, @firstname : String, @lastname : String, @base_group : UInt32, @group_name : String); end
end

def cmpPwds(hashed_pwd : Bytes, member_pw : Array(UInt8))
   if hashed_pwd.size != member_pw.size
       false
   else
       i = 0
       while i < hashed_pwd.size
           if hashed_pwd[i] != member_pw[i]
               return false
           end
           i += 1
       end
       true
   end
end

get "/" do |env|
    user = env.session.object?("user")
    if user
        user = user.as(UserStorableObject)
       render "src/views/index.ecr"
    else
        env.redirect "/login"
    end
end

get "/login" do |env|
   render "src/views/login.ecr" 
end

post "/login" do |env|
    body = env.params.body
    
    username = body["username"]
    password = body["password"]
    
    db.query "SELECT ml_member, ml_username, ml_password, ml_digest_hash, m_firstname, m_lastname, m_base_group, g_name FROM ml_member_login INNER JOIN m_member ON ml_member_login.ml_member = m_member.m_id INNER JOIN g_group ON m_base_group = g_id WHERE ml_username = ?", username do |rs|
        rs.each do
            member = rs.read(MemberLogin)
            puts "Attempting login with #{member.username}"
            digest_sha512.reset
            digest_sha512.update password
            hashed_pwd = digest_sha512.digest
            if cmpPwds(hashed_pwd, member.password.bytes)
                env.session.object("user", UserStorableObject.new(member.member, member.firstname, member.lastname, member.group_name, member.base_group))
            end
        end
    end
    
    if env.session.object?("user")
        env.redirect "/"
    else
        env.redirect "/login"
    end
end

get "/logout" do |env|
    env.session.destroy
    env.redirect "/login"
end

files = [
    "public/css/*.css",
    "public/js/*.js"
    ]

Kemal.watch files
Kemal.run
