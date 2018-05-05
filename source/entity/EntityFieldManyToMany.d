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
 
module entity.EntityFieldManyToMany;

import entity;

class EntityFieldManyToMany(T) : EntityFieldInfo
{
    
    private ManyToMany _mode;
    private T _value;
    this(string fileldName, string columnName, string joinColumn, string tableName, T fieldValue, ManyToMany mode)
    {
        super(fileldName, /*tableName~"."~columnName*/columnName, Variant(fieldValue), tableName);
        _mode = mode;
        _joinColumn = joinColumn;
        _value = fieldValue;
    }
}