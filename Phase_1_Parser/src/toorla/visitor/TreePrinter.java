package toorla.visitor;

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
import toorla.ast.expression.unaryExpression.UnaryExpression;
import toorla.ast.expression.value.BoolValue;
import toorla.ast.expression.value.IntValue;
import toorla.ast.expression.value.StringValue;
import toorla.ast.statement.*;
import toorla.ast.statement.localVarStats.LocalVarDef;
import toorla.ast.statement.localVarStats.LocalVarsDefinitions;
import toorla.ast.statement.returnStatement.Return;

import javax.swing.plaf.nimbus.State;
import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.List;

public class TreePrinter implements Visitor<Void> {
    //TODO : Implement all visit methods in TreePrinter to print AST as required in phase1 document
    @Override
    public Void visit(PrintLine printStat) {
        System.out.print("(print ");
        printStat.getArg().accept(this);
        System.out.println(")");
        return null;
    }

    @Override
    public Void visit(Assign assignStat) {
        System.out.print("(= ");
        assignStat.getLvalue().accept(this);
        System.out.print(" ");
        assignStat.getRvalue().accept(this);
        System.out.println(")");
        return null;
    }

    @Override
    public Void visit(Block block) {
        System.out.println("(");
        for (int i = 0; i < block.body.size(); i++)
            block.body.get(i).accept(this);
        System.out.println(")");
        return null;
    }

    @Override
    public Void visit(Conditional conditional) {
        System.out.print("(if ");
        conditional.getCondition().accept(this);
        System.out.print("\n");
        conditional.getThenStatement().accept(this);
        if(conditional.getElseStatement() != null)
            conditional.getElseStatement().accept(this);
        System.out.println(")");
        return null;
    }

    @Override
    public Void visit(While whileStat) {
        System.out.print("(while ");
        whileStat.expr.accept(this);
        whileStat.body.accept(this);
        System.out.println(")");
        return null;
    }

    @Override
    public Void visit(Return returnStat) {
        System.out.print("(return ");
        returnStat.getReturnedExpr().accept(this);
        System.out.println(" )");
        return null;
    }

    @Override
    public Void visit(Break breakStat) {
        System.out.print(breakStat.toString());
        return null;
    }

    @Override
    public Void visit(Continue continueStat) {
        System.out.print(continueStat.toString());
        return null;
    }

    @Override
    public Void visit(Skip skip) {
        System.out.println(skip.toString());
        return null;
    }

    private void BinaryPrinter(BinaryExpression binexp, String op)
    {
        System.out.print("(" + op + " ");
        binexp.getLhs().accept(this);
        System.out.print(" ");
        binexp.getRhs().accept(this);
        System.out.print(")");
    }

    @Override
    public Void visit(LocalVarDef localVarDef) {
        System.out.print("(var " + localVarDef.getLocalVarName().toString() + " ");
        localVarDef.getInitialValue().accept(this);
        System.out.println(")");
        return null;
    }

    private void incdecPrinter(Expression oprand, String op)
    {
        System.out.print("(" + op + " ");
        oprand.accept(this);
        System.out.println(")");
    }

    @Override
    public Void visit(IncStatement incStatement) {
        incdecPrinter(incStatement.getOperand(), "++");
        return null;
    }

    @Override
    public Void visit(DecStatement decStatement) {
        incdecPrinter(decStatement.getOperand(), "--");
        return null;
    }

    @Override
    public Void visit(Plus plusExpr) {
        BinaryPrinter(plusExpr, "+");
        return null;
    }

    @Override
    public Void visit(Minus minusExpr) {
        BinaryPrinter(minusExpr, "-");
        return null;
    }

    @Override
    public Void visit(Times timesExpr) {
        BinaryPrinter(timesExpr, "*");
        return null;
    }

    @Override
    public Void visit(Division divExpr) {
        BinaryPrinter(divExpr, "/");
        return null;
    }

    @Override
    public Void visit(Modulo moduloExpr) {
        BinaryPrinter(moduloExpr, "%");
        return null;
    }

    @Override
    public Void visit(Equals equalsExpr) {
        BinaryPrinter(equalsExpr, "==");
        return null;
    }

    @Override
    public Void visit(GreaterThan gtExpr){
        BinaryPrinter(gtExpr, ">");
        return null;
    }

    @Override
    public Void visit(LessThan lessThanExpr) {
        BinaryPrinter(lessThanExpr, "<");
        return null;
    }

    @Override
    public Void visit(And andExpr) {
        BinaryPrinter(andExpr, "&&");
        return null;
    }

    @Override
    public Void visit(Or orExpr) {
        BinaryPrinter(orExpr, "||");
        return null;
    }

    private void UnaryPrinter(UnaryExpression uniexp, String op)
    {
        System.out.print("(" + op + " ");
        uniexp.getExpr().accept(this);
        System.out.print(")");
    }

