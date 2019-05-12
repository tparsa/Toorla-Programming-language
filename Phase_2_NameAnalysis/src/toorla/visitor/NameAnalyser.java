package toorla.visitor;

import inheritsGraph.InheritsGraph;
import inheritsGraph.InheritsGraphNode;
import toorla.ast.Program;
import toorla.ast.declaration.classDecs.ClassDeclaration;
import toorla.ast.declaration.classDecs.EntryClassDeclaration;
import toorla.ast.declaration.classDecs.classMembersDecs.ClassMemberDeclaration;
import toorla.ast.declaration.classDecs.classMembersDecs.FieldDeclaration;
import toorla.ast.declaration.classDecs.classMembersDecs.MethodDeclaration;
import toorla.ast.declaration.localVarDecs.ParameterDeclaration;
import toorla.ast.expression.*;
import toorla.ast.expression.binaryExpression.*;
import toorla.ast.expression.unaryExpression.Neg;
import toorla.ast.expression.unaryExpression.Not;
import toorla.ast.expression.value.BoolValue;
import toorla.ast.expression.value.IntValue;
import toorla.ast.expression.value.StringValue;
import toorla.ast.statement.*;
import toorla.ast.statement.localVarStats.LocalVarDef;
import toorla.ast.statement.localVarStats.LocalVarsDefinitions;
import toorla.ast.statement.returnStatement.Return;
import toorla.symbolTable.Stack;
import toorla.symbolTable.SymbolTable;
import toorla.symbolTable.exceptions.ItemAlreadyExistsException;
import toorla.symbolTable.symbolTableItem.SymbolTableItem;
import toorla.symbolTable.symbolTableItem.classItems.ClassSymbolTableItem;
import toorla.symbolTable.symbolTableItem.classItems.FieldItem;
import toorla.symbolTable.symbolTableItem.classItems.MethodItem;
import toorla.symbolTable.symbolTableItem.varItems.LocalVariableSymbolTableItem;
import tuple.Tuple;

import javax.swing.plaf.nimbus.State;
import java.util.*;

public class NameAnalyser implements Visitor<Boolean> {

    private SymbolTable env;
    private SymbolTable methodFieldRedefEnv;
    private int redundantCounter;
    private InheritsGraph classGraph;
    private int index;
    List<Tuple<Integer, String>> errs;
    Map<String, Integer> dfsMark;

    public Boolean visit(PrintLine printStat) { return true; }
    public Boolean visit(Assign assignStat) { return true; }
    public Boolean visit(Block block){
        SymbolTable curSymbolTable = new SymbolTable();
        curSymbolTable.SymbolTableCopy(env);
        env = new SymbolTable();
        for (Statement statement : block.body)
            statement.accept(this);
        env.SymbolTableCopy(curSymbolTable);
        return true;
    }
    public Boolean visit(Conditional conditional){
        Statement thenStmt = conditional.getThenStatement();
        Statement elseStmt = conditional.getElseStatement();
        SymbolTable curSymbolTable = new SymbolTable();
        curSymbolTable.SymbolTableCopy(env);
        env = new SymbolTable();
        thenStmt.accept(this);
        env = new SymbolTable();
        elseStmt.accept(this);
        env.SymbolTableCopy(curSymbolTable);
        return true;
    }
    public Boolean visit(While whileStat){
        SymbolTable curSymbolTable = new SymbolTable();
        curSymbolTable.SymbolTableCopy(env);
        env = new SymbolTable();
        whileStat.body.accept(this);
        env.SymbolTableCopy(curSymbolTable);
        return true;
    }
    public Boolean visit(Return returnStat){return true;}
    public Boolean visit(Break breakStat){return true;}
    public Boolean visit(Continue continueStat){return true;}
    public Boolean visit(Skip skip){return true;}
    public Boolean visit(LocalVarDef localVarDef){
        try{
            String varName = localVarDef.getLocalVarName().getName();
            String newVarName = varName + "_" + index;
            env.put(new LocalVariableSymbolTableItem(varName, index));
            localVarDef.setIdentifier(new Identifier(newVarName));
            index++;
        }
        catch (ItemAlreadyExistsException exp){
            Integer errLine = localVarDef.line;
            String errMsg = "Error:Line:" + errLine.toString() + ":Redefinition of Local Variable " + localVarDef.getLocalVarName().getName() + " in current scope";
            errs.add(new Tuple<>(errLine, errMsg));
        }
        return true;
    }
    public Boolean visit(IncStatement incStatement){return true;}
    public Boolean visit(DecStatement decStatement){return true;}



