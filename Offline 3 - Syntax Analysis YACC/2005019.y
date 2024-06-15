
%{
#include<bits/stdc++.h>
#include <typeinfo>
#include "2005019.h"
//#define YYSTYPE symbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin; 

int line_count=1;
int err_count=0;
vector<symbolInfo*> varlist;
vector<symbolInfo*> paramlist;
vector<symbolInfo*> scopeVars;
vector<symbolInfo*> arglist;
ofstream logfile;
ofstream tokenfile;
ofstream parsefile;
ofstream errfile;

symbolTable *table = new symbolTable(11);
bool insideFunction;


void yyerror(char *s)
{
	//write your code
}

string generateParseText(string grammar,int sl, int el)
{
	string parse="";
	parse = grammar;
	parse+= " \t<Line: ";
	parse+= to_string(sl);
	parse+= "-";
	parse+= to_string(el);
	parse+= ">";

	return parse;
}

void parseTree(symbolInfo* root, int space)
{
	
	for(int i=0;i<space;i++)
	{ 
		parsefile<<" ";
	}
	parsefile<<root->getParseText()<<endl;
	

	if(root->leaf==true) 
	{
		return;
	}
	if(root->leaf==false)
	{
	for(symbolInfo* child: root->childList)
	{
		parseTree(child, space+1);
	}
	}
}

/**************************************ERROR**************************************/

string typeCasting(string type1, string type2)
{
	if(type1=="NULL" || type2 =="NULL") return "NULL";
	if(type1=="VOID" || type2=="VOID") return "error";

	if(type1=="INT" && type2=="INT") return "INT";
	if(type1=="INT" && type2=="FLOAT") return "FLOAT";
	if(type1=="FLOAT" && type2=="INT") return "FLOAT";
	if(type1=="FLOAT" && type2=="FLOAT") return "FLOAT";
	return "error";
}


bool match_assignop(string type1,string type2)
{
    if(type1== "NULL"||type2=="NULL") return true;
    if(type1=="VOID" ||type2=="VOID") return false;
    if(type1==""||type2=="") return false;
    if((type1=="INT") && (type2=="INT")) return true;
    if((type1=="FLOAT") && (type2=="FLOAT")) return true;
    return false;
}

void err_divide_mod_by_zero()
{
	errfile<<"Line# "<<line_count<<": Warning: division by zero i=0f=1Const=0"<<endl;
	err_count++;
}

void err_cast_mod()
{
	errfile<<"Line# "<<line_count<<": Operands of modulus must be integers "<<endl;
	err_count++;
}

void err_cast_void()
{
	errfile<<"Line# "<<line_count<<": Void cannot be used in expression "<<endl;
	err_count++;
}

void err_cast()
{
	errfile<<"Line# "<<line_count<<": Operands not compatible"<<endl;
	err_count++;
}

void err_cast_mismatch()
{
	errfile<<"Line# "<<line_count<<": Type mismatch in assignment"<<endl;
	err_count++;
}

void err_index_not_integer()
{
	errfile<<"Line# "<<line_count<<": Array subscript is not an integer"<<endl;
	err_count++;
}

void err_undeclared_var(string s)
{
	errfile<<"Line# "<<line_count<<": Undeclared variable '"<<s<<"'"<<endl;
	err_count++;
}

void err_undeclared_func(string s)
{
	errfile<<"Line# "<<line_count<<": Undeclared function '"<<s<<"'"<<endl;
	err_count++;
}

void err_param_redefined(string a)
{
	errfile<<"Line# "<<line_count<<": Redefinition of parameter '"<<a<<"'"<<endl;
	err_count++;	
}

void err_conflicting_return_type_in_definition(string a, int sl)
{
	errfile<<"Line# "<<sl<<": Conflicting types for '"<<a<<"'"<<endl;
	err_count++;
}

void err_redefined_different_type(string s, int line)
{
	errfile<<"Line# "<<line<<": '"<<s<<"' redeclared as different kind of symbol"<<endl;
	err_count++;
}

void err_conflicting_params_in_definition(string a, int sl)
{
	errfile<<"Line# "<<sl<<": Conflicting types for '"<<a<<"'"<<endl;
	err_count++;	
}

void err_field_declared_void(string s)
{
	errfile<<"Line# "<<line_count<<": Variable or field '"<<s<<"' declared void"<<endl;
	err_count++;
}

void err_conflicting_type_in_declaring_variables(string a)
{
	errfile<<"Line# "<<line_count<<": Conflicting types for'"<<a<<"'"<<endl;
	err_count++;
}

void err_redeclaration(string a)
{
	errfile<<"Line# "<<line_count<<": Redeclared variable! '"<<a<<"'"<<endl;
	err_count++;
}

void err_redeclared_function(string a)
{
	errfile<<"Line# "<<line_count<<": Redeclared Function! '"<<a<<"'"<<endl;
	err_count++;
}

void err_arg_type_mismatch(string a,int n)
{
	errfile<<"Line# "<<line_count<<": Type mismatch for argument "<<n<<" of '"<<a<<"'"<<endl;
	err_count++;
}

void err_too_few_args(string a)
{
	errfile<<"Line# "<<line_count<<": Too few arguments to function '"<<a<<"'"<<endl;
	err_count++;
	 
}

void err_too_many_args(string a)
{
	errfile<<"Line# "<<line_count<<": Too many arguments to function '"<<a<<"'"<<endl;
	err_count++;
}

void err_not_array(string a)
{
	errfile<<"Line# "<<line_count<<": '"<<a<<"' is not an array"<<endl;
	err_count++;
}

void warning_data_loss()
{
	errfile<<"Line# "<<line_count<<": Warning: possible loss of data in assignment of FLOAT to INT"<<endl;
	err_count++;
}

void err_array_index_missing(string a)
{
	errfile<<"Line# "<<line_count<<": '"<<a<<"' is an array. It needs indexing"<<endl;
	err_count++;
}

void err_func_arg_missing(string a)
{
	errfile<<"Line# "<<line_count<<": '"<<a<<"' is a function, not a variable"<<endl;
	err_count++;
}

/**************************************ERROR**************************************/

%}

