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
 
module entity.repository.CrudRepository;

import entity.Persistence;
import entity.DefaultEntityManagerFactory;
import entity;
public import entity.repository.Repository;

class CrudRepository(T, ID) : Repository!(T, ID)
{
    protected EntityManager _manager;

    this() {
        _manager = defaultEntityManagerFactory().createEntityManager();
    }
    ~ this() {
        if (_manager !is null)
            _manager.close();
        _manager = null;
    }
    public void close() {
        if (_manager !is null)
            _manager.close();
        _manager = null;
    }

    public long count()
    {
        if (_manager is null)
            throw new EntityException("EntityManager has been close!!!");
        
        CriteriaBuilder builder = _manager.getCriteriaBuilder();
        auto criteriaQuery = builder.createQuery!T;
        Root!T root = criteriaQuery.from();
        criteriaQuery.select(builder.count(root));
        
        Long result = cast(Long)(_manager.createQuery(criteriaQuery).getSingleResult());
        
        return result.longValue();
    }

    public void remove(T entity)
    {
        if (_manager is null)
            throw new EntityException("EntityManager has been close!!!");
        _manager.remove!T(entity);
    }

    public void removeAll()
    {
        if (_manager is null)
            throw new EntityException("EntityManager has been close!!!");
        foreach (entity; findAll())
        {
            _manager.remove!T(entity);
        }
    }
    
    public void removeAll(T[] entities)
    {
        if (_manager is null)
            throw new EntityException("EntityManager has been close!!!");
        foreach (entity; entities)
        {
            _manager.remove!T(entity);
        }
    }

    public void removeById(ID id)
    {
        if (_manager is null)
            throw new EntityException("EntityManager has been close!!!");
        _manager.remove!T(id);
        
    }
    
    public bool existsById(ID id)
    {
        if (_manager is null)
            throw new EntityException("EntityManager has been close!!!");
        T entity = this.findById(id);
        return (entity !is null);
    }

    public T[] findAll()
    {
        if (_manager is null)
            throw new EntityException("EntityManager has been close!!!");
        CriteriaBuilder builder = _manager.getCriteriaBuilder();
        auto criteriaQuery = builder.createQuery!(T);
        Root!T root = criteriaQuery.from().autoJoin();
        TypedQuery!T typedQuery = _manager.createQuery(criteriaQuery.select(root));
        return typedQuery.getResultList();
    }

    public T[] findAllById(ID[] ids)
    {
        if (_manager is null)
            throw new EntityException("EntityManager has been close!!!");

        T[] entities;
        foreach (id; ids)
        {
            T entity = this.findById(id);
            if (entity !is null)
                entities ~= entity;
        }

        return entities;
    }

    public T findById(ID id)
    {
        if (_manager is null)
            throw new EntityException("EntityManager has been close!!!");
        T result = _manager.find!T(id);
        return result;
    }

    public T save(T entity)
    {
        if (_manager is null)
            throw new EntityException("EntityManager has been close!!!");
        if (mixin(GenerateFindById!T()) is null)
        {
            _manager.persist(entity);
        }
        else
        {
            _manager.merge!T(entity);
        }
        return entity;
    }

    public T[] saveAll(T[] entities)
    {
        if (_manager is null)
            throw new EntityException("EntityManager has been close!!!");
        T[] resultList;
        foreach (entity; entities)
        {
            resultList ~= this.save(entity);
        }
        return resultList;
    }
}

string GenerateFindById(T)()
{
    return "_manager.find!T(entity." ~ getSymbolsByUDA!(T, PrimaryKey)[0].stringof ~ ")";
}
