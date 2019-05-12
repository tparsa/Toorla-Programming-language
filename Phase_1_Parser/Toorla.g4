grammar Toorla;

@header
{
    import toorla.ast.*;
    import toorla.ast.declaration.*;
    import toorla.ast.declaration.classDecs.*;
    import toorla.ast.declaration.classDecs.classMembersDecs.*;
    import toorla.ast.declaration.localVarDecs.*;
    import toorla.ast.expression.*;
    import toorla.ast.expression.binaryExpression.*;
    import toorla.ast.expression.unaryExpression.*;
    import toorla.ast.expression.value.*;
    import toorla.ast.statement.*;
    import toorla.ast.statement.localVarStats.*;
    import toorla.ast.statement.returnStatement.*;
    import toorla.types.*;
    import toorla.types.arrayType.*;
    import toorla.types.singleType.*;
}

@members
{
    int line;
}

program returns [Program mProgram]
    :   (class_dec+=class_definition)+ EOF
        {
            $mProgram = new Program();
            for (int i = 0; i < $class_dec.size(); i++)
                $mProgram.addClass($class_dec.get(i).class_dec);
            $mProgram.line = 0;
            $mProgram.col = 0;
        }
    ;

class_definition returns[ClassDeclaration class_dec]
    :   ecd=entry_class_definition
        {
            $class_dec = $ecd.entry_class_dec;
        }
    |
        (
        (cls=CLASS name=ID (INHERITS par_name=ID)?)
        {
            if($par_name != null)
                $class_dec = new ClassDeclaration(new Identifier($name.text), new Identifier($par_name.text));
            else $class_dec = new ClassDeclaration(new Identifier($name.text));
            $class_dec.line = $cls.getLine();
            $class_dec.col = $cls.getCharPositionInLine();
        }
        (COLON cls_bdy=class_body[$class_dec] END)
        )
    ;


entry_class_definition returns [EntryClassDeclaration entry_class_dec]
    :   (
        (ent=ENTRY CLASS name=ID (INHERITS par_name=ID)?)
        {
            if($par_name != null)
                $entry_class_dec = new EntryClassDeclaration(new Identifier($name.text), new Identifier($par_name.text));
            else $entry_class_dec = new EntryClassDeclaration(new Identifier($name.text));
            $entry_class_dec.line = $ent.getLine();
            $entry_class_dec.col = $ent.getCharPositionInLine();

        }
        (COLON cls_bdy=class_body[$entry_class_dec] END)
        )
    ;

class_body [ClassDeclaration class_dec]
    :   (
            method=method_definition
            {
                $class_dec.addMethodDeclaration($method.method_dec);
            }
            |
            field=field_definition
            {
                for (int j = 0; j < $field.field_decs.size(); j++)
                    $class_dec.addFieldDeclaration($field.field_decs.get(j));
            }
        )+
    ;

access_modifier returns[ String access_mod ]
    :   acm = (PUBLIC | PRIVATE)?
        {
            if($acm == null)
                $access_mod = "auto";
            else if($acm.text.equals( "private" ))
                $access_mod = "private";
            else if($acm.text.equals( "public" ))
                $access_mod = "public";
         }
    ;

method_definition returns [MethodDeclaration method_dec]
    :   ac=access_modifier FUNCTION name=ID LPAREN mdp=method_definition_param RPAREN RETURNS ret_type=type  COLON mbdy=method_body END
        {
            $method_dec = new MethodDeclaration(new Identifier($name.text));
            if($ac.access_mod.equals("private"))
                $method_dec.setAccessModifier(AccessModifier.ACCESS_MODIFIER_PRIVATE);
            $method_dec.setReturnType($ret_type.typee);
            for (int i = 0; i < $mdp.method_params.size(); i++)
                $method_dec.addArg($mdp.method_params.get(i));
            for(int i = 0; i < $mbdy.body_statements.size(); i++)
                $method_dec.addStatement($mbdy.body_statements.get(i));

        }
    ;

method_definition_param returns [List<ParameterDeclaration> method_params]
    :   (name+=ID COLON types+=type)?
        {
            $method_params = new ArrayList<ParameterDeclaration>();
            if($name.size() != 0)
            {
                for (int i = 0; i < $name.size(); i++)
                    $method_params.add(new ParameterDeclaration(new Identifier($name.get(i).getText()), $types.get(i).typee));
            }
        }
    |
        (first_name=ID COLON first_type=type) (COMMA other_names+=ID COLON other_types+=type)+
        {
            $method_params = new ArrayList<ParameterDeclaration>();
            $method_params.add(new ParameterDeclaration(new Identifier($first_name.text), $first_type.typee));
            for (int i = 0; i < $other_names.size(); i++)
                $method_params.add(new ParameterDeclaration(new Identifier($other_names.get(i).getText()), $other_types.get(i).typee));
        }
    ;

method_call_param returns[List<Expression> exprs]
    :   expr+=expression?
        {
            $exprs = new ArrayList<Expression>();
            if($expr.size() != 0)
                $exprs.add($expr.get(0).expr);
        }
    |
        first_expr=expression (COMMA other_exprs+=expression)+
        {
            $exprs = new ArrayList<Expression>();
            $exprs.add($first_expr.expr);
            for (int i = 0; i < $other_exprs.size(); i++)
                $exprs.add($other_exprs.get(i).expr);
        }
    ;

