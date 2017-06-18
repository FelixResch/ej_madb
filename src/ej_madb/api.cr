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
        email: Array(String),
        base_group_url: String
    })
    
    def initialize (@member_id : Int32, @firstname : String, @lastname : String, @birthdate : Time, @tel : Array(String), @email : Array(String), @base_group_url : String); end
end

class MemberData < UserData
    JSON.mapping({
        member_id: Int32,
        firstname: String,
        lastname: String,
        birthdate: Time,
        tel: Array(String),
        email: Array(String),
        base_group_url: String,
        is_staff: Bool
    })
    
    def initialize (@member_id : Int32, @firstname : String, @lastname : String, @birthdate : Time, @tel : Array(String), @email : Array(String), @base_group_url : String, @is_staff : Bool); end
    
end

class GroupData
    JSON.mapping({
        group_id: Int32,
        name: String,
        parent: ( String | Nil ),
        members: String
    })
   
    def initialize (@group_id : Int32, @name : String, @parent : ( Nil | String ), @members : String); end
end

get "/api/v1/test" do |env|
    env.response.content_type = "application/json"
    {"api": {"version": EjMadb::VERSION}, "success": true}.to_json()
end

get "/api/v1/members" do |env|
    db.query "SELECT m_id, m_firstname, m_lastname, DATE_FORMAT(m_birthdate, '%Y-%m-%d'), tel, email, m_base_group FROM user_data" do |rs|
        user_data = Array(UserData).new
        rs.each do
            member_id = rs.read(Int32)
            firstname = rs.read(String)
            lastname = rs.read(String)
            birthdate = date_format.parse(rs.read(String), kind = Time::Kind::Unspecified)
            tel = rs.read(String).split(",")
            email = rs.read(String).split(",")
            base_group_url = "/api/v1/groups/#{rs.read(Int32)}"
            member = UserData.new(member_id, firstname, lastname, birthdate, tel, email, base_group_url)
            user_data << member
        end
        {api: {version: EjMadb::VERSION}, success: true, members: user_data}.to_json
    end
end

get "/api/v1/members/:member_id" do |env|
    env.response.content_type = "application/json"
    db.query "SELECT m_id, m_firstname, m_lastname, DATE_FORMAT(m_birthdate, '%Y-%m-%d'), tel, email, m_base_group FROM user_data WHERE m_id = ?", env.params.url["member_id"] do |rs|
        if rs.move_next()
            member_id = rs.read(Int32)
            firstname = rs.read(String)
            lastname = rs.read(String)
            birthdate = date_format.parse(rs.read(String), kind = Time::Kind::Unspecified)
            tel = rs.read(String).split(",")
            email = rs.read(String).split(",")
            base_group_url = "/api/v1/groups/#{rs.read(Int32)}"
            {api: {version: EjMadb::VERSION}, success: true, member: UserData.new(member_id, firstname, lastname, birthdate, tel, email, base_group_url)}.to_json
        else
            env.response.status_code = 404
            {api: {version: EjMadb::VERSION}, success: false, errror: "No member found"}.to_json
        end
    end
end

get "/api/v1/groups/:group_id/" do |env|
    env.response.content_type = "application/json"
    db.query "SELECT g_id, g_name, g_parent_id FROM g_group WHERE g_id = ?", env.params.url["group_id"] do |rs|
        if rs.move_next()
            group_id = rs.read(Int32)
            name = rs.read(String)
            parent_id = rs.read(Int32|Nil)
            if(parent_id)
               parent_url = "/api/v1/groups/#{parent_id}"
            else
                parent_url = nil
            end
            members_url = "/api/v1/groups/#{group_id}/members"
            {api: {version: EjMadb::VERSION}, success: true, group: GroupData.new(group_id, name, parent_url, members_url)}.to_json
        else
            env.response.status_code = 404
            {api: {version: EjMadb::VERSION}, success: false, error: "No group #{env.params.url["group_id"]} found"}.to_json
        end
    end
end

get "/api/v1/groups/:group_id/members" do |env|
    env.response.content_type = "application/json"
    members = Array(MemberData).new
    db.query "SELECT  m_id, m_firstname, m_lastname, DATE_FORMAT(m_birthdate, '%Y-%m-%d'), tel, email, m_base_group, gm_staff FROM user_data INNER JOIN gm_group_members ON m_id = gm_member WHERE gm_group = ?", env.params.url["group_id"] do |rs|
        rs.each do
            member_id = rs.read(Int32)
            firstname = rs.read(String)
            lastname = rs.read(String)
            birthdate = date_format.parse(rs.read(String), kind = Time::Kind::Unspecified)
            tels = rs.read(String|Nil)
            if tels 
                tel = tels.split(",")
            else
                tel = Array(String).new
            end
            emails = rs.read(String|Nil)
            if emails
                email = emails.split(",")
            else
                email = Array(String).new
            end
            base_group_url = "/api/v1/groups/#{rs.read(Int32)}"
            is_staff = rs.read(Bool)
            member = MemberData.new(member_id, firstname, lastname, birthdate, tel, email, base_group_url, is_staff)
            members << member
        end
    end
    {api: {version: EjMadb::VERSION}, success: true, members: members}.to_json
end
