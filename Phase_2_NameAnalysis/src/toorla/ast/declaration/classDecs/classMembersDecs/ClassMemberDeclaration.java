package toorla.ast.declaration.classDecs.classMembersDecs;

import toorla.ast.expression.Identifier;
import toorla.visitor.Visitor;

public interface ClassMemberDeclaration {
    <R> R accept(Visitor<R> visitor);
    String toString();
    boolean isField();
    Identifier getName();
    int getLine();
}