method_body returns [List<Statement> body_statements]
    :   body_stmnts+=statement+
        {
            $body_statements = new ArrayList<Statement>();
            for (int i = 0; i < $body_stmnts.size(); i++)
                $body_statements.add($body_stmnts.get(i).stmnt);
        }
    ;

statement returns[Statement stmnt]
    :   ois=open_if_statement
        {
            $stmnt = $ois.open_if_stmnt;
        }
    |
        cis=closed_if_statement
        {
            $stmnt = $cis.closed_if_stmnt;
        }
    ;

open_if_statement returns [Statement open_if_stmnt]
    :   if1=IF LPAREN if1_cond=expression RPAREN if1_stmnt=statement
        {
            $open_if_stmnt = new Conditional($if1_cond.expr, $if1_stmnt.stmnt, new Skip());
            $open_if_stmnt.line = $if1.getLine();
            $open_if_stmnt.col = $if1.getCharPositionInLine();
        }
//    |
  //      IF LPAREN expression RPAREN open_if_statement
    |
        if2=IF LPAREN if2_cond1=expression RPAREN if2_then_stmt=closed_if_statement ( ELIF LPAREN if2_other_conds+=expression RPAREN if2_other_stmt+=closed_if_statement )* (ELIF LPAREN if2_last_cond=expression RPAREN if2_last_stmt=statement)
        {
            Statement tmp = new Conditional($if2_last_cond.expr, $if2_last_stmt.stmnt, new Skip());
            for (int i = (int)$if2_other_conds.size() - 1; i > -1; i--)
            {
                tmp = new Conditional($if2_other_conds.get(i).expr, $if2_other_stmt.get(i).closed_if_stmnt, tmp);
                tmp.line = $if2_other_conds.get(i).expr.line;
                tmp.col = $if2_other_conds.get(i).expr.col;
            }
            $open_if_stmnt = new Conditional($if2_cond1.expr, $if2_then_stmt.closed_if_stmnt, tmp);
            $open_if_stmnt.col = $if2.getCharPositionInLine();
            $open_if_stmnt.line = $if2.getLine();
        }
    |
        if3=IF LPAREN if3_cond1=expression RPAREN if3_then_stmt=closed_if_statement ( ELIF LPAREN if3_other_conds+=expression RPAREN if3_other_stmt+=closed_if_statement )* ELSE if3_last_stmt=open_if_statement
        {
            if($if3_other_conds.size() != 0)
            {
                Statement tmp = new Conditional($if3_other_conds.get($if3_other_conds.size() - 1).expr, $if3_other_stmt.get($if3_other_stmt.size() - 1).closed_if_stmnt, $if3_last_stmt.open_if_stmnt);
                for (int i = (int)$if3_other_conds.size() - 2; i > -1; i--)
                {
                    tmp = new Conditional($if3_other_conds.get(i).expr, $if3_other_stmt.get(i).closed_if_stmnt, tmp);
                    tmp.line = $if3_other_conds.get(i).expr.line;
                    tmp.col = $if3_other_conds.get(i).expr.col;
                }
                $open_if_stmnt = new Conditional($if3_cond1.expr, $if3_then_stmt.closed_if_stmnt, tmp);
            }
            else
            {
                $open_if_stmnt = new Conditional($if3_cond1.expr, $if3_then_stmt.closed_if_stmnt, $if3_last_stmt.open_if_stmnt);
            }
            $open_if_stmnt.col = $if3.getCharPositionInLine();
            $open_if_stmnt.line = $if3.getLine();
        }
    |
        wh=WHILE LPAREN while_cond=expression RPAREN while_body=open_if_statement
        {
            $open_if_stmnt = new While($while_cond.expr, $while_body.open_if_stmnt);
            $open_if_stmnt.line = $wh.getLine();
            $open_if_stmnt.col = $wh.getCharPositionInLine();
        }
    ;

closed_if_statement returns [Statement closed_if_stmnt]
    :   simple_stmnt=simple_statement
        {
            $closed_if_stmnt = $simple_stmnt.sstmnt;
        }
    |
        if1=IF LPAREN cond1=expression RPAREN then_stmt=closed_if_statement ( ELIF LPAREN other_conds+=expression RPAREN other_stmt+=closed_if_statement )* ELSE last_stmt=closed_if_statement
        {
            if($other_conds.size() != 0)
            {
                Statement tmp = new Conditional($other_conds.get($other_conds.size() - 1).expr, $other_stmt.get($other_stmt.size() - 1).closed_if_stmnt, $last_stmt.closed_if_stmnt);
                for (int i = (int)$other_conds.size() - 2; i > -1; i--)
                {
                    tmp = new Conditional($other_conds.get(i).expr, $other_stmt.get(i).closed_if_stmnt, tmp);
                    tmp.line = $other_conds.get(i).expr.line;
                    tmp.col = $other_conds.get(i).expr.col;
                }
                $closed_if_stmnt = new Conditional($cond1.expr, $then_stmt.closed_if_stmnt, tmp);
            }
            else
            {
                $closed_if_stmnt = new Conditional($cond1.expr, $then_stmt.closed_if_stmnt, $last_stmt.closed_if_stmnt);
            }
            $closed_if_stmnt.col = $if1.getCharPositionInLine();
            $closed_if_stmnt.line = $if1.getLine();
        }
    |
        wh=WHILE LPAREN while_cond=expression RPAREN while_body=closed_if_statement
        {
            $closed_if_stmnt = new While($while_cond.expr, $while_body.closed_if_stmnt);
            $closed_if_stmnt.line = $wh.getLine();
            $closed_if_stmnt.col = $wh.getCharPositionInLine();
        }
    ;

