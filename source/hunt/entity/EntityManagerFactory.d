/*
 * Entity - Entity is an object-relational mapping tool for the D programming language. Referring to the design idea of JPA.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.entity.EntityManagerFactory;

import hunt.entity;
import hunt.entity.dialect;
import hunt.entity.EntityOption;
import hunt.logging;
import hunt.Exceptions;

class EntityManagerFactory {

    public Dialect _dialect;
    public EntityOption _option;
    public Database _db;
    public string _name;
    private CriteriaBuilder _criteriaBuilder;
    private string[] _exitTables;

    public this(string name, EntityOption option)
    {
        _name = name;
        _option = option;

        version(HUNT_ENTITY_DEBUG) {
            tracef("maxPoolSize: %d", _option.pool.maxPoolSize);
        }
        
        auto databaseOptions = new DatabaseOption(_option.database.url);
        databaseOptions.maximumPoolSize(_option.pool.maxPoolSize);
        databaseOptions.minimumPoolSize(_option.pool.minPoolSize);
        databaseOptions.setConnectionTimeout(_option.pool.connectionTimeout);
        databaseOptions.setEncoderBufferSize(512);  // The sql string may be very long.

        _db = new Database(databaseOptions);
        
        if(databaseOptions.isMysql()) {
            _dialect = new MySQLDialect();
        } else {
            _dialect = new PostgreSQLDialect();
        }

        _criteriaBuilder = new CriteriaBuilder(this);
        _exitTables = showTables();
        autoCreateTables();
    }

    ~this()
    {
        version(HUNT_DB_DEBUG) info("EntityManagerFactory destruct");
        if(_db)
            _db.close();
        _db = null;
    }   

    public EntityManager createEntityManager()
    {
        // if(_entityManagerInThread is null) {
        //     _entityManagerInThread = new EntityManager(this, _name, _option, _db, _dialect);
        // }
        // return _entityManagerInThread;
        return new EntityManager(this, _name, _option, _db, _dialect);
    }

    // private static EntityManager _entityManagerInThread;
    
    public QueryBuilder createQueryBuilder()
    {
        return _db.createQueryBuilder();
    }

    public void close()
    {
        if (_db)
            _db.close();

        _db = null;
    }

    private string[] showTables() {
        string[] ret;
        QueryBuilder builder = createQueryBuilder();
        Statement stmt = _db.prepare(builder.showTables().toString());
        RowSet rs = stmt.query();
        foreach(Row row; rs) {
            for(int i=0; i<row.size(); i++) {
                ret ~= row.getValue(i).toString();
            }
        }

        return ret;
    }

    private string[] descTable(string tableName)
    {
        string[] ret;
        QueryBuilder builder = createQueryBuilder();
        Statement stmt = _db.prepare(builder.descTable(tableName).toString());
        RowSet rs = stmt.query();
        foreach(Row row; rs) {
            // string[string] array = row.toStringArray();
            // ret ~= "Field" in array ? array["Field"] : array["field"];

            for(int i=0; i<row.size(); i++) {
                ret ~= row.getColumnName(i);
            }

            // FIXME: Needing refactor or cleanup -@zxp at 9/18/2019, 2:34:02 PM
            // 
            // just one row??
        }
        return ret;
    }

    public static void prepareEntity(T...)() {
        foreach(V; T) {
            addCreateTableHandle(getEntityTableName!V, &onCreateTableHandler!V);
        }
    }

    public void createTables(T...)() {
        prepareEntity!(T);
        autoCreateTables();
    }

    public void autoCreateTables()
    {
        GetCreateTableHandle[string] flushList;
        foreach(k,v; __createTableList) {
            string check = _option.database.prefix~k;
            if (!Common.inArray(_exitTables, _option.database.prefix~k)) {
                flushList[k] = v;
                trace("create new table ", _option.database.prefix~k);
            }
        }

        string[] alterRows;
        //step1:create base table
        foreach(v;flushList) {
            // FIXME: Needing refactor or cleanup -@zxp at 9/18/2019, 1:36:04 PM
            // 
            
            string createSql = v(_dialect, _option.database.prefix, alterRows);
            _db.execute(createSql);
        }
        
        //step2: alert table, eg add foreign key..
        foreach(v; alterRows) {
            trace(v);
            _db.execute(v);
        }
    }

    public Dialect getDialect() {return _dialect;}
    public Database getDatabase() {return _db;}
    public CriteriaBuilder getCriteriaBuilder() {return _criteriaBuilder;}
}



alias GetCreateTableHandle = string function(Dialect dialect, string tablePrefix, ref string[] alterRows);
string onCreateTableHandler(T)(Dialect dialect, string tablePrefix, ref string[] alertRows)
{
    return (new EntityCreateTable!T).createTable(dialect, tablePrefix, alertRows);
}
void addCreateTableHandle(string tableName, GetCreateTableHandle handler)
{
    if (tableName !in __createTableList)
        __createTableList[tableName] = handler;
}
GetCreateTableHandle getCreateTableHandle(string tableName)
{
    return __createTableList.get(tableName, null);
}
string getEntityTableName(T)() {
    static if (hasUDA!(T, Table)) {
        return getUDAs!(getSymbolsByUDA!(T,Table)[0], Table)[0].name;
    }
    else {
        return T.stringof;
    }
}
private:
__gshared GetCreateTableHandle[string] __createTableList;