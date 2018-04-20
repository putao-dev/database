


module entity.EntityFieldInfo;

import std.variant;
import entity;

class EntityFieldInfo {
    
    private int _mark;
    private string _columnName;
    private string _fileldName;
    private DlangDataType _fieldType;
    private Variant _fieldValue;


    public this(string fileldName,string columnName, DlangDataType fieldType, Variant fieldValue,int mark = 0) {
        _fileldName = fileldName;
        _columnName = columnName;
        _fieldType = fieldType;
        _mark = mark;
        _fieldValue = fieldValue;
    }
    
    public Variant getFieldValue() {return _fieldValue;}
    public string getFileldName() {return _fileldName;}
    public DlangDataType getFieldType() {return _fieldType;}
    public string getColumnName() {return _columnName;}


    public int addmark(int mark) {
        return _mark |= mark;
    }
    public int removemark(int mark) {
        return _mark & (~mark);
    }
    public int checkmark(int mark) {
        return _mark & mark;
    }
    


}