%union{symbolInfo* symbol;}
%token<symbol> IF ELSE LOWER_ELSE FOR WHILE LPAREN RPAREN SEMICOLON COMMA LCURL RCURL LTHIRD RTHIRD PRINTLN RETURN ASSIGNOP NOT INCOP DECOP CHAR DOUBLE
%token<symbol> INT FLOAT VOID ID CONST_INT LOGICOP RELOP ADDOP MULOP CONST_FLOAT BITOP
%type <symbol> start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments


%nonassoc LOWER_ELSE
%nonassoc ELSE


%%

start : program
	{
		$$ = new symbolInfo($1->getName(),$1->getType());
		logfile<<"start : program"<<endl;
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("start : program",$$->sl,$$->el);
		$$->childList.push_back($1);
		parseTree($$,0);

	}
	;

program : program unit { 
	string text = $1->getName();
	text+= $2->getName();
	$$ = new symbolInfo(text,"dummy");
	logfile<<"program : program unit "<<endl;
	$$->sl = $1->sl;
	$$->el = $2->el;
	$$->parseText = generateParseText("program : program unit",$$->sl,$$->el);
	$$->childList.push_back($1);
	$$->childList.push_back($2);
	}
	| unit 
	{ 
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("program : unit",$$->sl,$$->el);
		logfile<<"program : unit "<<endl;
		$$->childList.push_back($1);
		}
	;
	