simple_statement returns [Statement sstmnt]
    :   var_dec=variable_declaration
        {
            $sstmnt = $var_dec.lvd;
        }
    |
        inc1=increment
        {
            $sstmnt = $inc1.inc;
        }
    |
        dec1=decrement
        {
            $sstmnt = $dec1.dec;
        }
    |
        assign1=assign
        {
            $sstmnt = $assign1.ass;
        }
    |
        ret_stmnt=return_statement
        {
            $sstmnt = $ret_stmnt.ret;
        }
    |
        pr=print
        {
            $sstmnt = $pr.prntln;
        }
    |
        b=BEGIN stmt+=statement* END
        {
            Block new_block = new Block();
            new_block.line = $b.getLine();
            new_block.col = $b.getCharPositionInLine();
            for (int i = 0; i < $stmt.size(); i++)
                new_block.body.add($stmt.get(i).stmnt);
            $sstmnt = new_block;
            $sstmnt.line = $b.getLine();
            $sstmnt.col = $b.getCharPositionInLine();
        }

    |
        br=BREAK SEMICOLON
        {
           Break new_break = new Break();
           new_break.line = $br.getLine();
           new_break.col = $br.getCharPositionInLine();
           $sstmnt = new_break;
           $sstmnt.line = $br.getLine();
           $sstmnt.col = $br.getCharPositionInLine();
        }
    |
        cnt=CONTINUE SEMICOLON
        {
            Continue new_continue = new Continue();
            new_continue.line = $cnt.getLine();
            new_continue.col = $cnt.getCharPositionInLine();
            $sstmnt = new_continue;
            $sstmnt.line = $cnt.getLine();
            $sstmnt.col = $cnt.getCharPositionInLine();

        }
    |
        sem=SEMICOLON
        {
            $sstmnt = new Skip();
            $sstmnt.line = $sem.getLine();
            $sstmnt.col = $sem.getCharPositionInLine();
        }
    ;

print returns[PrintLine prntln]
    :   pr=PRINT LPAREN expr=expression RPAREN SEMICOLON
        {
            $prntln = new PrintLine($expr.expr);
            $prntln.line = $pr.getLine();
            $prntln.col = $pr.getCharPositionInLine();
        }
    ;

return_statement returns[Return ret]
    :   retrn=RETURN exp=expression SEMICOLON
        {
            $ret = new Return($exp.expr);
            $ret.line = $retrn.getLine();
            $ret.col = $retrn.getCharPositionInLine();
        }
    ;

assign returns [Assign ass]
    :   lv=expression ASSIGN expr=expression SEMICOLON
        {
            $ass = new Assign($lv.expr, $expr.expr);
            $ass.line = $lv.expr.line;
            $ass.col = $lv.expr.col;
        }
    ;

variable_declaration returns[Statement lvd]
    :   vr=VAR name=ID ASSIGN expr=expression (COMMA other_names+=ID ASSIGN other_exprs+=expression)* SEMICOLON
        {
            List<LocalVarDef> tmp_lvd = new ArrayList<LocalVarDef>();
            LocalVarDef first_var = new LocalVarDef(new Identifier($name.text), $expr.expr);
            first_var.line = $vr.getLine();
            first_var.col = $name.getCharPositionInLine();
            tmp_lvd.add(first_var);
            for (int i = 0; i < $other_names.size(); i++)
            {
                LocalVarDef new_var = new LocalVarDef(new Identifier($other_names.get(i).getText()), $other_exprs.get(i).expr);
                new_var.line = $vr.getLine();
                new_var.col = $other_names.get(i).getCharPositionInLine();
                tmp_lvd.add(new_var);
            }
            if(tmp_lvd.size() == 1)
                $lvd = tmp_lvd.get(0);
            else
            {
                LocalVarsDefinitions new_lvds = new LocalVarsDefinitions();
                for (LocalVarDef tmp : tmp_lvd)
                    new_lvds.addVarDefinition(tmp);
                $lvd = new_lvds;
            }
        }
    ;

expression returns [Expression expr]
    :   exp=semi_expression
        {
            $expr = $exp.expr;
        }
    |
        mexpr=method_expression
        {
            $expr = $mexpr.bmexpr;
        }
    ;

method_expression returns [Expression bmexpr]
    :   and1=method_andterm (OR and2+=expression)*
        {
            if($and2.size() == 0)
                $bmexpr = $and1.andexpr;
            else
            {
                $bmexpr = new Or($and1.andexpr, $and2.get(0).expr);
                for (int i = 1; i < $and2.size(); i++)
                    $bmexpr = new Or($bmexpr, $and2.get(i).expr);
                $bmexpr.line = $and1.andexpr.line;
                $bmexpr.col = $and1.andexpr.col;
            }
        }
    ;

