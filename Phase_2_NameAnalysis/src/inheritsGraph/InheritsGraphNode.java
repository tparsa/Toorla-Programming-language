package inheritsGraph;

import toorla.ast.declaration.classDecs.ClassDeclaration;
import toorla.ast.expression.Identifier;

import java.util.ArrayList;
import java.util.List;

public class InheritsGraphNode {
    private String name;
    private String parName;
    private InheritsGraphNode par;
    private ClassDeclaration classDec;
    public List<InheritsGraphNode> children;

    public InheritsGraphNode(String name){
        this(name, new ClassDeclaration(new Identifier("Any")), null);
    }

    public InheritsGraphNode(String name, ClassDeclaration classDec, String parName){
        this.children = new ArrayList<>();
        this.name = name;
        this.classDec = classDec;
        this.parName = parName;
    }

    public String getParName() { return this.parName; }

    public void setPar(InheritsGraphNode par) { this.par = par; }

    public String getName() { return name; }

    public void addChild(InheritsGraphNode child){
        this.children.add(child);
    }

    public ClassDeclaration getClassDec() { return this.classDec; }
}