    // Expression
    public Boolean visit(Plus plusExpr){return true;}
    public Boolean visit(Minus minusExpr){return true;}
    public Boolean visit(Times timesExpr){return true;}
    public Boolean visit(Division divExpr){return true;}
    public Boolean visit(Modulo moduloExpr){return true;}
    public Boolean visit(Equals equalsExpr){return true;}
    public Boolean visit(GreaterThan gtExpr){return true;}
    public Boolean visit(LessThan lessThanExpr){return true;}
    public Boolean visit(And andExpr){return true;}
    public Boolean visit(Or orExpr){return true;}
    public Boolean visit(Neg negExpr){return true;}
    public Boolean visit(Not notExpr){return true;}
    public Boolean visit(MethodCall methodCall){return true;}
    public Boolean visit(Identifier identifier){return true;}
    public Boolean visit(Self self){return true;}
    public Boolean visit(IntValue intValue){return true;}
    public Boolean visit(NewArray newArray){return true;}
    public Boolean visit(BoolValue booleanValue){return true;}
    public Boolean visit(StringValue stringValue){return true;}
    public Boolean visit(NewClassInstance newClassInstance){return true;}
    public Boolean visit(FieldCall fieldCall){return true;}
    public Boolean visit(ArrayCall arrayCall){return true;}
    public Boolean visit(NotEquals notEquals){return true;}

    //declarations
    private void addNewClass(ClassDeclaration classDeclaration, boolean isEntry){
        try {
            env.put(new ClassSymbolTableItem(classDeclaration.getName().getName(), isEntry));
        }
        catch(ItemAlreadyExistsException exp){
            Integer errLine = classDeclaration.line;
            String errMsg = "Error:Line:" + errLine.toString() + ":Redefinition of Class " + classDeclaration.getName().getName();
            errs.add(new Tuple<>(errLine, errMsg));
            try {
                String newClassName = Integer.toString(redundantCounter);
                env.put(new ClassSymbolTableItem(classDeclaration.getName().getName().concat("Temp_____-_____"+classDeclaration.getName().getName() + "_____-_____" + newClassName)));
                redundantCounter++;
            }
            catch(ItemAlreadyExistsException e){
                //This Won't happen
            }
        }
    }

    public Boolean visit(ClassDeclaration classDeclaration){
        addNewClass(classDeclaration, false);
        //for
        return true;
    }
    public Boolean visit(EntryClassDeclaration entryClassDeclaration){
        addNewClass(entryClassDeclaration, true);
        return true;
    }
    public Boolean visit(FieldDeclaration fieldDeclaration){
        try{
            env.put(new FieldItem(fieldDeclaration.getName().getName()));
        }
        catch (ItemAlreadyExistsException exp){
            // already handled
        }

        return true;
    }
    public Boolean visit(ParameterDeclaration parameterDeclaration){return true;}
    public Boolean visit(MethodDeclaration methodDeclaration){
        SymbolTable scopeSymbolTable = new SymbolTable();
        scopeSymbolTable.SymbolTableCopy(env);
        env = new SymbolTable();
        try {
            env.put(new MethodItem(methodDeclaration.getName().getName()));
            List<ParameterDeclaration> args = methodDeclaration.getArgs();
           // System.out.println("\n\n\n\n HELOOOASODAOSDFO: " + methodDeclaration.getName().getName() + " " + args.size());
            index = 1;
            for (ParameterDeclaration arg : args){
                try{
                    String argName = arg.getIdentifier().getName();
                    String newArgName = argName + "_" + index;
                    env.put(new LocalVariableSymbolTableItem( argName, index ));
                    index++;
                 //   System.out.print("\n\n");
                   // System.out.println("\n\n\n HALOOOOO: " + methodDeclaration.getName().getName() + " " + argName + " " + newArgName);
                    arg.setIdentifier(new Identifier(newArgName));
                }
                catch(ItemAlreadyExistsException exp){
                    Integer errLine = methodDeclaration.line;
                    String errMsg = "Error:Line:" + errLine.toString() + ":Redefinition of Local Variable " + arg.getIdentifier().getName() + " in current scope";
                    errs.add(new Tuple<>(errLine, errMsg));
                }
            }
            List<Statement> body = methodDeclaration.getBody();
            SymbolTable curSymbolTable = new SymbolTable();
            curSymbolTable.SymbolTableCopy(env);
            for (Statement statement : body)
                statement.accept(this);
            env.SymbolTableCopy(curSymbolTable);
        }
        catch(ItemAlreadyExistsException exp){
            // No need to handle
        }
        env.SymbolTableCopy(scopeSymbolTable);
        return true;
    }

    public Boolean visit(LocalVarsDefinitions localVarsDefinitions){
        List<LocalVarDef> localVarDefs = localVarsDefinitions.getVarDefinitions();
        for (LocalVarDef lvd : localVarDefs)
            lvd.accept(this);
        return true;
    }