unit : var_declaration { 
	$$ = new symbolInfo($1->getName(),$1->getType());
	$$->sl = $1->sl;
	$$->el = $1->el;
	$$->parseText = generateParseText("unit : var_declaration",$$->sl,$$->el);
	logfile<<"unit : var_declaration "<<endl;
	$$->childList.push_back($1);

	}
    | func_declaration
	 {
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("unit : func_declaration",$$->sl, $$->el);
		logfile<<"unit : func_declaration "<<endl;
		$$->childList.push_back($1);

	 }
    | func_definition
	 {
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("unit : func_definition",$$->sl, $$->el);
		logfile<<"unit : func_definition"<<endl;
		$$->childList.push_back($1);

	 }
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			symbolInfo* func = new symbolInfo($2->getName(),"FUNCTION");
			func->setIsFunc(true);
			func->setParameter(paramlist);
			func->setReturnType(new symbolInfo($1->getType(),""));
			symbolInfo* predefined = table->lookup(func->getName());
						if(predefined!=nullptr)
						{
							if(predefined->getType()!=func->getType())
							{
								err_redefined_different_type(predefined->getName(),$2->sl);
							}
							else
							{
								err_redeclared_function(predefined->getName());
							}
						}
			table->insert(func);
			
			string text = $1->getType();
			text+= $2->getName();
			text+= "(";
			text+= $4->getName();
			text+= ");";
			$$ = new symbolInfo(text,"");
			$$->sl = $1->sl;
			$$->el = $6->el;
			$$->parseText = generateParseText("func_declaration :  type_specifier ID LPAREN parameter_list RPAREN SEMICOLON",$$->sl,$$->el);
			logfile<<"func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON "<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
				$$->childList.push_back($6);
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			symbolInfo* func = new symbolInfo($2->getName(),"FUNCTION");
			func->setIsFunc(true);
			
			func->setReturnType(new symbolInfo($1->getType(),""));
			symbolInfo* predefined = table->lookup(func->getName());
						if(predefined!=nullptr)
						{
							if(predefined->getType()!=func->getType())
							{
								err_redefined_different_type(predefined->getName(),$2->sl);
							}
							else
							{
								err_redeclared_function(predefined->getName());
							}
						}
			table->insert(func);

			string text = $1->getType();
			text+= $2->getName();
			text+= "();";
			$$ = new symbolInfo(text,"");
			$$->sl = $1->sl;
			$$->el = $5->el;
			$$->parseText = generateParseText("func_declaration :  type_specifier ID LPAREN RPAREN SEMICOLON",$$->sl,$$->el);
			logfile<<"func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
		{
			symbolInfo* predefined = table->lookup($2->getName());
			
			if(predefined!=nullptr)
			{
				
				if((predefined->getType())!="FUNCTION")
				{
					
					err_redefined_different_type(predefined->getName(),$2->sl);
				}
			}

			if(predefined!=nullptr && predefined->getIsFunc())
			{
				if((predefined->getReturnType())->getName()!=($1->getType()))
				{
					err_conflicting_return_type_in_definition($2->getName(),$1->sl);
				}

				if((predefined->getParams()).size()!=paramlist.size())
				{
					err_conflicting_params_in_definition($2->getName(),$1->sl);
				}
				else
				{
					vector<symbolInfo*> preParams = predefined->getParams();
					for(int i=0;i<paramlist.size();i++)
					{
						if(preParams[i]->getName()==paramlist[i]->getName() && preParams[i]->getType()==paramlist[i]->getType())
						{
							continue;
						}
						else err_conflicting_params_in_definition($2->getName(),$1->sl);
					}
				}
			}
			
			symbolInfo* func = new symbolInfo($2->getName(),"FUNCTION");
			func->setIsFunc(true);
			func->setParameter(paramlist);
			// have to check if the declared parameter list matches or not

			func->setReturnType(new symbolInfo($1->getType(),""));


			// have to insert the declared parameters in new scope

			table->enterScope();
			for(int i=0;i<scopeVars.size();i++)
				{
					
					symbolInfo* pre = table->lookupHere(scopeVars[i]->getName());
						if(pre!=nullptr)
						{
							if(pre->getType()!=scopeVars[i]->getType())
							{
								err_redefined_different_type(pre->getName(),$4->sl);
							}
						}
					table->insert(scopeVars[i]);
				}
			scopeVars.clear();
			for(int i=0;i<paramlist.size();i++)
				{
					symbolInfo* pre = table->lookupHere(paramlist[i]->getName());
						if(pre!=nullptr)
						{
							if(pre->getType()!=paramlist[i]->getType())
							{
								err_redefined_different_type(pre->getName(),$4->sl);
							}
						}
					table->insert(paramlist[i]);
				}
			
			table->printAll(logfile);
			table->exitScope();
			paramlist.clear();
			scopeVars.clear();
			if(!(func->getName()=="main")) table->insert(func);
			insideFunction=false;

			string text = $1->getType();
			text+= $2->getName();
			text+= "(";
			text+= $4->getName();
			text+= ")";
			text+= $6->getName();
			$$ = new symbolInfo(text,"");
			$$->sl = $1->sl;
			$$->el = $6->el;
			$$->parseText = generateParseText("func_definition :  type_specifier ID LPAREN parameter_list RPAREN compound_statement",$$->sl,$$->el);
			logfile<<"func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
				$$->childList.push_back($6);
		}
		| type_specifier ID LPAREN RPAREN compound_statement
		{
			symbolInfo* predefined = table->lookup($2->getName());
			

			if(predefined!=nullptr)
			{
				if((predefined->getType())!="FUNCTION")
				{
					err_redefined_different_type(predefined->getName(),$2->sl);
				}
			}

			if(predefined!=nullptr && predefined->getIsFunc())
			{
				// errfile<<(predefined->getReturnType())->getName();
				// errfile<<$1->getType();
				if((predefined->getReturnType())->getName()!=($1->getType()))
				{
					err_conflicting_return_type_in_definition($2->getName(),$1->sl);
				}
			}
			symbolInfo* func = new symbolInfo($2->getName(),"FUNCTION");
			func->setIsFunc(true);
			func->setReturnType(new symbolInfo($1->getType(),""));
			table->enterScope();
			for(int i=0;i<scopeVars.size();i++)
				{
					// errfile<<scopeVars[i]->getName()<<" "<<scopeVars[i]->getType()<<endl;
					// symbolInfo* pre = table->lookupHere(scopeVars[i]->getName());
					// 	if(pre!=nullptr)
					// 	{
					// 		if(pre->getType()!=scopeVars[i]->getType())
					// 		{
					// 			err_redefined_different_type(pre->getName());
					// 		}
					// 	}
					table->insert(scopeVars[i]);
				}
			table->printAll(logfile);
			table->exitScope();
			insideFunction=false;
			scopeVars.clear();
			if(!(func->getName()=="main")) table->insert(func);
			string text = $1->getType();
			text+= $2->getName();
			text+= "()";
			text+= $5->getName();
			$$ = new symbolInfo(text,"");
			$$->sl = $1->sl;
			$$->el = $5->el;
			$$->parseText = generateParseText("func_definition :  type_specifier ID LPAREN RPAREN compound_statement",$$->sl,$$->el);
			logfile<<"func_definition : type_specifier ID LPAREN RPAREN compound_statement"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
		}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
		{
			symbolInfo* p = new symbolInfo($4->getName(),$3->getType());
			bool exists = false;
			for(symbolInfo* a: paramlist)
			{
				if(a->getName()==p->getName()) 
				{
					err_param_redefined(a->getName());
					exists=true;
					break;
				}
			}
			if(!exists) paramlist.push_back(p);
			string text = $1->getName();
			text+= ",";
			text+= $3->getType();
			text+= $4->getName();
			$$ = new symbolInfo(text, "");
			$$->sl = $1->sl;
			$$->el = $4->el;
			$$->parseText = generateParseText("parameter_list  : parameter_list COMMA type_specifier ID", $$->sl,$$->el);

			logfile<<"parameter_list  : parameter_list COMMA type_specifier ID"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
		}
		| parameter_list COMMA type_specifier
		{
			symbolInfo* p = new symbolInfo("name",$3->getType());
			paramlist.push_back(p);
			string text = $1->getName();
			text+= ",";
			text+= $3->getType();
			$$ = new symbolInfo(text, "");
			$$->sl = $1->sl;
			$$->el = $3->el;
			$$->parseText = generateParseText("parameter_list  : parameter_list COMMA type_specifier", $$->sl,$$->el);
			
			logfile<<"parameter_list  : parameter_list COMMA type_specifier"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
		}
 		| type_specifier ID	{

			paramlist.clear();
			symbolInfo* p = new symbolInfo($2->getName(),$1->getType());
			paramlist.push_back(p);

			string text = $1->getType();
			text+= " ";
			text+= $2->getName();
			$$ = new symbolInfo(text, "");
			$$->sl = $1->sl;
			$$->el = $2->el;
			$$->parseText = generateParseText("parameter_list  : type_specifier ID", $$->sl,$$->el);
			
			logfile<<"parameter_list  : type_specifier ID"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);

		}
		| type_specifier	{

			paramlist.clear();
			symbolInfo* p = new symbolInfo("name",$1->getType());
			paramlist.push_back(p);
			string text = $1->getName();
			$$ = new symbolInfo(text, "");
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("parameter_list  : type_specifier", $$->sl,$$->el);
			
			logfile<<"parameter_list : type_specifier"<<endl;
			$$->childList.push_back($1);
		}
 		;

 		
