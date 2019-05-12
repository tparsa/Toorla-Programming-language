package toorla.symbolTable.symbolTableItem.classItems;

import toorla.symbolTable.symbolTableItem.SymbolTableItem;

public class ClassSymbolTableItem extends SymbolTableItem {
    private boolean isEntry;
    public ClassSymbolTableItem(String name){ this(name, false); }
    public ClassSymbolTableItem(String name, boolean isEntry){
        this.name = name;
        this.isEntry = isEntry;
    }

    @Override
    public String getKey() { return "CLASS__-__NAME" + name; }
}
