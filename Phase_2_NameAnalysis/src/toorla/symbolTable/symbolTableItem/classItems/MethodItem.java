package toorla.symbolTable.symbolTableItem.classItems;

import toorla.symbolTable.symbolTableItem.SymbolTableItem;

public class MethodItem extends SymbolTableItem {

    public MethodItem(String name){
        this.name = name;
    }

    @Override
    public String getKey() {return "METHOD__-__NAME" + name;}
}