method_andterm returns [Expression andexpr]
    :   comp1=method_compterm (AND comp2+=expression)*
        {
            if($comp2.size() == 0)
                $andexpr = $comp1.compexpr;
            else
            {
                $andexpr = new And($comp1.compexpr, $comp2.get(0).expr);
                for (int i = 1; i < $comp2.size(); i++)
                    $andexpr = new And($andexpr, $comp2.get(i).expr);
                $andexpr.line = $comp1.compexpr.line;
                $andexpr.col = $comp1.compexpr.col;
            }
        }
    ;

method_compterm returns [Expression compexpr]
    :   glt1=method_greaterlessthanterm ( op=(NOTEQUAL | EQUALS) glt2+=expression )?
        {
            if($glt2.size() == 0)
                $compexpr = $glt1.glexpr;
            else
            {
                if($op.text.equals( "<>" ))
                    $compexpr = new NotEquals($glt1.glexpr, $glt2.get(0).expr);
                else $compexpr = new Equals($glt1.glexpr, $glt2.get(0).expr);
                $compexpr.line = $glt1.glexpr.line;
                $compexpr.col = $glt1.glexpr.col;
            }

        }
    ;

method_greaterlessthanterm returns [Expression glexpr]
    :   add1=method_addition_expression ( op=(LESSTHAN | GREATERTHAN) add2+=expression )?
        {
            if($add2.size() == 0)
                $glexpr = $add1.plus;
            else
            {
                if($op.text.equals( "<" ))
                    $glexpr = new LessThan($add1.plus, $add2.get(0).expr);
                else $glexpr = new GreaterThan($add1.plus, $add2.get(0).expr);
                $glexpr.line = $add1.plus.line;
                $glexpr.col = $add1.plus.col;
            }
        }
    ;

method_addition_expression returns [Expression plus]
    :   exp1=method_mult_expression ( op+=(PLUS | MINUS) exp2+=expression)*
        {
            if($exp2.size() == 0)
                $plus = $exp1.bin;
            else
            {
                BinaryExpression tmp;
                if($op.get(0).getText().equals( "+" ))
                    tmp = new Plus($exp1.bin, $exp2.get(0).expr);
                else
                    tmp = new Minus($exp1.bin, $exp2.get(0).expr);
                tmp.line = $exp1.bin.line;
                tmp.col = $exp1.bin.col;
                for (int i = 1; i < $exp2.size(); i++)
                {
                    if($op.get(i).getText().equals( "+" ))
                        tmp = new Plus(tmp, $exp2.get(i).expr);
                    else
                        tmp = new Minus(tmp, $exp2.get(i).expr);
                    tmp.line = $exp1.bin.line;
                    tmp.col = $op.get(i).getCharPositionInLine();
                }
                $plus = tmp;
                $plus.line = $exp1.bin.line;
                $plus.col = $exp1.bin.col;
            }
        }
    ;

method_mult_expression returns [Expression bin]
    :   exp1=method_not_neg_expression ( op+=(TIMES | DIV | MOD) exp2+=expression )*
        {
            if($op.size() == 0)
                $bin = $exp1.uni;
            else
            {
                BinaryExpression tmp;
                if($op.get(0).getText().equals("/"))
                    tmp = new Division($exp1.uni, $exp2.get(0).expr);
                else if($op.get(0).getText().equals("*"))
                    tmp = new Times($exp1.uni, $exp2.get(0).expr);
                else
                    tmp = new Modulo($exp1.uni, $exp2.get(0).expr);

                for (int i = 1; i < $op.size(); i++)
                {
                    if($op.get(i).getText().equals("/"))
                        tmp = new Division(tmp, $exp2.get(i).expr);
                    else if($op.get(i).getText().equals("*"))
                        tmp = new Times(tmp, $exp2.get(i).expr);
                    else if($op.get(i).getText().equals("%"))
                        tmp = new Modulo(tmp, $exp2.get(i).expr);
                }
                $bin = tmp;
                $bin.line = $exp1.uni.line;
                $bin.col = $exp1.uni.col;
            }
        }
    ;

method_not_neg_expression returns [Expression uni]
    :   (nt+=NOT)+ fax1=dot_expression_with_method_call
        {
            $uni = new Not($fax1.expr);
            for (int i = 1; i < $nt.size(); i++)
                $uni = new Not($uni);
        }
    |
        (mi+=MINUS)+ fax2=dot_expression_with_method_call
        {
            $uni = new Neg($fax2.expr);
            for (int i = 1; i < $mi.size(); i++)
                $uni = new Neg($uni);
        }
    |
        fax3=dot_expression_with_method_call
        {
            $uni = $fax3.expr;
        }
    ;


semi_expression returns [Expression expr]
    :   exprwmc=expression_without_method_call
        {
            $expr = $exprwmc.expr;
        }
    |
        methodc=method_call
        {
            $expr = $methodc.mc;
        }
    |
        dewmc=dot_expression_with_method_call
        {
            $expr = $dewmc.expr;
        }
    |
        (id1=ID | id2=ID nw1=new_bracket) DOT (id3=ID | id4=ID nw2=new_bracket)
        {
            if($id1 == null)
            {
                if($id3 == null)
                {
                    $expr = new ArrayCall(new Identifier($id2.getText()), $nw1.expr);
                    $expr = new ArrayCall($expr, $nw2.expr);
                }
                else
                {
                    $expr = new ArrayCall(new Identifier($id2.getText()), $nw1.expr);
                    $expr = new FieldCall($expr, new Identifier($id3.getText()));
                }
            }
            else
            {
                if($id3 == null)
                {
                    $expr = new FieldCall(new Identifier($id1.getText()), new Identifier($id4.getText()));
                    $expr = new ArrayCall($expr, $nw2.expr);
                }
                else
                    $expr = new FieldCall(new Identifier($id1.getText()), new Identifier($id3.getText()));
            }
        }
        (DOT (lid=ID | nwid=ID lnw=new_bracket)
            {
                if($lid == null)
                {
                    $expr = new FieldCall($expr, new Identifier($nwid.getText()));
                    $expr = new ArrayCall($expr, $lnw.expr);
                }
                else
                    $expr = new FieldCall($expr, new Identifier($lid.getText()));
            }
        )*
    ;