    @Override
    public Void visit(Neg negExpr) {
        UnaryPrinter(negExpr, "-");
        return null;
    }

    @Override
    public Void visit(Not notExpr) {
        UnaryPrinter(notExpr, "!");
        return null;
    }

    @Override
    public Void visit(MethodCall methodCall) {
        System.out.print("(. ");
        methodCall.getInstance().accept(this);
        System.out.print(" ");
        methodCall.getMethodName().accept(this);
        System.out.print(" (");
        ArrayList<Expression> args = methodCall.getArgs();
        for (Expression arg : args)
        {
            arg.accept(this);
            System.out.print(" ");
        }
        System.out.print("))");
        return null;
    }

    @Override
    public Void visit(Identifier identifier) {
        System.out.print(identifier.toString());
        return null;
    }

    @Override
    public Void visit(Self self) {
        System.out.print(self.toString());
        return null;
    }

    @Override
    public Void visit(IntValue intValue) {
        System.out.print(intValue.toString());
        return null;
    }

    @Override
    public Void visit(NewArray newArray) {
        System.out.print("(new arrayof " + newArray.getType().toString());
        newArray.getLength().accept(this);
        System.out.print(")");
        return null;
    }

    @Override
    public Void visit(BoolValue booleanValue) {
        System.out.print(booleanValue.toString());
        return null;
    }

    @Override
    public Void visit(StringValue stringValue) {
        System.out.print(stringValue.toString());
        return null;
    }

    @Override
    public Void visit(NewClassInstance newClassInstance) {
        System.out.print("(new ");
        newClassInstance.getClassName().accept(this);
        System.out.print(")");
        return null;
    }

    @Override
    public Void visit(FieldCall fieldCall) {
        System.out.print("(. ");
        fieldCall.getInstance().accept(this);
        System.out.print(" ");
        fieldCall.getField().accept(this);
        System.out.println(")");
        return null;
    }

    @Override
    public Void visit(ArrayCall arrayCall) {
        System.out.print("([] ");
        arrayCall.getInstance().accept(this);
        System.out.print(" ");
        arrayCall.getIndex().accept(this);
        System.out.print(")");
        return null;
    }

    @Override
    public Void visit(NotEquals notEquals) {
        BinaryPrinter(notEquals, "<>");
        return null;
    }

    private void printEntryAndNormalClasses(ClassDeclaration classDeclaration, String start)
    {
        String s = start;
        s += classDeclaration.getName().toString();
        if(classDeclaration.getParentName() != null)
            s += " " + classDeclaration.getParentName().toString();
        ArrayList<ClassMemberDeclaration> CMD = classDeclaration.getClassMembers();
        System.out.println(s);
        for (ClassMemberDeclaration cmd : CMD) {
            cmd.accept(this);
            System.out.print("\n");
        }
        System.out.print(")");
    }

    @Override
    public Void visit(ClassDeclaration classDeclaration) {
        printEntryAndNormalClasses(classDeclaration, "(class");
        return null;
    }

    @Override
    public Void visit(EntryClassDeclaration entryClassDeclaration) {
        printEntryAndNormalClasses(entryClassDeclaration, "(entry class");
        return null;
    }

    @Override
    public Void visit(FieldDeclaration fieldDeclaration) {
        System.out.print("(" + fieldDeclaration.getAccessModifier().toString() + " field " + fieldDeclaration.getIdentifier().toString() + " " + fieldDeclaration.getType().toString() + ")");
        return null;
    }

    @Override
    public Void visit(ParameterDeclaration parameterDeclaration) {
        System.out.print("(");
        parameterDeclaration.getIdentifier().accept(this);
        System.out.print(":" + parameterDeclaration.getType().toString());
        System.out.print(")");
        return null;
    }

    @Override
    public Void visit(MethodDeclaration methodDeclaration) {
        System.out.println("(" + methodDeclaration.getAccessModifier().toString() + " method " + methodDeclaration.getName().toString());
        ArrayList<ParameterDeclaration> params = methodDeclaration.getArgs();
        for (ParameterDeclaration param : params)
        {
            param.accept(this);
            System.out.print(" ");
        }
        System.out.print("\n");
        System.out.println(methodDeclaration.getReturnType().toString());
        System.out.print("(");
        ArrayList<Statement> stmts = methodDeclaration.getBody();
        for (Statement stmt : stmts)
        {
            stmt.accept(this);
        }
        System.out.println(")");
        System.out.println(")");
        return null;
    }

    @Override
    public Void visit(LocalVarsDefinitions localVarsDefinitions) {
        List<LocalVarDef> defs = localVarsDefinitions.getVarDefinitions();
        for (LocalVarDef def : defs)
            def.accept(this);
        return null;
    }

    @Override
    public Void visit(Program program) {
        List<ClassDeclaration> classes = program.getClasses();
        System.out.println("(");
        for(ClassDeclaration cls : classes)
            cls.accept(this);
        System.out.println(")");
        return null;
    }
}
