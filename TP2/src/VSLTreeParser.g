tree grammar VSLTreeParser;

options {
  language     = Java;
  tokenVocab   = VSLParser;
  ASTLabelType = CommonTree;
}

@header {
  import java.util.List;
  import java.util.LinkedList;
}

/* Beginning of the parsing */
s returns [Code3a code] // The symbol table is synthetized here and not inherited
  : ^(PROG {code = new Code3a(); SymbolTable symTab = new SymbolTable(); } (e=unit[symTab] {code.append($e.code);})+)
  ;

/* Base unit of the program : function or prototype */
unit [SymbolTable symTab] returns [Code3a code]
  : ^(PROTO_KW type IDENT e=param_list[symTab])
    {
      FunctionType ft = new FunctionType($type.ty, true);
      for(int i = 0; i < $e.lty.size(); i++)
        ft.extend($e.lty.get(i));
      symTab.insert($IDENT.text, new FunctionSymbol(new LabelSymbol($IDENT.text), ft));
    }

  | ^(FUNC_KW type IDENT e=param_list[symTab]
    {
      // TODO, as for everything else we'll have to check the type of arguments <= But the type of the arguments is not specified, is it always INT or can it be TAB ?
      // TODO, a function might not have been prototyped <= this is only a problem if it is used before its definition
      code = new Code3a();
      FunctionType ft = new FunctionType($type.ty, false);
      LabelSymbol funLabel = new LabelSymbol($IDENT.text);

      // Insert the function into the symTab
      for(int i = 0; i < $e.lty.size(); i++)
        ft.extend($e.lty.get(i));
      symTab.insert($IDENT.text, new FunctionSymbol(funLabel, ft));

      // Prints the label and the begining of the function
      code.append(Code3aGenerator.genBeginfunc(funLabel));

      // Create a new scope for the funtion definition
      symTab.enterScope();

      // Add the parameters to the new scope and prints them
      for(int i = 0; i < $e.lnames.size(); i++) {
        symTab.insert($e.lnames.get(i), new VarSymbol($e.lty.get(i), $e.lnames.get(i), 1));
        code.append(Code3aGenerator.genVar(symTab.lookup($e.lnames.get(i))));
      }
    }
    ^(BODY statement[symTab]))
    {
      code.append($statement.code);
      //Leave the scope and the function
      symTab.leaveScope();
      code.append(Code3aGenerator.genEndfunc());
    }
  ;

/* Statement */
statement [SymbolTable symTab] returns [Code3a code]
  : ^(ASSIGN_KW e=expression[symTab] IDENT)
    {
      code = Code3aGenerator.genCopy(symTab.lookup($IDENT.text), e);
    }
  // TODO, array

  | ^(RETURN_KW e=expression[symTab])
    {
      code = Code3aGenerator.genRet(e.place);
    }

  /*| ^(PRINT_KW e1=print_list[symTab])*/
  /*  {                                */
  /*    code = e1;                     */
  /*  }                                */

  | ^(IF_KW {code = new Code3a();
            LabelSymbol tempL1 = SymbDistrib.newLabel();
            LabelSymbol tempL2 = SymbDistrib.newLabel();}
    e1=expression[symTab] {code.append(Code3aGenerator.genIfz(e1, tempL1));}
    e2=statement[symTab] {code.append(e2);
                          code.append(Code3aGenerator.genGoto(tempL2));
                          code.append(Code3aGenerator.genLabel(tempL1));}
    (e3=statement[symTab] {code.append(e3);})?  // TODO, use only 1 goto if there's no else
    {code.append(Code3aGenerator.genLabel(tempL2));})

  | ^(WHILE_KW {code = new Code3a();
                LabelSymbol tempL1 = SymbDistrib.newLabel();
                LabelSymbol tempL2 = SymbDistrib.newLabel();
                code.append(Code3aGenerator.genLabel(tempL1));}
    e1=expression[symTab] {code.append(Code3aGenerator.genIfz(e1, tempL2));}
    e2=statement[symTab] {code.append(e2);
                          code.append(Code3aGenerator.genGoto(tempL1));
                          code.append(Code3aGenerator.genLabel(tempL2));})

  | block[symTab] {code = $block.code;}
  ;


block [SymbolTable symTab] returns [Code3a code]
  : ^(BLOCK declaration[symTab] { symTab.enterScope(); } // Push a new symTable
    e=inst_list[symTab])
    {
      code = e;
      symTab.leaveScope(); // Pop the symTable
    }

  | ^(BLOCK  { symTab.enterScope(); } // Push a new symTable => We don't really need to do it here since there is no decl ?
    e=inst_list[symTab])
    {
      code = e;
      symTab.leaveScope(); // Pop the symTable
    }
  ;

inst_list [SymbolTable symTab] returns [Code3a code]
  : ^(INST {code = new Code3a();} (e=statement[symTab] {code.append(e);})+)
  ;