expression_without_method_call returns[Expression expr]
    :   boolmathexpr=boolean_mathematical_expression
        {
            $expr = $boolmathexpr.bmexpr;
        }
    |
        naexpr=new_array_class_expression
        {
            $expr = $naexpr.new_array_class_expr;
        }
    ;

new_array_class_expression returns [Expression new_array_class_expr] locals[MethodCall tmp_mc]
    :   nw=NEW st=single_type nb=new_bracket
        {
            if($st.typee.equals( "bool" ))
                $new_array_class_expr = new NewArray( new BoolType(), $nb.expr );
            else if($st.typee.equals("int"))
                $new_array_class_expr = new NewArray( new IntType(), $nb.expr);
            else if($st.typee.equals("string"))
                $new_array_class_expr = new NewArray( new StringType(), $nb.expr);
            else $new_array_class_expr = new NewArray( new UserDefinedType(new ClassDeclaration(new Identifier($st.typee))), $nb.expr );
        }
        |
        nw=NEW st=single_type LPAREN RPAREN
        {
            $new_array_class_expr = new NewClassInstance(new Identifier($st.typee));
        }
        (DOT
            ((method_name=ID LPAREN mcparam=method_call_param RPAREN)
            {

                $tmp_mc = new MethodCall($new_array_class_expr, new Identifier($method_name.text));
                for (Expression epx : $mcparam.exprs)
                    $tmp_mc.addArg(epx);
                $tmp_mc.line = $new_array_class_expr.line;
                $tmp_mc.col = $method_name.getCharPositionInLine();
                $new_array_class_expr = $tmp_mc;
            }
            |
            id=ID
            {
                $new_array_class_expr = new FieldCall($new_array_class_expr, new Identifier($id.text));
            }
            |
            id=ID new_brack=new_bracket
            {
                $new_array_class_expr = new FieldCall($new_array_class_expr, new Identifier($id.text));
                $new_array_class_expr = new ArrayCall($new_array_class_expr, $new_brack.expr);
            })
        )*

    ;

dot_expression_with_method_call returns [Expression expr] locals [MethodCall tmp_mc]
    :
        methodc=method_call
        (
            (
                (DOT
                    (
                        (method_name=ID LPAREN mcparam=method_call_param RPAREN)
                        {
                            if($expr == null)
                                $tmp_mc = new MethodCall($methodc.mc, new Identifier($method_name.text));
                            else
                                $tmp_mc = new MethodCall($expr, new Identifier($method_name.text));
                            for (Expression epx : $mcparam.exprs)
                                $tmp_mc.addArg(epx);
                            $tmp_mc.line = $methodc.mc.line;
                            $tmp_mc.col = $method_name.getCharPositionInLine();
                            $expr = $tmp_mc;
                        }
                    |
                        id=ID
                        {
                            if($expr == null)
                                $expr = new FieldCall($methodc.mc, new Identifier($id.text));
                            else
                                $expr = new FieldCall($expr, new Identifier($id.text));
                        }
                    )
                )
            |
                new_brack=new_bracket
                {
                    if($expr == null)
                        $expr = new ArrayCall($methodc.mc, $new_brack.expr);
                    else
                        $expr = new ArrayCall($expr, $new_brack.expr);
                }
            )
        )+
    ;

method_call returns[Expression mc] locals[MethodCall tmp_mc]
    :   (nt+=NOT)* (ng+=MINUS)* (lv+=expression_without_method_call DOT)? method_name=ID LPAREN mcparam=method_call_param RPAREN
        {
            if($lv.size() != 0)
                $tmp_mc = new MethodCall($lv.get(0).expr, new Identifier($method_name.text));
            else $tmp_mc = new MethodCall(new Self(), new Identifier($method_name.text));
            $tmp_mc.line = $method_name.getLine();
            if($lv.size() != 0)
                $tmp_mc.col = $lv.get(0).expr.col;
            else $tmp_mc.col = $method_name.getCharPositionInLine();
            for (Expression epx : $mcparam.exprs)
                $tmp_mc.addArg(epx);
            $mc = $tmp_mc;
            for (int i = 0; i < $nt.size(); i++)
                $mc = new Not($mc);
            for (int i = 0; i < $ng.size(); i++)
                $mc = new Neg($mc);
        }
        mcr=method_call_recursion[$mc]
        {
            $mc = $mcr.mc;
        }
    ;