compound_statement : LCURL statements RCURL
			{
				string text = "{";
				text+= $2->getName();
				text+= "}";

				$$ = new symbolInfo(text,"dummy");
				$$->sl = $1->sl;
				$$->el = $3->el;
				$$->parseText = generateParseText("compound_statement : LCURL statements RCURL",$$->sl,$$->el);
				logfile<<"compound_statement : LCURL statements RCURL"<<endl;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				
			}
 		    | LCURL RCURL
			{
				$$ = new symbolInfo("{}","dummy");
				$$->sl = $1->sl;
				$$->el = $2->el;
				$$->parseText = generateParseText("compound_statement : LCURL RCURL",$$->sl,$$->el);
				logfile<<"compound_statement : LCURL RCURL"<<endl;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
			}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
			{
				
				if($1->getType()=="VOID") 
				{
					for(int i=0;i<varlist.size();i++)
				{
					err_field_declared_void(varlist[i]->getName()); 
				}
				}
				else{
				for(int i=0;i<varlist.size();i++)
				{
					varlist[i]->setType($1->getType());
					bool entry = false;
					if(insideFunction)
					{
						for(int k=0;k<scopeVars.size();k++)
						{
							if(scopeVars[k]->getName()==varlist[i]->getName())
							{
								entry = true;
								if(scopeVars[k]->getType()!=varlist[i]->getType())
								{
									err_conflicting_type_in_declaring_variables(varlist[i]->getName());
								}
								else
								{
									err_redeclaration(varlist[i]->getName());
								}

							}
						}
						if(!entry) scopeVars.push_back(varlist[i]);
					}
					else 
					{
						symbolInfo* predefined = table->lookup(varlist[i]->getName());
						if(predefined!=nullptr)
						{
							if(predefined->getType()!=varlist[i]->getType())
							{
								err_conflicting_type_in_declaring_variables(predefined->getName());
							}
							else err_redeclaration(varlist[i]->getName());
						}
						table->insert(varlist[i]);
					}
				}
			}
				$$ = new symbolInfo("d","d");
				$$->sl = $1->sl;
				$$->el = $3->el;
				$$->parseText = generateParseText("var_declaration : type_specifier declaration_list SEMICOLON",$$->sl,$$->el);
				logfile<<"var_declaration : type_specifier declaration_list SEMICOLON  "<<endl;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
			}
 		 ;
 		 
