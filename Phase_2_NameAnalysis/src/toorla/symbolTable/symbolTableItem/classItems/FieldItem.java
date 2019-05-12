package toorla.symbolTable.symbolTableItem.classItems;

import toorla.symbolTable.symbolTableItem.SymbolTableItem;

public class FieldItem extends SymbolTableItem {
    public FieldItem(String name){
        this.name = name;
    }

    @Override
    public String getKey() { return "FIELD__-__NAME" + name; }
}