method_call_recursion [Expression bf_dot] returns [Expression mc] locals[MethodCall tmp_mc]
    :   DOT name=ID LPAREN mcparam=method_call_param RPAREN
        {
            $tmp_mc = new MethodCall(bf_dot, new Identifier($name.text));
            $tmp_mc.line = $name.getLine();
            $tmp_mc.col = $name.getCharPositionInLine();
            for (Expression epx : $mcparam.exprs)
                $tmp_mc.addArg(epx);
            $mc = $tmp_mc;
        }
        mcr=method_call_recursion[$mc]
        {
            $mc = $mcr.mc;
        }
        |
        {
            $mc = $bf_dot;
        }
    ;

boolean_mathematical_expression returns [Expression bmexpr]
    :   and1=andterm (OR and2+=expression)*
        {
            if($and2.size() == 0)
                $bmexpr = $and1.andexpr;
            else
            {
                $bmexpr = new Or($and1.andexpr, $and2.get(0).expr);
                for (int i = 1; i < $and2.size(); i++)
                    $bmexpr = new Or($bmexpr, $and2.get(i).expr);
                $bmexpr.line = $and1.andexpr.line;
                $bmexpr.col = $and1.andexpr.col;
            }
        }
    ;

andterm returns [Expression andexpr]
    :   comp1=compterm (AND comp2+=expression)*
        {
            if($comp2.size() == 0)
                $andexpr = $comp1.compexpr;
            else
            {
                $andexpr = new And($comp1.compexpr, $comp2.get(0).expr);
                for (int i = 1; i < $comp2.size(); i++)
                    $andexpr = new And($andexpr, $comp2.get(i).expr);
                $andexpr.line = $comp1.compexpr.line;
                $andexpr.col = $comp1.compexpr.col;
            }
        }
    ;

compterm returns [Expression compexpr]
    :   glt1=greaterlessthanterm ( op=(NOTEQUAL | EQUALS) glt2+=expression )?
        {
            if($glt2.size() == 0)
                $compexpr = $glt1.glexpr;
            else
            {
                if($op.text.equals( "<>" ))
                    $compexpr = new NotEquals($glt1.glexpr, $glt2.get(0).expr);
                else $compexpr = new Equals($glt1.glexpr, $glt2.get(0).expr);
                $compexpr.line = $glt1.glexpr.line;
                $compexpr.col = $glt1.glexpr.col;
            }

        }
    ;

greaterlessthanterm returns [Expression glexpr]
    :   add1=addition_expression ( op=(LESSTHAN | GREATERTHAN) add2+=expression )?
        {
            if($add2.size() == 0)
                $glexpr = $add1.plus;
            else
            {
                if($op.text.equals( "<" ))
                    $glexpr = new LessThan($add1.plus, $add2.get(0).expr);
                else $glexpr = new GreaterThan($add1.plus, $add2.get(0).expr);
                $glexpr.line = $add1.plus.line;
                $glexpr.col = $add1.plus.col;
            }
        }
    ;

addition_expression returns [Expression plus]
    :   exp1=mult_expression ( op+=(PLUS | MINUS) exp2+=expression)*
        {
            if($exp2.size() == 0)
                $plus = $exp1.bin;
            else
            {
                BinaryExpression tmp;
                if($op.get(0).getText().equals( "+" ))
                    tmp = new Plus($exp1.bin, $exp2.get(0).expr);
                else
                    tmp = new Minus($exp1.bin, $exp2.get(0).expr);
                tmp.line = $exp1.bin.line;
                tmp.col = $exp1.bin.col;
                for (int i = 1; i < $exp2.size(); i++)
                {
                    if($op.get(i).getText().equals( "+" ))
                        tmp = new Plus(tmp, $exp2.get(i).expr);
                    else
                        tmp = new Minus(tmp, $exp2.get(i).expr);
                    tmp.line = $exp1.bin.line;
                    tmp.col = $op.get(i).getCharPositionInLine();
                }
                $plus = tmp;
                $plus.line = $exp1.bin.line;
                $plus.col = $exp1.bin.col;
            }
        }
    ;

mult_expression returns [Expression bin]
    :   exp1=not_neg_expression ( op+=(TIMES | DIV | MOD) exp2+=expression )*
        {
            if($op.size() == 0)
                $bin = $exp1.uni;
            else
            {
                BinaryExpression tmp;
                if($op.get(0).getText().equals("/"))
                    tmp = new Division($exp1.uni, $exp2.get(0).expr);
                else if($op.get(0).getText().equals("*"))
                    tmp = new Times($exp1.uni, $exp2.get(0).expr);
                else
                    tmp = new Modulo($exp1.uni, $exp2.get(0).expr);

                for (int i = 1; i < $op.size(); i++)
                {
                    if($op.get(i).getText().equals("/"))
                        tmp = new Division(tmp, $exp2.get(i).expr);
                    else if($op.get(i).getText().equals("*"))
                        tmp = new Times(tmp, $exp2.get(i).expr);
                    else if($op.get(i).getText().equals("%"))
                        tmp = new Modulo(tmp, $exp2.get(i).expr);
                }
                $bin = tmp;
                $bin.line = $exp1.uni.line;
                $bin.col = $exp1.uni.col;
            }
        }
    ;

not_neg_expression returns [Expression uni]
    :   (nt+=NOT)+ fax1=field_array_expression
        {
            $uni = new Not($fax1.faexpr);
            for (int i = 1; i < $nt.size(); i++)
                $uni = new Not($uni);
        }
    |
        (mi+=MINUS)+ fax2=field_array_expression
        {
            $uni = new Neg($fax2.faexpr);
            for (int i = 1; i < $mi.size(); i++)
                $uni = new Neg($uni);
        }
    |
        fax3=field_array_expression
        {
            $uni = $fax3.faexpr;
        }
    ;