type_specifier	: INT	{
		
		logfile<<"type_specifier	: INT "<<endl;
		
		$$ = new symbolInfo("type_specifier",$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("type_specifier	: INT",$$->sl,$$->el);
		$$->childList.push_back($1);

		}
 		| FLOAT			{
		
		logfile<<"type_specifier	: FLOAT "<<endl;
	
		$$ = new symbolInfo("type_specifier",$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("type_specifier	: FLOAT",$$->sl,$$->el);
		$$->childList.push_back($1);
		}

 		| VOID			{
		logfile<<"type_specifier	: VOID "<<endl;
		
		$$ = new symbolInfo("type_specifier",$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("type_specifier	: VOID",$$->sl,$$->el);
		$$->childList.push_back($1);
		}
 		;
 		
declaration_list : declaration_list COMMA ID 
			{
			logfile<<"declaration_list : declaration_list COMMA ID  "<<endl;
			varlist.push_back($3);
			string text = $1->getName();
			text+= ",";
			text+= $3->getName();
			$$ = new symbolInfo("dd","dd");
			$$->sl = $1->sl;
			$$->el = $3->el;
			$$->parseText = generateParseText("declaration_list : declaration_list COMMA ID",$$->sl,$$->el);
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
			}

 		| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
			symbolInfo* s = $3;
			s->setIsArray(1);
			s->setArrLen(stoi($5->getName()));
			varlist.push_back(s);
			$$ = new symbolInfo("dumm","dumm");
			$$->sl = $1->sl;
			$$->el = $3->el;
			$$->parseText = generateParseText("declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE",$$->sl,$$->el);
			logfile<<"declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE "<<endl;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
			$$->childList.push_back($4);
			$$->childList.push_back($5);
			$$->childList.push_back($6);
		  	}

 		| ID	{
			varlist.clear();
			varlist.push_back($1);
			$$ = new symbolInfo("dumm","dumm");
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("declaration_list : ID",$$->sl,$$->el);
			logfile<<"declaration_list : ID "<<endl;
			$$->childList.push_back($1);
			}
 		| ID LTHIRD CONST_INT RTHIRD {
			varlist.clear();
			symbolInfo* s = $1;
			s->setIsArray(1);
			s->setArrLen(stoi($3->getName()));
			varlist.push_back(s);
			$$ = new symbolInfo("dumm","dumm");
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("declaration_list : ID LSQUARE CONST_INT RSQUARE",$$->sl,$$->el);
			logfile<<"declaration_list : ID LSQUARE CONST_INT RSQUARE"<<endl;
			
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
			$$->childList.push_back($4);
		  }
 		;
 		  
statements : statement
		{
			$$ = new symbolInfo($1->getName(),$1->getType());
			logfile<<"statements : statement "<<endl;
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("statements : statement",$$->sl,$$->el);
			$$->childList.push_back($1);
				
		}
	   | statements statement
	   {
			string text = $1->getName();
			text+="\n";
			text+=$2->getName();
		    $$ = new symbolInfo(text,$1->getType());
			$$->sl = $1->sl;
			$$->el = $2->el;
			$$->parseText = generateParseText("statements : statements statement",$$->sl,$$->el);
			logfile<<"statements : statements statement"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
			
	   }
	   ;
	   
statement : var_declaration
		{
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("statement : var_declaration",$$->sl,$$->el);
			logfile<<"statement : var_declaration "<<endl;
			$$->childList.push_back($1);
			
		}
	  | expression_statement
	  	{
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("statement : expression_statement",$$->sl,$$->el);
			logfile<<"statement : expression_statement "<<endl;
			$$->childList.push_back($1);
			
	  	}
	  | compound_statement
	  	{
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("statement : compound_statement",$$->sl,$$->el);
			logfile<<"statement : compound_statement "<<endl;
			$$->childList.push_back($1);
			
	  	}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  	{
			string text = "for";
			text+= "(";
			text+= $3->getName();
			text+= $4->getName();
			text+= $5->getName();
			text+= ")";
			text+= $7->getName();
			
			$$ = new symbolInfo(text, $7->getType());
			$$->sl = $1->sl;
			$$->el = $7->el;
			$$->parseText = generateParseText("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement",$$->sl,$$->el);
			logfile<<"statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
				$$->childList.push_back($6);
				$$->childList.push_back($7);
			
		}
	  | IF LPAREN expression RPAREN statement %prec LOWER_ELSE
	  {
		string text = "if";
		text+= "(";
		text+= $3->getName();
		text+= ")";
		text+= $5->getName();

		$$ = new symbolInfo(text, $5->getType());

		$$->sl = $1->sl;
		$$->el = $5->el;
		$$->parseText = generateParseText("statement : IF LPAREN expression RPAREN statement",$$->sl,$$->el);
		logfile<<"statement : IF LPAREN expression RPAREN statement"<<endl;
		$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
				
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
		string text = "if";
		text+= "(";
		text+= $3->getName();
		text+= ")";
		text+= $5->getName();
		text+= "else";
		text+= $7->getName();

		$$ = new symbolInfo(text, $5->getType());
		$$->sl = $1->sl;
		$$->el = $7->el;
		$$->parseText = generateParseText("statement : IF LPAREN expression RPAREN statement ELSE statement",$$->sl,$$->el);
		logfile<<"statement : IF LPAREN expression RPAREN statement ELSE statement"<<endl;
		$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
				$$->childList.push_back($6);
				$$->childList.push_back($7);
				

	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
		string text = "while";
		text+= "(";
		text+= $3->getName();
		text+= ")";
		text+= $5->getName();

		$$ = new symbolInfo(text, $5->getType());
		$$->sl = $1->sl;
		$$->el = $5->el;
		$$->parseText = generateParseText("statement : WHILE LPAREN expression RPAREN statement",$$->sl,$$->el);
		logfile<<"statement : WHILE LPAREN expression RPAREN statement"<<endl;
		$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
				
		
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		string text = "printf";
		text+= "(";
		text+= $3->getName();
		text+= ")";
		text+= ";";
		$$ = new symbolInfo(text, $3->getType());
		$$->sl = $1->sl;
		$$->el = $5->el;
		$$->parseText = generateParseText("statement : PRINTLN LPAREN ID RPAREN SEMICOLON",$$->sl,$$->el);
		logfile<<"statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<endl;
		$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
				

	  }
	  | RETURN expression SEMICOLON
	  {
		string text = "return";
		text+= $2->getName();
		text+=";";

		$$ = new symbolInfo(text, $2->getType());
		$$->sl = $1->sl;
		$$->el = $3->el;
		$$->parseText = generateParseText("statement : RETURN expression SEMICOLON",$$->sl,$$->el);
		logfile<<"statement : RETURN expression SEMICOLON"<<endl;
		$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
	  }
	  ;
	  
expression_statement 	: SEMICOLON	
			{
				$$ = new symbolInfo(";","SEMICOLON");
				$$->sl = $1->sl;
				$$->el = $1->el;
				$$->parseText = generateParseText("expression_statement 	: SEMICOLON	",$$->sl,$$->el);
				logfile<<"expression_statement 	: SEMICOLON"<<endl;
				$$->childList.push_back($1);
				
			}		
			| expression SEMICOLON{
				$$ = new symbolInfo($1->getName()+";",$1->getType());
				$$->sl = $1->sl;
				$$->el = $2->el;
				$$->parseText = generateParseText("expression_statement 	: expression SEMICOLON",$$->sl,$$->el);
				logfile<<"expression_statement 	: expression SEMICOLON"<<endl;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				
			}
			;
	  
variable : ID 
	 {
		symbolInfo* s=nullptr;
		if(!insideFunction) s = table->lookup($1->getName());

		else
		{
			if(paramlist.size()!=0)
			{
			for(int i=0;i<paramlist.size();i++)
			{
				if(paramlist[i]->getName()==$1->getName()) s=paramlist[i];
			}
			}
			if(s==nullptr)
			{
				for(symbolInfo* sc: scopeVars)
				{
					if(sc->getName()==$1->getName()) s=sc;
				}

				if(s==nullptr)
				{
					s = table->lookup($1->getName());
				}
			}
			
		}
		
		string type="";
		if(s==nullptr) 
		{
			err_undeclared_var($1->getName());
			type="NULL";
		}
		else
		{ type= s->getType();

		if(s->getIsArray())
		{
			err_array_index_missing(s->getName());
		}
		else if(s->getIsFunc())
		{
			err_func_arg_missing(s->getName());
		}
		}

		$$ = new symbolInfo($1->getName(),type);
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("variable : ID",$$->sl,$$->el);
		logfile<<"variable : ID	"<<endl;
		$$->childList.push_back($1);
	 }		
	 | ID LTHIRD expression RTHIRD 
	 {
		string text = $1->getName();
		text+= "[";
		text+= $3->getName();
		text+= "]";
		string type="";


		symbolInfo* s = nullptr;
		if(insideFunction)
		{
			for(int i=0;i<scopeVars.size();i++)
			{
				if(scopeVars[i]->getName()==$1->getName()) 
				{
					s = scopeVars[i];
					break;
				}
				if(paramlist[i]->getName()==$1->getName())
				{
					s=paramlist[i];
					break;
				}
				
			}
		}
		else s=table->lookup($1->getName());
		if(s==nullptr) 
		{
			err_undeclared_var($1->getName());
			type="NULL";
		}

		else if(!s->getIsArray())
		{
			err_not_array(s->getName());
			type=s->getType();
		}
		else if($3->getType()!="INT")
		{
			err_index_not_integer();
			type="NULL";
		}
		
		else type= s->getType();

		/*int index = stoi($3->getName());
		if($1->getIsArray())
		{
			$$ = $1->getElementAtIndex(index);
		}*/
		 

		$$ = new symbolInfo(text,type);
		$$->sl = $1->sl;
		$$->el = $4->el;
		$$->parseText = generateParseText("variable : ID LSQUARE expression RSQUARE",$$->sl,$$->el);
		logfile<<"variable	: ID LSQUARE expression RSQUARE"<<endl;
		$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				

	 }
	 ;
	 
expression : logic_expression	
		{
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("expression : logic_expression",$$->sl,$$->el);
			logfile<<"expression	: logic_expression "<<endl;
			$$->childList.push_back($1);

		}
	   | variable ASSIGNOP logic_expression
	   {
			string text = $1->getName();
			text+= "=";
			text+= $3->getName();

			
			if(!match_assignop($1->getType(),$3->getType()))
            {
				
                if($1->getType()=="VOID"||$3->getType()=="VOID")
                {
                    err_cast_void();
                }
				else if($1->getType()=="INT" && $3->getType()=="FLOAT")
				{
					warning_data_loss();
				}
				else if($3->getType()==""){}
				else
				{
					err_cast_mismatch();
				}
            }

			$$ = new symbolInfo(text, $1->getType());
			$$->sl = $1->sl;
			$$->el = $3->el;
			$$->parseText = generateParseText("expression : variable ASSIGNOP logic_expression",$$->sl,$$->el);
			logfile<<"expression : variable ASSIGNOP logic_expression"<<endl;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);

			// have to check type error
	   } 	
	   ;
			
logic_expression : rel_expression 
		{
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("logic_expression : rel_expression ",$$->sl,$$->el);
			logfile<<"logic_expression : rel_expression "<<endl;
			$$->childList.push_back($1);

		}	
		 | rel_expression LOGICOP rel_expression 	
		 {
			string text = $1->getName();
			text+= $2->getName();
			text+= $3->getName();
			
			string type = typeCasting($1->getType(),$3->getType());
			
			if(type!="error" && type!="NULL")	type="INT";
			if(type=="error")
			{
				if($1->getType()=="VOID" || $3->getType()=="VOID")
				{
					err_cast_void();
					type="NULL";
				}
				else 
				{
					err_cast();
					type="NULL";
				}
			}
			$$ = new symbolInfo(text, type);
			$$->sl = $1->sl;
			$$->el = $3->el;
			$$->parseText = generateParseText("logic_expression : rel_expression LOGICOP rel_expression ",$$->sl,$$->el);
			logfile<<"logic_expression : rel_expression LOGICOP rel_expression"<<endl;
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
		 }
		 ;
			
rel_expression	: simple_expression 
		{
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("rel_expression : simple_expression ",$$->sl,$$->el);
			logfile<<"rel_expression : simple_expression "<<endl;
			$$->childList.push_back($1);

		}
		| simple_expression RELOP simple_expression	
		{
			string text = $1->getName();
			text+= $2->getName();
			text+= $3->getName();

			string type = typeCasting($1->getType(),$3->getType());
			
			if(type!="error" && type!="NULL")	type="INT";
			if(type=="error")
			{
				if($1->getType()=="VOID" || $3->getType()=="VOID")
				{
					err_cast_void();
					type="NULL";
				}
				else 
				{
					err_cast();
					type="NULL";
				}
			}
			$$ = new symbolInfo(text, type);
			$$->sl = $1->sl;
			$$->el = $3->el;
			$$->parseText = generateParseText("rel_expression : simple_expression RELOP simple_expression",$$->sl,$$->el);
			logfile<<"rel_expression	: simple_expression RELOP simple_expression"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
		}
		;
				
simple_expression : term 
		  {
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("simple_expression : term ",$$->sl,$$->el);
			logfile<<"simple_expression : term "<<endl;
			$$->childList.push_back($1);

		  }
		  | simple_expression ADDOP term 
		  {
			string text = $1->getName();
			text+= $2->getName();
			text+= $3->getName();

			string type = typeCasting($1->getType(),$3->getType());
		
			if(type=="error")
			{
				if($1->getType()=="VOID" || $3->getType()=="VOID")
				{
					err_cast_void();
					type="NULL";
				}
				else 
				{
					err_cast();
					type="NULL";
				}
			}

			$$ = new symbolInfo(text, type);
			$$->sl = $1->sl;
			$$->el = $3->el;
			$$->parseText = generateParseText("simple_expression : simple_expression ADDOP term",$$->sl,$$->el);
			logfile<<"simple_expression : simple_expression ADDOP term "<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
		// have to handle typecasting here
		  }
		  ;
					
term :	unary_expression
	{
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("term : unary_expression",$$->sl,$$->el);
		logfile<<"term :	unary_expression"<<endl;
		$$->childList.push_back($1);
	
	}
     |  term MULOP unary_expression
	 {
		string text = $1->getName();
		text+= $2->getName();
		text+= $3->getName();

		string type = typeCasting($1->getType(),$3->getType());
		
			if($2->getName()=="/" || $2->getName()=="%" )
			{
				if($3->getName()=="0")
				{
					err_divide_mod_by_zero();
					type="NULL";
				}
				else if($2->getName()=="%" && type!="INT")
				{
				err_cast_mod();
				type = "NULL";
				}
			}
		
			
			else if(type=="error")
			{
				if($1->getType()=="VOID" || $3->getType()=="VOID")
				{
					err_cast_void();
					type="NULL";
				}
				else 
				{
					err_cast();
					type="NULL";
				}
			}
		

		$$ = new symbolInfo(text, type);
		$$->sl = $1->sl;
		$$->el = $3->el;
		$$->parseText = generateParseText("term : term MULOP unary_expression ",$$->sl,$$->el);
		logfile<<"term :	term MULOP unary_expression"<<endl;
		$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
		// have to handle typecasting here
	 }
     ;

unary_expression : ADDOP unary_expression  
		 {
			$$ = new symbolInfo($1->getName()+$2->getName(),$2->getType());
			$$->sl = $2->sl;
			$$->el = $2->el;
			$$->parseText = generateParseText("unary_expression : ADDOP unary_expression",$$->sl,$$->el);
			logfile<<"unary_expression : ADDOP unary_expression"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
			
		 }
		 | NOT unary_expression 
		 {
			$$ = new symbolInfo("!"+($2->getName()),$2->getType());
			$$->sl = $2->sl;
			$$->el = $2->el;
			$$->parseText = generateParseText("logic_expression : rel_expression ",$$->sl,$$->el);
			logfile<<"unary_expression	: NOT unary_expression"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				

		 } 
		 | factor {
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("unary_expression : factor ",$$->sl,$$->el);
			logfile<<"unary_expression : factor "<<endl;	
			$$->childList.push_back($1);
			
		 }
		 ;
	
factor	: variable 
		{
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("factor : variable ",$$->sl,$$->el);
		logfile<<"factor	 : variable"<<endl;
		$$->childList.push_back($1);
		}
	| ID LPAREN argument_list RPAREN
		{
			symbolInfo* callee = table->lookupHere($1->getName());
			if(callee!=nullptr && callee->getIsFunc())
			{
				vector<symbolInfo*> plist = callee->getParams();
				if(arglist.size()<plist.size())
				{		err_too_few_args($1->getName()); }
				else if(arglist.size()>plist.size())
				{
					err_too_many_args($1->getName());
				}
				else{
					for(int i=0;i<arglist.size();i++)
					{
						if(arglist[i]->getType()!=plist[i]->getType())
						{
							err_arg_type_mismatch($1->getName(),i+1);
						}
					}
				}
			}
		string text = $1->getName();
		text+= "(";
		text+= $3->getName();
		text+= ")";
		string type="";
		symbolInfo* f = table->lookup($1->getName());
		if(f==nullptr) err_undeclared_func($1->getName());
		else if(f->getIsFunc()) 
		{
			type=(f->getReturnType())->getName();
		}
		$$ = new symbolInfo(text,type);
		$$->sl = $1->sl;
		$$->el = $4->el;
		$$->parseText = generateParseText("factor : ID LPAREN argument_list RPAREN ",$$->sl,$$->el);
		logfile<<"factor : ID LPAREN argument_list RPAREN"<<endl;
		$$->childList.push_back($1);
		$$->childList.push_back($2);
		$$->childList.push_back($3);
		$$->childList.push_back($4);
		
		}
	| LPAREN expression RPAREN
		{
		string text = "(";
		text+= $2->getName();
		text+= ")";
		$$ = new symbolInfo(text, $2->getType());
		$$->sl = $1->sl;
		$$->el = $3->el;
		$$->parseText = generateParseText("factor : LPAREN expression RPAREN ",$$->sl,$$->el);
		logfile<<"factor : LPAREN expression RPAREN"<<endl;
		$$->childList.push_back($1);
		$$->childList.push_back($2);
		$$->childList.push_back($3);
		}
	| CONST_INT
		{
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("factor : CONST_INT",$$->sl,$$->el);
		logfile<<"factor	: CONST_INT	"<<endl;
		$$->childList.push_back($1);
	
		} 
	| CONST_FLOAT
		{
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("factor : CONST_FLOAT",$$->sl,$$->el);
		logfile<<"factor	: CONST_FLOAT"<<endl;
		$$->childList.push_back($1);
		}
	| variable INCOP 
		{
		$$ = new symbolInfo($1->getName()+"++",$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("factor : variable INCOP",$$->sl,$$->el);
		logfile<<"factor : variable INCOP"<<endl;
		$$->childList.push_back($1);
		$$->childList.push_back($2);
				
		}
	| variable DECOP
		{
		$$ = new symbolInfo($1->getName()+"--",$1->getType());
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("factor : variable DECOP",$$->sl,$$->el);
		logfile<<"factor	: variable DECOP"<<endl;
		$$->childList.push_back($1);
		$$->childList.push_back($2);
		
		}
	;
	
argument_list : arguments
				{
					$$ = new symbolInfo($1->getName(),$1->getType());
					$$->sl = $1->sl;
					$$->el = $1->el;
					$$->parseText = generateParseText("argument_list : arguments",$$->sl,$$->el);
					logfile<<"argument_list : arguments"<<endl;
					$$->childList.push_back($1);

				}
			  |{
				$$ = new symbolInfo("","");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
			{
				symbolInfo* a = new symbolInfo($3->getName(),$3->getType());
				arglist.push_back(a);
				string text= $1->getName();
				text+=",";
				text+= $3->getName();
				$$ = new symbolInfo(text,$1->getType());
				$$->sl = $1->sl;
				$$->el = $3->el;
				$$->parseText = generateParseText("arguments : arguments COMMA logic_expression",$$->sl,$$->el);
				logfile<<"arguments : arguments COMMA logic_expression"<<endl;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
			}
	      | logic_expression
		  {
			arglist.clear();
			symbolInfo* a = new symbolInfo($1->getName(),$1->getType());
			arglist.push_back(a);
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("arguments : logic_expression",$$->sl,$$->el);
			logfile<<"arguments : logic_expression"<<endl;
			$$->childList.push_back($1);
		  }
	      ;
 

%%

void clearAndDeleteSymbolInfoVector(std::vector<symbolInfo*>& vec) {
    for (symbolInfo* info : vec) {
        delete info;
    }
    vec.clear();
}

int main(int argc,char *argv[])
{

		if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logfile.open("2005019_log.txt");
	tokenfile.open("2005019_token.txt");
	parsefile.open("2005019_parsetree.txt");
	errfile.open("2005019_error.txt");

	yyin= fin;
	yyparse();
	logfile<<"Total lines: "<<line_count<<endl;
	logfile<<"Total errors: "<<err_count<<endl;
	
	logfile.close();
	tokenfile.close();
	errfile.close();
	parsefile.close();
	fclose(yyin);
	table = nullptr;
	/* clearAndDeleteSymbolInfoVector(varlist);
	clearAndDeleteSymbolInfoVector(paramlist);
	clearAndDeleteSymbolInfoVector(scopeVars); */

	return 0;
}