/* Expressions */
expression [SymbolTable symTab] returns [ExpAttribute expAtt]
  : ^(PLUS e1=expression[symTab] e2=expression[symTab])
    {
      Type ty = TypeCheck.checkBinOp(e1.type, e2.type);
      VarSymbol temp = SymbDistrib.newTemp();
      Code3a cod = Code3aGenerator.genBinOp(Inst3a.TAC.ADD, temp, e1, e2);
      expAtt = new ExpAttribute(ty, cod, temp);
    }

  | ^(MINUS e1=expression[symTab] e2=expression[symTab])
    {
      Type ty = TypeCheck.checkBinOp(e1.type, e2.type);
      VarSymbol temp = SymbDistrib.newTemp();
      Code3a cod = Code3aGenerator.genBinOp(Inst3a.TAC.SUB, temp, e1, e2);
      expAtt = new ExpAttribute(ty, cod, temp);
    }

  | ^(MUL e1=expression[symTab] e2=expression[symTab])
    {
      Type ty = TypeCheck.checkBinOp(e1.type, e2.type);
      VarSymbol temp = SymbDistrib.newTemp();
      Code3a cod = Code3aGenerator.genBinOp(Inst3a.TAC.MUL, temp, e1, e2);
      expAtt = new ExpAttribute(ty, cod, temp);
    }

  | ^(DIV e1=expression[symTab] e2=expression[symTab])
    {
      Type ty = TypeCheck.checkBinOp(e1.type, e2.type);
      VarSymbol temp = SymbDistrib.newTemp();
      Code3a cod = Code3aGenerator.genBinOp(Inst3a.TAC.DIV, temp, e1, e2);
      expAtt = new ExpAttribute(ty, cod, temp);
    }

  | pe=primary_exp[symTab]
    { expAtt = pe; }
  ;

primary_exp [SymbolTable symTab] returns [ExpAttribute expAtt]
  : INTEGER
    {
      ConstSymbol cs = new ConstSymbol(Integer.parseInt($INTEGER.text));
      expAtt = new ExpAttribute(Type.INT, new Code3a(), cs);
    }

  | IDENT
    {
      Operand3a id = symTab.lookup($IDENT.text);
      if (id == null) {
        // Error : Undeclared identifier
      }
      expAtt = new ExpAttribute(id.type, new Code3a(), id);
    }

  // TODO check if the function has been declared and if the type of the arguments matches with the declaration
  | ^(FCALL IDENT
    {
      Code3a code = new Code3a();
      Operand3a id = symTab.lookup($IDENT.text);
      if (id == null) {
        // Error : Undeclared function
      }
      FunctionType ft = new FunctionType(id.type);
    }
    (e=expression[symTab]
    {
      ft.extend(e.type);
      code.append(Code3aGenerator.genArg(e.place));
    })*)
    {
      // Check the args
      if (!ft.isCompatible(id.type)) {
        // Error : wrong arg
      }

      if(ft.getReturnType() != Type.VOID) {
        VarSymbol temp = SymbDistrib.newTemp();
        code.append(Code3aGenerator.genCall(temp, new ExpAttribute(id.type, new Code3a(), id)));
        expAtt = new ExpAttribute(id.type, code, temp);
      } else {
        code.append(Code3aGenerator.genCall(new ExpAttribute(id.type, new Code3a(), id)));
        // ExpAtt is null here !
      }
    }
  ;

/*print_list [SymbolTable symTab] returns [Code3a code]                                     */
/*    : e1=print_item[symTab] {code = e1;} (e2=print_item[symTab] {code.append(e2);})*      */
/*    ;                                                                                     */

/*print_item [SymbolTable symTab] returns [Code3a code]                                     */
/*    : TEXT                                                                                */
/*      {                                                                                   */
/*        code = new Code3a();                                                              */
/*        code.appendData(new Data3a($TEXT.text));                                          */
/*        Operand3a id = symTab.lookup("prints");                                           */
/*        code.append(Code3aGenerator.genCall(new ExpAttribute(id.type, new Code3a(), id)));*/
/*      }                                                                                   */
/*    | e=expression[symTab]                                                                */
/*      {                                                                                   */
/*        code = new Code3a();                                                              */
/*        code.appendData(new Data3a(e.toString()));                                        */
/*        Operand3a id = symTab.lookup("printn");                                           */
/*        code.append(Code3aGenerator.genCall(new ExpAttribute(id.type, new Code3a(), id)));*/
/*      }                                                                                   */
/*    ;                                                                                     */

/* Parameters */
param_list [SymbolTable symTab] returns [List<Type> lty, List<String> lnames]  // TODO, check that params aren't in symTab? => If they are, they belong to a different scope
  // TODO, that's stupid to use lists right? => I don't see other possibilities
  : ^(PARAM {$lty = new LinkedList<Type>(); $lnames = new LinkedList<String>();}
    (e=param[symTab] {$lty.add($e.ty); $lnames.add($e.name);})*)
  ;

param [SymbolTable symTab] returns [Type ty, String name]
  : IDENT {$ty = Type.INT; $name = $IDENT.text;}
  | ^(ARRAY IDENT) {$ty = Type.POINTER; $name = $IDENT.text;}
  ;

/* Type */
type returns [Type ty]
  : INT_KW {ty = Type.INT;}
  | VOID_KW {ty = Type.VOID;}
  ;

/* Declarations */
declaration [SymbolTable symTab] returns [Code3a code]
  : ^(DECL {code = new Code3a();} (decl_item[symTab] {code.append($decl_item.code);})+)
  ;

decl_item [SymbolTable symTab] returns [Code3a code]
  : IDENT
    {
      symTab.insert($IDENT.text, new VarSymbol(Type.INT, $IDENT.text, symTab.getScope()));  // TODO, understand scope
      code = Code3aGenerator.genVar(symTab.lookup($IDENT.text));
    }
  /*| ^(ARDECL IDENT INTEGER) {}  // TODO, array declaration*/
  ;