field_array_expression returns [Expression faexpr]
    :   expf1=expression_factor
        {
            $faexpr = $expf1.expr;
        }
    |
        cef=call_expression_factor (DOT id+=ID)+
        {
            $faexpr = new FieldCall($cef.expr, new Identifier($id.get(0).getText()));
            for (int i = 1; i < $id.size(); i++)
                $faexpr = new FieldCall($faexpr, new Identifier($id.get(i).getText()));
        }
    |
        expf2=expression_factor nwbrack=new_bracket
        {
            $faexpr = new ArrayCall($expf2.expr, $nwbrack.expr);
        }
    ;

call_expression_factor returns [Expression expr]
    :   num=NUMBER
        {
            $expr = new IntValue( Integer.valueOf($num.text) );
            $expr.line = $num.getLine();
            $expr.col = $num.getCharPositionInLine();
        }
    |
        t=TRUE
        {
            $expr = new BoolValue(true);
            $expr.line = $t.getLine();
            $expr.col = $t.getCharPositionInLine();
        }
    |
        f=FALSE
        {
            $expr = new BoolValue(false);
            $expr.line = $f.getLine();
            $expr.col = $f.getCharPositionInLine();
        }
//    |
//        n=NOT exp1=expression
//        {
//            $expr = new Not($exp1.expr);
//            $expr.line = $n.getLine();
//            $expr.col = $n.getCharPositionInLine();
//        }
//    |
//        m=MINUS exp2=expression
//        {
//            $expr = new Neg($exp2.expr);
//            $expr.line = $m.getLine();
//            $expr.col = $m.getCharPositionInLine();
//        }
    |
        str=STRING_LITERAL
        {
            $expr = new StringValue($str.text);
            $expr.line = $str.getLine();
            $expr.col = $str.getCharPositionInLine();
        }
    |
        sf=SELF
        {
            $expr = new Self();
            $expr.line = $sf.getLine();
            $expr.col = $sf.getCharPositionInLine();
        }
    |
        id=ID
        {
            $expr = new Identifier($id.text);
            $expr.line = $id.getLine();
            $expr.col = $id.getCharPositionInLine();
        }
    ;

expression_factor returns [Expression expr]
    :   lp=LPAREN exp3=expression RPAREN
        {
            $expr = $exp3.expr;
            $expr.col = $lp.getCharPositionInLine();
        }
    |
        cexprf=call_expression_factor
        {
            $expr = $cexprf.expr;
        }
    |
        LPAREN exp=expression RPAREN (DOT (id = ID | id2 = ID nw1=new_bracket))
        {
            if($id == null)
            {
                $expr = new FieldCall($exp.expr, new Identifier($id2.getText()));
                $expr = new ArrayCall($expr, $nw1.expr);
            }
            else
                $expr = new FieldCall($exp.expr, new Identifier($id.getText()));
        }
        (DOT
            (id3=ID | id4=ID nw2=new_bracket)
            {
                if($id3 == null)
                {
                    $expr = new FieldCall($expr, new Identifier($id4.getText()));
                    $expr = new ArrayCall($expr, $nw2.expr);
                }
                else
                    $expr = new FieldCall($expr, new Identifier($id3.getText()));
            }

        )*
    ;

increment returns [IncStatement inc]
    :   lv=expression PLUSPLUS SEMICOLON
        {
            $inc = new IncStatement($lv.expr);
            $inc.line = $lv.expr.line;
            $inc.col = $lv.expr.col;
        }
    ;

decrement returns [DecStatement dec]
    :   lv=expression MINUSMINUS SEMICOLON
        {
            $dec = new DecStatement($lv.expr);
            $dec.line = $lv.expr.line;
            $dec.col = $lv.expr.col;
        }
    ;

/*lvalue returns [Expression expr]
    :   lvs=lvalue_selfless
        {
            $expr = $lvs.expr;
        }
    |
        SELF (DOT lvalue_selfless)?
    |
        LPAREN lvalue RPAREN
    ;

lvalue_selfless returns [Expression expr]
    :
        lvalue_selfless_newless
    |
        NEW ID LPAREN RPAREN (DOT lvalue_selfless_newless)?
    ;

lvalue_selfless_newless [List<Expression> before_dot] returns [Expression expr, bool field_call, String field_name, Expression call_index] locals[List<Expression> bf_dot, Expression temp_expr]
    :   lva=lvalue_atom
        {
            if($lva.call_index == null)
            {
                $tmp_expr = new FieldCall($before_dot.get(0), $lva.field);
                $field_call = true;
            }
            else
            {
                $tmp_expr = new ArrayCall($before_dot.get(0), $lva.call_index);
                $field_call = false;
            }
            $bf_dot.add($tmp_expr);
        }(DOT lsn+=lvalue_selfless_newless[$bf_dot])?
        {
            if($before_dot == null)
                $before_dot.add(new Self);
            if($lsn == null)
                $expr = $tmp_expr;
            else
            {
                $field_call = $lsn.field_call;
                if($field_call == true)

            }
        }
    ;

lvalue_atom returns [String field, Expression call_index]
    :   name=ID (nwb+=new_bracket)?
        {
            if($nwb == null)
                $field = $name.text;
            else $call_index = $nwb.get(0).expr;
        }
    ;*/

