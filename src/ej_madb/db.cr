require "mysql"

module EjMadb
    DATABASE = DB.open "mysql://root@localhost:3306/ej_madb"
end
