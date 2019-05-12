package inheritsGraph;

import toorla.ast.declaration.classDecs.ClassDeclaration;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class InheritsGraph {
    private Map<String, InheritsGraphNode> nodes;
    public List<String> nodesName;

    public InheritsGraph(){
        nodes = new HashMap<>();
        nodesName = new ArrayList<>();
        this.addClass("__Any__");
    }
    private void addClass(String name){
        nodesName.add(name);
        nodes.put(name, new InheritsGraphNode(name));
    }
    public void addClass (String name, ClassDeclaration classDec, String parName){
        nodesName.add(name);
        InheritsGraphNode newNode = new InheritsGraphNode(name, classDec, parName);
        nodes.put(name, newNode);
    }

    public InheritsGraphNode findNodeWithName(String name){
        return nodes.getOrDefault(name, null);
    }

    public void setParNodes(){
        for (Map.Entry<String, InheritsGraphNode> node : nodes.entrySet()){
            if(node.getKey() != "__Any__") {
                String parName = node.getValue().getParName();
                InheritsGraphNode parNode = findNodeWithName(parName);
                node.getValue().setPar(parNode);
                if(parNode != null)
                    parNode.addChild(node.getValue());
            }
        }
    }
}
