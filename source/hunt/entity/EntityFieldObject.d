

module hunt.entity.EntityFieldObject;

import hunt.entity;

class EntityFieldObject(T : Object, F : Object) : EntityFieldInfo {

    protected T _value;
    private F _owner;
    protected EntityInfo!(T,F) _entityInfo;
    protected EntityManager _manager;

    this (EntityManager manager,string fieldName, string columnName, string tableName, T fieldValue, F owner) {
        super(fieldName, columnName, tableName);
        _manager = manager;
        _value = fieldValue;
        _owner = owner;
        _entityInfo = new EntityInfo!(T,F)(_manager, fieldValue, owner);
        _typeInfo = typeid(T);
    }   
}