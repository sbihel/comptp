tree grammar Eval;

options {
    tokenVocab=Expr;
    ASTLabelType=CommonTree;
}

@header {
}

@members {
}

prog returns [String s]: stat+ {$s = $stat.s;};

stat returns [String s]: expr {$s = $expr.s;};

expr returns [String s]
	: ^(SUJETS a=expr)    {$s = "prout";}
	| ^(PREDICATS a=expr) {$s = "prout2";}
	| ^(OBJETS a=expr)    {$s = "prout3";}
	| Entite              {$s = "Entite"/*$Entite.text*/;}
	| Texte               {$s = "Texte"/*$Texte.text*/;}
	| EMPTY               {$s = "";}
	;
	/*| 
    :   ^('+' a=expr b=expr)  {$value = a+b;}
    |   ^('-' a=expr b=expr)  {$value = a-b;}
    |   ^('*' a=expr b=expr)  {$value = a*b;}
    |   ^('/' a=expr b=expr)  {$value = a/b;}
    |   ^('^' a=expr b=expr)  {$value = (int) Math.pow(a,b);}
    |   ID
        {
        Integer v = (Integer)memory.get($ID.text);
        if ( v!=null ) $value = v.intValue();
        else System.err.println("undefined variable "+$ID.text);
        }
    |   INT                   {$value = Integer.parseInt($INT.text);}
    *//*;*/

/*
document returns [String s]:
      list_sujet {$s = $list_sujet.s;};

list_sujet returns [String s]:
      * espilon * {$s = "";}
    | sujet list_sujetDA {$s = $sujet.s + $list_sujetDA.s;};

list_sujetDA returns [String s]:
      list_sujet {$s = $list_sujet.s;};

sujet returns [String s]:
      Entite list_predicat[$Entite.text] '.' {$s = $list_predicat.s;};

list_predicat [String h] returns [String s]:
      predicat[$h] list_predicatp[$h] {$s = $predicat.s + $list_predicatp.s;};

list_predicatp [String h] returns [String s]:
      * epsilon * {$s = "";}
    | ';' predicat[$h] list_predicatpDA[$h] {$s = $predicat.s + $list_predicatpDA.s;};

list_predicatpDA [String h] returns [String s]:
      list_predicatp[$h] {$s = $list_predicatp.s;};

predicat [String h] returns [String s]:
      Entite liste_obj[$h + " " + $Entite.text] {$s = $liste_obj.s;};

liste_obj [String h] returns [String s]:
      objet[$h] liste_objp[$h] {$s = $objet.s + $liste_objp.s;};

liste_objp [String h] returns [String s]:
      /* epsilon * {$s = "";}
    | ',' objet[$h] liste_objpDA[$h] {$s = $objet.s + $liste_objpDA.s;};

liste_objpDA [String h] returns [String s]:
      liste_objp[$h] {$s = $liste_objp.s;};

objet [String h] returns [String s]:
      Entite {$s = $h + " " + $Entite.text + " .\n";}
    | Texte {$s = $h + " " + $Texte.text + " .\n";}
    ;
*/