    public Boolean visit(Program program){
        env = new SymbolTable();
        classGraph = new InheritsGraph();
        errs = new ArrayList<>();
        try {
            env.put(new ClassSymbolTableItem("Any"));
        }
        catch (ItemAlreadyExistsException exp) {
            //
        }
        List<ClassDeclaration> classDecs = program.getClasses();
        for (ClassDeclaration cd : classDecs)
            cd.accept(this);

        for (ClassDeclaration cd : classDecs) {
            String parName = cd.getParentName().getName();
            if(parName == null)
                parName = "__Any__";
            classGraph.addClass(cd.getName().getName(), cd, parName);
        }

        classGraph.setParNodes();

       // System.out.println("HAYA FUKKKKKERS" + classGraph.findNodeWithName("__Any__").children.size());
        dfsCheckMethodFieldRedefinition();

        for (ClassDeclaration cd : classDecs){
            List<ClassMemberDeclaration> classMemDecs = cd.getClassMembers();
            for (ClassMemberDeclaration cmd : classMemDecs)
                cmd.accept(this);
        }

        bubbleSortErrs();

        for (Tuple<Integer, String> err : errs){
            System.out.println(err.y);
        }

        return (errs.size() == 0);
    }

    private void bubbleSortErrs() {
        for (int i = 0; i < errs.size(); i++)
            for (int j = 0; j < errs.size() - 1; j++)
                if(errs.get(j).x > errs.get(j + 1).x)
                    Collections.swap(errs, j, j + 1);
    }
    private void dfsVisitField(ClassMemberDeclaration fieldDeclaration){
        if(fieldDeclaration.getName().getName().equals("length")){
            Integer errLine = fieldDeclaration.getLine();
            String errMsg = "Error:Line:" + errLine.toString() + ":Definition of length as field of a class";
            errs.add(new Tuple<>(errLine, errMsg));
        }
        else {
            try {
                methodFieldRedefEnv.put(new FieldItem(fieldDeclaration.getName().getName()));
             /*   Map<String, SymbolTableItem> test = methodFieldRedefEnv.getItems();
                for (Map.Entry<String, SymbolTableItem> ent : test.entrySet()){
                    System.out.println(ent.getKey() +  " = " + ent.getValue());
                }*/
            } catch (ItemAlreadyExistsException exp) {
                Integer errLine = fieldDeclaration.getLine();
                String errMsg = "Error:Line:" + errLine.toString() + ":Redefinition of Field " + fieldDeclaration.getName().getName();
                errs.add(new Tuple<>(errLine, errMsg));
            }
        }
    }

    private void dfsVisitMethod (ClassMemberDeclaration methodDeclaration){
        try{
            methodFieldRedefEnv.put(new MethodItem(methodDeclaration.getName().getName()));
        }
        catch (ItemAlreadyExistsException exp){
            Integer errLine = methodDeclaration.getLine();
            String errMsg = "Error:Line:" + errLine.toString() + ":Redefinition of Method " + methodDeclaration.getName().getName();
            errs.add(new Tuple<>(errLine, errMsg));
        }
    }

    private void dfsVisit(InheritsGraphNode node){
        if(dfsMark.containsKey(node.getName()))
            dfsMark.put(node.getName(), 2);
        else dfsMark.put(node.getName(), 1);

        List<ClassMemberDeclaration> classMemDecs = node.getClassDec().getClassMembers();
        for (ClassMemberDeclaration cmd : classMemDecs)
            if(cmd.isField())
                dfsVisitField(cmd);
            else
                dfsVisitMethod(cmd);
        SymbolTable curSymbolTable = new SymbolTable();
        curSymbolTable.SymbolTableCopy(methodFieldRedefEnv);
        for (InheritsGraphNode nextNode : node.children)
            if(!dfsMark.containsKey(nextNode.getName()))
                dfsVisit(nextNode);
            else if(dfsMark.get(nextNode.getName()) == 1) {
                dfsVisit(nextNode);
            }
        methodFieldRedefEnv.SymbolTableCopy(curSymbolTable);

    }

    private void dfsCheckMethodFieldRedefinition(){
        dfsMark = new HashMap<>();
        methodFieldRedefEnv = new SymbolTable();
        dfsVisit(classGraph.findNodeWithName("__Any__"));
        for (String nodeName : classGraph.nodesName){
            if(!dfsMark.containsKey(nodeName)) {
                methodFieldRedefEnv = new SymbolTable();
                dfsVisit(classGraph.findNodeWithName(nodeName));
            }
        }
    }
}
