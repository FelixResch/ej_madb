require "./version"
require "./db"

require "kemal"
require "json"

db = EjMadb::DATABASE

date_format = Time::Format.new("%Y-%m-%d")

class UserData
    #DB.mapping ({
    #             member_id: {type: Int32, key: "m_id"},
    #             firstname: {type: String, key: "m_firstname"},
    #             lastname: {type: String, key: "m_lastname"},
    #             birthdate: {type: Time, key: "m_birthdate"},
    #             tel: String,
    #             email: String
    #})
    JSON.mapping({
        member_id: Int32,
        firstname: String,
        lastname: String,
        birthdate: Time,
        tel: Array(String),
        email: Array(String)
    })
    
    def initialize (@member_id : Int32, @firstname : String, @lastname : String, @birthdate : Time, @tel : Array(String), @email : Array(String)); end
end

get "/api/v1/test" do |env|
    env.response.content_type = "application/json"
    {"api": {"version": EjMadb::VERSION}, "success": true}.to_json()
end

get "/api/v1/member" do |env|
    db.query "SELECT m_id, m_firstname, m_lastname, DATE_FORMAT(m_birthdate, '%Y-%m-%d'), tel, email FROM user_data" do |rs|
        user_data = Array(UserData).new
        rs.each do
            member_id = rs.read(Int32)
            firstname = rs.read(String)
            lastname = rs.read(String)
            birthdate = date_format.parse(rs.read(String), kind = Time::Kind::Unspecified)
            tel = rs.read(String).split(",")
            email = rs.read(String).split(",")
            member = UserData.new(member_id, firstname, lastname, birthdate, tel, email)
            user_data << member
        end
        user_data.to_json
    end
end

get "/api/v1/member/:member_id" do |env|
    env.response.content_type = "application/json"
    db.query "SELECT m_id, m_firstname, m_lastname, DATE_FORMAT(m_birthdate, '%Y-%m-%d'), tel, email FROM user_data WHERE m_id = ?", env.params.url["member_id"] do |rs|
        if rs.move_next()
            member_id = rs.read(Int32)
            firstname = rs.read(String)
            lastname = rs.read(String)
            birthdate = date_format.parse(rs.read(String), kind = Time::Kind::Unspecified)
            tel = rs.read(String).split(",")
            email = rs.read(String).split(",")
            {api: {version: EjMadb::VERSION}, success: true, member: UserData.new(member_id, firstname, lastname, birthdate, tel, email)}.to_json
        else
            env.response.status_code = 404
            {api: {version: EjMadb::VERSION}, success: false, errror: "No member found"}.to_json
        end
    end
end