field_definition returns[List<FieldDeclaration> field_decs]
    :   access_modifier fi=FIELD first_name=ID (COMMA other_names+=ID)* type (SEMICOLON)+
        {
            $field_decs = new ArrayList<FieldDeclaration>();
            if($access_modifier.access_mod.equals("auto"))
            {
                FieldDeclaration new_field = new FieldDeclaration(new Identifier($first_name.text), $type.typee);
                new_field.line = $fi.getLine();
                new_field.col = $fi.getCharPositionInLine();
                $field_decs.add(new_field);
            }
            else if($access_modifier.access_mod.equals("private") )
            {
                FieldDeclaration new_field = new FieldDeclaration(new Identifier($first_name.text), $type.typee, AccessModifier.ACCESS_MODIFIER_PRIVATE);
                new_field.line = $fi.getLine();
                new_field.col = $fi.getCharPositionInLine();
                $field_decs.add(new_field);
            }
            else
            {
                FieldDeclaration new_field = new FieldDeclaration(new Identifier($first_name.text), $type.typee, AccessModifier.ACCESS_MODIFIER_PUBLIC);
                new_field.line = $fi.getLine();
                new_field.col = $fi.getCharPositionInLine();
                $field_decs.add(new_field);
            }
            for (int i = 0; i < $other_names.size(); i++)
            {
                if($access_modifier.access_mod.equals("auto"))
                {
                    FieldDeclaration new_field = new FieldDeclaration(new Identifier($other_names.get(i).getText()), $type.typee);
                    new_field.line = $fi.getLine();
                    new_field.col = $fi.getCharPositionInLine();
                    $field_decs.add(new_field);
                }
                else if( $access_modifier.access_mod.equals("private") )
                {
                    FieldDeclaration new_field = new FieldDeclaration(new Identifier( $other_names.get(i).getText()), $type.typee, AccessModifier.ACCESS_MODIFIER_PRIVATE);
                    new_field.line = $fi.getLine();
                    new_field.col = $fi.getCharPositionInLine();
                    $field_decs.add(new_field);
                }
                else
                {
                    FieldDeclaration new_field = new FieldDeclaration(new Identifier($other_names.get(i).getText()), $type.typee, AccessModifier.ACCESS_MODIFIER_PUBLIC);
                    new_field.line = $fi.getLine();
                    new_field.col = $fi.getCharPositionInLine();
                    $field_decs.add(new_field);
                }
            }
        }
    ;

non_new_bracket
    :   LBRACKET RBRACKET
    ;

new_bracket returns [Expression expr]
    :   LBRACKET (exp=expression) RBRACKET
        {
            $expr = $exp.expr;
        }
    ;

single_type returns [String typee]
    :   type_name=( BOOL | STRING | INT | ID )
        {
            $typee = $type_name.text;
        }
    ;

type returns[Type typee] locals[SingleType tmpType]
    :   single_type (nnb+=non_new_bracket)?
        {
            if($single_type.typee.equals( "bool" ))
                $tmpType = new BoolType();
            else if($single_type.typee.equals("int"))
                $tmpType = new IntType();
            else if($single_type.typee.equals("string"))
                $tmpType = new StringType();
            else $tmpType = new UserDefinedType(new ClassDeclaration(new Identifier($single_type.typee)));
            if($nnb.size() != 0)
                $typee = new ArrayType($tmpType);
            else $typee = $tmpType;

        }
    ;

NUMBER : [1-9][0-9]* | [0] ;

DOT : '.';

NOT : '!';

OR : '||';

AND : '&&';

LESSTHAN : '<';

GREATERTHAN : '>';

NOTEQUAL : '<>';

EQUALS : '==';

LPAREN : '(';

RPAREN : ')';

LBRACKET : '[';

RBRACKET : ']';

MINUSMINUS : '--';

PLUSPLUS : '++';

MINUS : '-';

PLUS : '+';

TIMES : '*';

DIV : '/';

MOD : '%';

ASSIGN : '=';

COMMA : ',';

COLON : ':';

BOOL : 'bool';

STRING : 'string';

INT : 'int';

CLASS : 'class';

FUNCTION : 'function';

IF : 'if';

PRINT : 'print';

PRIVATE : 'private';

FIELD : 'field';

SELF : 'self';

FALSE : 'false';

TRUE : 'true';

WHILE : 'while';

ELSE : 'else';

NEW : 'new';

RETURNS : 'returns';

RETURN : 'return';

ELIF : 'elif';

BREAK : 'break';

CONTINUE : 'continue';

ENTRY : 'entry';

BEGIN : 'begin';

END : 'end';

PUBLIC : 'public';

VAR : 'var';

INHERITS : 'inherits';

ID : [a-zA-Z_] [a-zA-Z0-9_]* ;

SEMICOLON : ';';

STRING_LITERAL : '"' ~["]* '"';

WS: [ \r\t\n] -> skip;

COMMENT : '/*' .*? '*/'  -> skip;

LINE_COMMENT : '//' ~[\r\n]* -> skip;

CHAR : [a-zA-Z0-9] | [_!@#$%^&*()+/.?<>~:;|] | '\\' | '/' | '-' | [ ];