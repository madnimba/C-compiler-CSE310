
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
int label =1;
int whileLabels=1;
int forlabels=1;
int funclabels=1;
string funcName="";
vector<symbolInfo*> varlist;
vector<symbolInfo*> paramlist;
vector<symbolInfo*> scopeVars;
vector<symbolInfo*> arglist;
vector<symbolInfo*> globalVars;
vector<symbolInfo*> presentLocalVars;
symbolInfo* currentFunction=nullptr;
ofstream logfile;
ofstream tokenfile;
ofstream parsefile;
ofstream errfile;
ofstream codefile;
ofstream optfile;
ifstream pfile;
regex PushPop("(\tPUSH AX\n\tPOP AX\n)|(\tPUSH BX\n\tPOP BX\n)|(\tPUSH CX\n\tPOP CX\n)|(\tPUSH DX\n\tPOP DX\n)");
regex AddZero("ADD (AX|BX|CX|DX), 0");
regex MulOne("MUL (AX|BX|CX|DX), 1");

symbolTable *table = new symbolTable(11);
bool insideFunction;
bool insideSpecialCurls;
int SO=0;
int PO=0;

void asmTree(symbolInfo* root);
void assemblyGenerator(symbolInfo* node);



void optimization(ofstream &OriginalCodeFile)
{
	ifstream mainfile1("code.asm");
	ifstream mainfile2("code.asm");

	
	string line1,line2;
	getline(mainfile2,line2);
	line2 = regex_replace(line2,AddZero,"");
	line2 = regex_replace(line2,MulOne,"");
	while(getline(mainfile1,line1))
	{
		getline(mainfile2,line2);
		line1 = regex_replace(line1,PushPop,"");
		line1 = regex_replace(line1,AddZero,"");
		line2 = regex_replace(line2,PushPop,"");
		line2 = regex_replace(line2,AddZero,"");
		string temp= line1;
		string line = temp.append(line2);
		line = regex_replace(line,PushPop,"");
		if(line=="")
		{
			continue;
		}
		else optfile<<line1<<endl;
	}
	optfile<<"END main"<<endl;
}


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

string assign(string left, string right,int lineC)
{
	string st = "";
	st.append(right);  
	st.append("\tPOP AX") ;
	st.append("\n\tMOV ");
	st.append(left);
	st.append(", AX");
	st.append("\n\tPUSH AX\n\tPOP AX\n");
	return st;
}

string printLabel()
{
	string s= "L";
	s.append(to_string(label++));
	s.append(":\n");
	return s;
}

string whileLabel()
{
	string s= "WHILE";
	s.append(to_string(whileLabels++));
	return s;
}

string movFunc(string dst, string src, int lineC)
{
	string s = "\tMOV ";
	s.append(dst);
	s.append(", ");
	s.append(src);
	s.append("\t\t; Line ");
	s.append(to_string(lineC));
	s.append("\n");
	return s;
}

string pushFunc(string src)
{
	string s="\tPUSH ";
	s.append(src);
	s.append("\n");
	return s;
}


string printfunction(string p,int lineC)
{
	string s= "\tMOV AX, ";
	s.append(p);
	s.append("\t\t; Line ");
	s.append(to_string(lineC));
	s.append("\n\tCALL print_output\n");
	s.append("\tCALL new_line\n");
	
	return s;
}

string addop(string left, string op, string right, int lineC)
{
	string s = "";
	if(left.substr(0,4)!="\tMOV")
	{
		s.append("\tMOV AX, ");
		s.append(left);
		s.append("\n\tPUSH AX\n");
	}else s.append(left);

	if(right.substr(0,4)!="\tMOV")
	{
		s.append("\tMOV AX, ");
		s.append(right);
		s.append("\n\tPUSH AX\n");
	}else s.append(right);
	
	s.append("\tPOP DX\n\tPOP AX");
	if(op=="+")
	{
		s.append("\n\tADD AX, DX");
	}
	else s.append("\n\tSUB AX, DX");
	s.append("\n\tPUSH AX\n");
	return s;
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

string getFunctionLocalVariableName(symbolInfo* node, symbolInfo* funcNode)
{
	
	symbolInfo* s = nullptr;

		for(symbolInfo* var: funcNode->parameterVariableList)
		{
			if(var->getName()==node->getName())
			{
				s=var;
				string st = "[BP+";
				st.append(to_string(s->stackOffset));
				st.append("]");
				return st;
				break;
			}
		}
		if(s==nullptr)
		{
			for(symbolInfo* var: funcNode->localVariableList)
			{
				if(var->getName()==node->getName())
				{
					s=var;
					break;
				}
			}
		}
		if(s==nullptr)
		{
			s=table->lookup(node->getName());
		}
		
		if(s!=nullptr && !(s->isGlobal))
		{
			string st = "[BP-";
			st.append(to_string(s->stackOffset));
			st.append("]");
			return st;
		}
		else {
			return node->getName();
		}
}

string getNameforVariable(symbolInfo* variableNode)
{
	symbolInfo* s = nullptr;
		
			for(symbolInfo* var: presentLocalVars)
			{
				if(var->getName()==variableNode->getName())
				{
					s=var;
					break;
				}
			}
		if(s==nullptr)
		{
			s=table->lookup(variableNode->getName());
		}
		
		if(s!=nullptr && !(s->isGlobal))
		{
			string st = "[BP-";
			st.append(to_string(s->stackOffset));
			st.append("]");
			return st;
		}
		else {
			return variableNode->getName();
		}
}
bool checkIfGlobal(symbolInfo* node)
{
	for(int h=0;h<globalVars.size();h++)
		{
			if(node->getName()==globalVars[h]->getName())
			{
				return true;
			}
		}
	return false;
}
void prepareArray(symbolInfo* index,bool globalCheck)
{
	codefile<<"\tPUSH AX\n"; // assignment value
	asmTree(index);
	codefile<<"\tPOP BX\n";
	codefile<<"\tMOV AX, 2\n";
	//codefile<<"\tPUSH DX\n";
	codefile<<"\tMUL BX\n";
	//codefile<<"\tPOP DX\n";
	codefile<<"\tMOV BX, AX\n";
	
	if(!globalCheck)
	{
		codefile<<"\tMOV AX, ";
		codefile<<currentFunction->stackOffset;
		codefile<<"\n";
		codefile<<"\tSUB AX, BX\n";
		codefile<<"\tMOV SI, AX\n";
		codefile<<"\tNEG SI\n";

	}
	
}


void assemblyGenerator(symbolInfo* node)
{
	if(node->rule=="start : program")
	{
		
		codefile<<".MODEL SMALL\n.STACK 1000H\n.DATA\n\tnumber DB \"00000$\""<<endl;
			
			for(symbolInfo* var: globalVars){
				codefile<<'\t'<<var->getName()<<" DW 1 DUP (0000H)\n";
			}
			codefile<<".CODE"<<endl;
	}
	else if(node->rule=="program : program unit")
	{
		
	}
	else if(node->rule=="program : unit")
	{
		
	}
	else if(node->rule=="unit : var_declaration")
	{
		
	}
	else if(node->rule=="unit : func_declaration")
	{

	}
	else if(node->rule=="unit : func_definition")
	{

	}
	else if(node->rule=="func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON")
	{

	}
	else if(node->rule=="func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON")
	{

	}
	else if(node->rule=="func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement")
	{
			
		presentLocalVars.clear();
		presentLocalVars = node->localVariableList;
		codefile<<node->getName()<<" ";
		codefile<<" PROC\n";
		currentFunction = node;
		PO=4;
		asmTree(node->childList[3]);
			if(node->getName()=="main")
			{
				codefile<<"\tMOV AX, @DATA\n\tMOV DS, AX\n";
			}

		codefile<<("\tPUSH BP\n\tMOV BP,SP\n");
		int offset=0;
		for(int h=0;h<node->localVariableList.size();h++)
			{
				if(!(node->localVariableList[h]->getIsArray())) {codefile<<("\tSUB SP,2\n"); offset+=2;}
				else {codefile<<("\tSUB SP,");
				codefile<<to_string(node->localVariableList[h]->getArrLen()*2);
				offset+=node->localVariableList[h]->getArrLen()*2;
				codefile<<"\n";}

			}
		node->stackOffset = offset;
		asmTree(node->childList[5]);

		node->childList.clear();
		codefile<<"FUNCEND"<<funclabels<<":\n";
		funclabels++;
		codefile<<"\tADD SP,";
		codefile<<to_string(node->stackOffset);
		codefile<<"\n\tPOP BP\n";
		if(node->getName()=="main")
		{
			codefile<<"\tMOV AX, 4CH\n\tINT 21H\n";
		}
		else {
			codefile<<"\tRET ";
			codefile<<to_string(PO-4);
			codefile<<"\n";
		}
		codefile<<node->childList[1]->getName()<<" ENDP\n";
		currentFunction=nullptr;
	}
	else if(node->rule=="func_definition : type_specifier ID LPAREN RPAREN compound_statement")
	{
		presentLocalVars.clear();
		presentLocalVars = node->localVariableList;
		codefile<<node->getName()<<" ";
		codefile<<" PROC\n";
		currentFunction = node;
			if(node->getName()=="main")
			{
				codefile<<"\tMOV AX, @DATA\n\tMOV DS, AX\n";
			}
		codefile<<("\tPUSH BP\n\tMOV BP,SP\n");
		int offset=0;
		for(int h=0;h<node->localVariableList.size();h++)
			{
				if(!(node->localVariableList[h]->getIsArray())) {codefile<<("\tSUB SP,2\n"); offset+=2;}
				else {codefile<<("\tSUB SP,");
				codefile<<to_string(node->localVariableList[h]->getArrLen()*2);
				offset+=node->localVariableList[h]->getArrLen()*2;
				codefile<<"\n";}

			}
		node->stackOffset = offset;
		asmTree(node->childList[4]);
		node->childList.clear();
		codefile<<"FUNCEND"<<funclabels<<":\n";
		funclabels++;
		codefile<<"\tADD SP,";
		codefile<<to_string(node->stackOffset);
		codefile<<"\n\tPOP BP\n";
		if(node->getName()=="main")
		{
			codefile<<"\tMOV AX, 4CH\n\tINT 21H\n";
		}
		else codefile<<"\tRET\n";
		codefile<<node->childList[1]->getName()<<" ENDP\n";
		currentFunction=nullptr;

	}
	else if(node->rule=="parameter_list : parameter_list COMMA type_specifier ID")
	{
		symbolInfo* var = new symbolInfo(node->childList[3]->getName(),node->childList[2]->getType());
		var->stackOffset = PO;
		PO+=2;
		currentFunction->parameterVariableList.push_back(var);
		asmTree(node->childList[0]);
		node->childList.clear();
	}
	else if(node->rule=="parameter_list : parameter_list COMMA type_specifier")
	{

	}
	else if(node->rule=="parameter_list : type_specifier ID")
	{	
		symbolInfo* var = new symbolInfo(node->childList[1]->getName(),node->childList[0]->getType());
		var->stackOffset = PO;
		PO+=2;
		currentFunction->parameterVariableList.push_back(var);
		node->childList.clear();
		
	}
	else if(node->rule=="parameter_list : type_specifier")
	{

	}
	else if(node->rule=="compound_statement : LCURL statements RCURL")
	{

	}
	else if(node->rule=="compound_statement : LCURL RCURL")
	{

	}
	else if(node->rule=="var_declaration : type_specifier declaration_list SEMICOLON")
	{
		
	}
	else if(node->rule=="type_specifier : INT")
	{

	}
	else if(node->rule=="type_specifier : FLOAT")
	{

	}
	else if(node->rule=="type_specifier : VOID")
	{

	}
	else if(node->rule=="declaration_list : declaration_list COMMA ID")
	{

	}
	else if(node->rule=="declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD")
	{

	}
	else if(node->rule=="declaration_list : ID")
	{

	}
	else if(node->rule=="declaration_list : ID LTHIRD CONST_INT RTHIRD")
	{

	}
	else if(node->rule=="statements : statement")
	{

	}
	else if(node->rule=="statements : statements statement")
	{

	}
	else if(node->rule=="statement : var_declaration")
	{

	}
	else if(node->rule=="statement : expression_statement")
	{

	}
	else if(node->rule=="statement : compound_statement")
	{

	}
	else if(node->rule=="statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement")
	{
		asmTree(node->childList[2]);
		codefile<<"\tFORBEGIN"<<forlabels<<":\n";
		asmTree(node->childList[3]);
		codefile<<"\tPOP AX\n";
		codefile<<"\tCMP AX,0\n";
		codefile<<"\tJNE L"<<label<<"\n";
		codefile<<"\tJMP FOREND"<<forlabels+1<<"\n";
		asmTree(node->childList[6]);
		asmTree(node->childList[4]);
		codefile<<"\tJMP FORBEGIN"<<forlabels<<"\n";
		node->childList.clear();
		forlabels++;
		codefile<<"\tFOREND"<<forlabels<<":\n";

	}
	else if(node->rule=="statement : IF LPAREN expression RPAREN statement")
	{
		codefile<<printLabel();
		asmTree(node->childList[2]);
		codefile<<"\tPOP AX\n";
		codefile<<"\tCMP AX,0\n";
		codefile<<"\tJNE L"<<label<<"\n";
		codefile<<"\tJMP L"<<label+1<<"\n";
		asmTree(node->childList[4]);
		node->childList.clear();
	}
	else if(node->rule=="statement : IF LPAREN expression RPAREN statement ELSE statement")
	{
		codefile<<printLabel();
		asmTree(node->childList[2]);
		codefile<<"\tPOP AX\n";
		codefile<<"\tCMP AX,0\n";
		codefile<<"\tJNE L"<<label<<"\n";
		codefile<<"\tJMP L"<<label+1<<"\n";
		asmTree(node->childList[4]);
		codefile<<"\tJMP L"<<label+1<<"\n";
		asmTree(node->childList[6]);
		node->childList.clear();
	}
	else if(node->rule=="statement : WHILE LPAREN expression RPAREN statement")
	{
		string while_expression_start = whileLabel();
		codefile<<while_expression_start<<":\n";
		codefile<<printLabel();
		asmTree(node->childList[2]);
		codefile<<"\tPOP AX\n";
		codefile<<"\tCMP AX,0\n";
		codefile<<"\tJNE L"<<label<<"\n";
		string while_expression_end = whileLabel();
		codefile<<"\tJMP "<<while_expression_end<<"\n";
		asmTree(node->childList[4]);
		codefile<<"\tJMP "<<while_expression_start<<"\n";
		codefile<<while_expression_end<<":\n";
		node->childList.clear();
 
	}
	else if(node->rule=="statement : PRINTLN LPAREN ID RPAREN SEMICOLON")
	{
		codefile<<printLabel();
		string name = "";
		if(currentFunction!=nullptr)
		{
			name = getFunctionLocalVariableName(node->childList[2],currentFunction);
		}
		else name = getNameforVariable(node->childList[2]);
		codefile<<printfunction(name,node->childList[2]->sl);
		node->childList.clear();
	}
	else if(node->rule=="statement : RETURN expression SEMICOLON")
	{
		codefile<<printLabel();
		
		asmTree(node->childList[1]);
		codefile<<"\tPOP DX\n";
		codefile<<movFunc("AX","DX",node->childList[1]->sl);
		codefile<<"\tJMP FUNCEND"<<funclabels<<"\n";
		node->childList.clear();

	}
	else if(node->rule=="expression_statement : SEMICOLON")
	{

	}
	else if(node->rule=="expression_statement : expression SEMICOLON")
	{

	}
	else if(node->rule=="variable : ID")
	{
		string name = "";
		if(currentFunction!=nullptr)
		{
			name = getFunctionLocalVariableName(node->childList[0],currentFunction);
		}
		else name = getNameforVariable(node->childList[0]);
		codefile<<name;
	}
	else if(node->rule=="variable : ID LTHIRD expression RTHIRD")
	{
		string name = "";
		for(int h=0;h<globalVars.size();h++)
		{
			if(node->childList[0]->getName()==globalVars[h]->getName())
			{
				name = globalVars[h]->getName();
				name.append("[BX]");
			}
		}
		if(name=="") name = "[BP+SI]";

		codefile<<name;

		node->childList.clear();
		
	}
	else if(node->rule=="expression : logic_expression")
	{

	}
	else if(node->rule=="expression : variable ASSIGNOP logic_expression")
	{ 
		codefile<<printLabel();
		asmTree(node->childList[2]);
		codefile<<"\tPOP AX\n";
		if(node->childList[0]->childList.size()>1)
		{
			prepareArray(node->childList[0]->childList[2],checkIfGlobal(node->childList[0]->childList[0]));
			codefile<<"\tPOP AX\n";
		}
		codefile<<"\tMOV ";
		asmTree(node->childList[0]);
		codefile<<", AX\n";
		node->childList.clear();
	
	}
	else if(node->rule=="logic_expression : rel_expression")
	{
		asmTree(node->childList[0]);
		node->childList.clear();
	}
	else if(node->rule=="logic_expression : rel_expression LOGICOP rel_expression")
	{
		asmTree(node->childList[0]);
		//asmTree(node->childList[2]);
		codefile<<"\tPOP AX\n";
		if(node->childList[1]->getName()=="&&")
		{
			codefile<<"\tCMP AX,0\n\tJNE L"<<label<<"\n";
			codefile<<"\tJMP L"<<label+2<<"\n";
			codefile<<printLabel();
			asmTree(node->childList[2]);
			codefile<<"\tPOP DX\n";
			codefile<<"\tCMP DX,0\n";
			codefile<<"\tJNE L"<<label<<"\n";
			codefile<<"\tJMP L"<<label+1<<"\n";
			codefile<<printLabel();
			codefile<<movFunc("AX","1",node->childList[0]->sl);
			codefile<<"\tJMP L"<<label+1<<"\n";
			codefile<<printLabel();
			codefile<<movFunc("AX","0",node->childList[0]->sl);

		}
		else if(node->childList[1]->getName()=="||")
		{
			codefile<<"\tCMP AX,0\n\tJNE L"<<label+1<<"\n";
			codefile<<"\tJMP L"<<label<<"\n";
			codefile<<printLabel();
			asmTree(node->childList[2]);
			codefile<<"\tPOP DX\n";
			codefile<<"\tCMP DX,0\n";
			codefile<<"\tJNE L"<<label<<"\n";
			codefile<<"\tJMP L"<<label+1<<"\n";
			codefile<<printLabel();
			codefile<<movFunc("AX","1",node->childList[0]->sl);
			codefile<<"\tJMP L"<<label+1<<"\n";
			codefile<<printLabel();
			codefile<<movFunc("AX","0",node->childList[0]->sl);
			
		}
		codefile<<printLabel();
		codefile<<"\tPUSH AX\n";
		node->childList.clear();
	}
	else if(node->rule=="rel_expression : simple_expression")
	{
		asmTree(node->childList[0]);
		node->childList.clear();
	}
	else if(node->rule=="rel_expression : simple_expression RELOP simple_expression")
	{
		asmTree(node->childList[0]);
		asmTree(node->childList[2]);
		codefile<<"\tPOP DX\n\tPOP AX\n\tCMP AX,DX\n";
		if(node->childList[1]->getName()=="<=")
		{
		codefile<<"\tJLE L"<<label<<"\n";
		} 
		else if(node->childList[1]->getName()==">=")
		{
		codefile<<"\tJGE L"<<label<<"\n";
		}
		else if(node->childList[1]->getName()=="<")
		{
		codefile<<"\tJL L"<<label<<"\n";
		}
		else if(node->childList[1]->getName()==">")
		{
		codefile<<"\tJG L"<<label<<"\n";
		}
		else if(node->childList[1]->getName()=="==")
		{
		codefile<<"\tJE L"<<label<<"\n";
		}
		else if(node->childList[1]->getName()=="!=")
		{
		codefile<<"\tJNE L"<<label<<"\n";
		}
		
		codefile<<"\tJMP L"<<label+1<<"\n";
		codefile<<printLabel();
		codefile<<movFunc("AX","1",node->childList[0]->sl);
		codefile<<"\tJMP L"<<label+1<<"\n";
		codefile<<printLabel();
		codefile<<movFunc("AX","0",node->childList[0]->sl);
		codefile<<printLabel();
		codefile<<pushFunc("AX");
		node->childList.clear();

	}
	else if(node->rule=="simple_expression : term")
	{
		asmTree(node->childList[0]);
		node->childList.clear();
	}
	else if(node->rule=="simple_expression : simple_expression ADDOP term")
	{
		asmTree(node->childList[0]);
		asmTree(node->childList[2]);
		if(node->childList[1]->getName()=="+") codefile<<"\tPOP DX\n\tPOP AX\n\tADD AX,DX\n\tPUSH AX\n";
		else codefile<<"\tPOP DX\n\tPOP AX\n\tSUB AX,DX\n\tPUSH AX\n";
		node->childList.clear();
		
	}
	else if(node->rule=="term : unary_expression")
	{
		asmTree(node->childList[0]);
		node->childList.clear();
	}
	else if(node->rule=="term : term MULOP unary_expression")
	{
		asmTree(node->childList[0]);
		asmTree(node->childList[2]);
		codefile<<"\tPOP CX\n";
		codefile<<"\tPOP AX\n\tCWD\n";
		if ((node->childList[1])->getName()=="%")
		{
			codefile<<"\tDIV CX\n\tPUSH DX\n";
		}
		else if ((node->childList[1])->getName()=="/")
		{
			codefile<<"\tDIV CX\n\tPUSH AX\n";
		}
		else
		{
			codefile<<"\tMUL CX\n\tPUSH AX\n";
		}
	
		node->childList.clear();
	}
	else if(node->rule=="unary_expression : ADDOP unary_expression")
	{
		asmTree(node->childList[1]);
		
		if(node->childList[0]->getName()=="-")
		{
			codefile<<"\tPOP AX\n";
			codefile<<"\tNEG AX\n";
			codefile<<"\tPUSH AX\n";
		}
		node->childList.clear();

	}
	else if(node->rule=="unary_expression : NOT unary_expression")
	{
		asmTree(node->childList[1]);
		codefile<<"\tPOP AX\n";
		codefile<<"\tNOT AX\n";
		codefile<<"\tPUSH AX\n";
		node->childList.clear();

	}
	else if(node->rule=="unary_expression : factor")
	{
		asmTree(node->childList[0]);
		node->childList.clear();
	}
	else if(node->rule=="factor : variable")
	{
		string name = "";
		if(node->childList[0]->childList.size()>1)
		{	
			bool globalCheck = checkIfGlobal(node->childList[0]->childList[0]);
			prepareArray(node->childList[0]->childList[2],globalCheck);
			name = "";
			if(!globalCheck)
			{
				name = "[BP+SI]";
			}
			else 
			{
				name = getNameforVariable(node->childList[0]);
				name.append("[BX]");
			}
		}
		else{
			name = "";
			if(currentFunction!=nullptr)
			{
				name = getFunctionLocalVariableName(node->childList[0],currentFunction);
			}
			else name = getNameforVariable(node->childList[0]);
		}
		codefile<<movFunc("AX",name,node->childList[0]->sl);
		codefile<<pushFunc("AX");
		node->childList.clear();
	}
	else if(node->rule=="factor : ID LPAREN argument_list RPAREN")
	{
		asmTree(node->childList[2]);
		codefile<<"\tCALL ";
		codefile<<node->childList[0]->getName();
		codefile<<"\n";
		codefile<<"\tPUSH AX\n";
		node->childList.clear();
	}
	else if(node->rule=="factor : LPAREN expression RPAREN")
	{

	}
	else if(node->rule=="factor : CONST_INT")
	{	//cout<<"kintu kaj to korena"<<endl;
		codefile<<movFunc("AX",node->childList[0]->getName(),node->childList[0]->sl);
		codefile<<pushFunc("AX");
		node->childList.clear();
	}
	else if(node->rule=="factor : CONST_FLOAT")
	{
		codefile<<movFunc("AX",node->childList[0]->getName(),node->childList[0]->sl);
		codefile<<pushFunc("AX");
		node->childList.clear();
	}
	else if(node->rule=="factor : variable INCOP")
	{
		codefile<<printLabel();
		string name = "";
		if(node->childList[0]->childList.size()>1)
		{	
			bool globalCheck = checkIfGlobal(node->childList[0]->childList[0]);
			prepareArray(node->childList[0]->childList[2],globalCheck);
			name = "";
			if(!globalCheck)
			{
				name = "[BP+SI]";
			}
			else 
			{
				name = getNameforVariable(node->childList[0]);
				name.append("[BX]");
			}
		}
		else{
			name = "";
			if(currentFunction!=nullptr)
			{
				name = getFunctionLocalVariableName(node->childList[0],currentFunction);
			}
			else name = getNameforVariable(node->childList[0]);
		}
		codefile<<movFunc("AX",name,node->childList[0]->sl);
		codefile<<"\tINC AX\n";
		codefile<<"\tMOV ";
		codefile<<name;
		codefile<<", AX\n";
		node->childList.clear();
	}
	else if(node->rule=="factor : variable DECOP")
	{
		codefile<<printLabel();
		string name = "";
		if(node->childList[0]->childList.size()>1)
		{	
			bool globalCheck = checkIfGlobal(node->childList[0]->childList[0]);
			prepareArray(node->childList[0]->childList[2],globalCheck);
			name = "";
			if(!globalCheck)
			{
				name = "[BP+SI]";
			}
			else 
			{
				name = getNameforVariable(node->childList[0]);
				name.append("[BX]");
			}
		}
		else{
			name = "";
			if(currentFunction!=nullptr)
			{
				name = getFunctionLocalVariableName(node->childList[0],currentFunction);
			}
			else name = getNameforVariable(node->childList[0]);
		}
		codefile<<movFunc("AX",name,node->childList[0]->sl);
		//codefile<<"\tPUSH AX\n";
		codefile<<"\tDEC AX\n";
		codefile<<"\tMOV ";
		codefile<<name;
		codefile<<", AX\n";
		node->childList.clear();
	}
	else if(node->rule=="argument_list : arguments")
	{

	}
	else if(node->rule=="arguments : arguments COMMA logic_expression")
	{

	}
	else if(node->rule=="arguments : logic_expression")
	{
		asmTree(node->childList[0]);
		node->childList.clear();
	}
	else
	{

	}

}

void asmTree(symbolInfo* root)
{
	assemblyGenerator(root);
	if(root->leaf==true)
	{
		return;
	}
	if(root->leaf==false)
	{
	for(symbolInfo* child: root->childList)
	{
		asmTree(child);
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
		$$->rule = "start : program";
		logfile<<"start : program"<<endl;
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("start : program",$$->sl,$$->el);
		$$->childList.push_back($1);
		parseTree($$,0);
		
			
			asmTree($$);
			string Txt;
    		while (getline(pfile, Txt)) {
        	codefile << Txt <<endl;
    		}
			codefile<<"END main\n";

			optimization(codefile);
			
		

	}
	;

program : program unit { 
	string text = $1->getName();
	text+= $2->getName();
	$$ = new symbolInfo(text,"dummy");
	$$->rule = "program : program unit";
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
		$$->rule = "program : unit";
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("program : unit",$$->sl,$$->el);
		logfile<<"program : unit "<<endl;
		$$->childList.push_back($1);
		}
	;
	
unit : var_declaration { 
	$$ = new symbolInfo($1->getName(),$1->getType());
	$$->rule = "unit : var_declaration";
	$$->sl = $1->sl;
	$$->el = $1->el;
	$$->parseText = generateParseText("unit : var_declaration",$$->sl,$$->el);
	logfile<<"unit : var_declaration "<<endl;
	$$->childList.push_back($1);

	}
    | func_declaration
	 {
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->rule = "unit : func_declaration";
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("unit : func_declaration",$$->sl, $$->el);
		logfile<<"unit : func_declaration "<<endl;
		$$->childList.push_back($1);

	 }
    | func_definition
	 {
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->rule = "unit : func_definition";
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
		
			$$->rule = "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON";
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
			
			$$->rule = "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON";
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
			
			
			if(!(func->getName()=="main")) table->insert(func);
			insideFunction=false;

			string text = $1->getType();
			text+= $2->getName();
			text+= "(";
			text+= $4->getName();
			text+= ")";
			text+= $6->getName();
			$$ = new symbolInfo(text,"");

			$$->rule = "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement";
			$$->sl = $1->sl;
			$$->el = $6->el;
			$$->stackOffset = SO;
			SO = 0;
			$$->parseText = generateParseText("func_definition :  type_specifier ID LPAREN parameter_list RPAREN compound_statement",$$->sl,$$->el);
			$$->setName($2->getName());
			funcName = $2->getName();
			

			
			// for(int h=0;h<paramlist.size();h++)
			// {
			// 	$$->localVariableList.push_back(paramlist[h]);

			// }
			
			for(int h=0;h<scopeVars.size();h++)
			{
				$$->localVariableList.push_back(scopeVars[h]);
			}
			scopeVars.clear();
			paramlist.clear();
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
					
					table->insert(scopeVars[i]);
				}
			table->printAll(logfile);
			table->exitScope();
			insideFunction=false;
			
			if(!(func->getName()=="main")) table->insert(func);
			string text = $1->getType();
			text+= $2->getName();
			text+= "()";
			text+= $5->getName();
			$$ = new symbolInfo(text,"");
			$$->rule = "func_definition : type_specifier ID LPAREN RPAREN compound_statement";
			$$->stackOffset = SO;
			SO = 0;
			$$->setName($2->getName());
			funcName = $2->getName();
			
			for(int h=0;h<scopeVars.size();h++)
			{
				$$->localVariableList.push_back(scopeVars[h]);
			}
			
			$$->sl = $1->sl;
			$$->el = $5->el;
			$$->parseText = generateParseText("func_definition : type_specifier ID LPAREN RPAREN compound_statement",$$->sl,$$->el);
			logfile<<"func_definition : type_specifier ID LPAREN RPAREN compound_statement"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->childList.push_back($4);
				$$->childList.push_back($5);
			
			scopeVars.clear();
			
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
			$$->rule = "parameter_list : parameter_list COMMA type_specifier ID";
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
			$$->rule = "parameter_list : parameter_list COMMA type_specifier";
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
			$$->rule = "parameter_list : type_specifier ID";
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
			$$->rule = "parameter_list : type_specifier";
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
				$$->rule = "compound_statement : LCURL statements RCURL";
				$$->sl = $1->sl;
				$$->el = $3->el;
				$$->parseText = generateParseText("compound_statement : LCURL statements RCURL",$$->sl,$$->el);
				logfile<<"compound_statement : LCURL statements RCURL"<<endl;
				$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->localVariableList = $2->localVariableList;
				
			}
 		    | LCURL RCURL
			{
				$$ = new symbolInfo("{}","dummy");
				$$->rule = "compound_statement : LCURL RCURL";
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
				
				$$ = new symbolInfo("d","d");
				$$->rule = "var_declaration : type_specifier declaration_list SEMICOLON";
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
						if(!entry) 
						{
							SO += 2;
							varlist[i]->stackOffset = SO;
							varlist[i]->isGlobal = false;
							scopeVars.push_back(varlist[i]);
							$$->localVariableList.push_back(varlist[i]);
							
						}
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
						varlist[i]->isGlobal = true;
						table->insert(varlist[i]);
						globalVars.push_back(varlist[i]);
					}
				}
			}
				
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
		$$->rule = "type_specifier : INT";
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("type_specifier	: INT",$$->sl,$$->el);
		$$->childList.push_back($1);

		}
 		| FLOAT			{
		
		logfile<<"type_specifier	: FLOAT "<<endl;
	
		$$ = new symbolInfo("type_specifier",$1->getType());
		$$->rule = "type_specifier : FLOAT";
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("type_specifier	: FLOAT",$$->sl,$$->el);
		$$->childList.push_back($1);
		}

 		| VOID			{
		logfile<<"type_specifier	: VOID "<<endl;
		
		$$ = new symbolInfo("type_specifier",$1->getType());
		$$->rule = "type_specifier : VOID";
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
			$$->rule = "declaration_list : declaration_list COMMA ID";
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
			$$->rule = "declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD";
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
			$$->rule = "declaration_list : ID";
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
			$$->rule = "declaration_list : ID LTHIRD CONST_INT RTHIRD";
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
			$$->rule = "statements : statement";
			logfile<<"statements : statement "<<endl;
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("statements : statement",$$->sl,$$->el);
			$$->childList.push_back($1);
			$$->localVariableList = $1->localVariableList;
				
		}
	   | statements statement
	   {
			string text = $1->getName();
			text+="\n";
			text+=$2->getName();
		    $$ = new symbolInfo(text,$1->getType());
			$$->rule = "statements : statements statement";
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
			$$->rule = "statement : var_declaration";
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("statement : var_declaration",$$->sl,$$->el);
			logfile<<"statement : var_declaration "<<endl;
			$$->childList.push_back($1);
			$$->localVariableList = $1->localVariableList;
			
		}
	  | expression_statement
	  	{
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->rule = "statement : expression_statement";
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("statement : expression_statement",$$->sl,$$->el);
			logfile<<"statement : expression_statement "<<endl;
			$$->childList.push_back($1);
			
	  	}
	  | compound_statement
	  	{
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->rule = "statement : compound_statement";
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
			$$->rule = "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement";
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
		$$->rule = "statement : IF LPAREN expression RPAREN statement";
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
		
		$$ = new symbolInfo("dummy", "dummy");
		$$->rule = "statement : IF LPAREN expression RPAREN statement ELSE statement";
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
		$$->rule = "statement : WHILE LPAREN expression RPAREN statement";
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
		$$->rule = "statement : PRINTLN LPAREN ID RPAREN SEMICOLON";
		$$->sl = $1->sl;
		$$->el = $5->el;
		$$->parseText = generateParseText("statement : PRINTLN LPAREN ID RPAREN SEMICOLON",$$->sl,$$->el);
		logfile<<"statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<endl;


		symbolInfo* s=nullptr;
		
		if(!insideFunction) s = table->lookup($3->getName());
		else
		{
			if(paramlist.size()!=0)
			{
			for(int i=0;i<paramlist.size();i++)
			{
				if(paramlist[i]->getName()==$3->getName()) s=paramlist[i];
			}
			}
			if(s==nullptr)
			{
				for(symbolInfo* sc: scopeVars)
				{
					if(sc->getName()==$3->getName()) s=sc;
				}

				if(s==nullptr)
				{
					s = table->lookup($3->getName());
				}
			}
			
		}

		string idtext;
		if(s!=nullptr && !(s->isGlobal))
		{
			string st = "[BP-";
			st.append(to_string(s->stackOffset));
			st.append("]");
			idtext = st;
		}
		else idtext = $3->getName();



		
		$$->asmStr.append(printfunction(idtext,line_count));

		$1->asmStr="";
		$2->asmStr="";
		$3->asmStr="";
		$4->asmStr="";
		$5->asmStr="";

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
		$$->rule = "statement : RETURN expression SEMICOLON";
		$$->sl = $1->sl;
		$$->el = $3->el;
		$$->parseText = generateParseText("statement : RETURN expression SEMICOLON",$$->sl,$$->el);
		logfile<<"statement : RETURN expression SEMICOLON"<<endl;
		$2->asmStr="";
		$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
		
		
	  }
	  ;
	  
expression_statement 	: SEMICOLON	
			{
				$$ = new symbolInfo(";","SEMICOLON");
				$$->rule = "expression_statement : SEMICOLON";
				$$->sl = $1->sl;
				$$->el = $1->el;
				$$->parseText = generateParseText("expression_statement 	: SEMICOLON	",$$->sl,$$->el);
				logfile<<"expression_statement 	: SEMICOLON"<<endl;
				$$->childList.push_back($1);
				
			}		
			| expression SEMICOLON{
				$$ = new symbolInfo($1->getName()+";",$1->getType());
				$$->rule = "expression_statement : expression SEMICOLON";
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
		$$->rule = "variable : ID";
		if(!(s->isGlobal))
		{
			string st = "[BP-";
			st.append(to_string(s->stackOffset));
			st.append("]");
			$$->asmStr = st;
			$$->setName(st);
		}
		else {
			$$->asmStr = $1->getName();
			$$->setName($1->getName());
		}
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("variable : ID",$$->sl,$$->el);
		logfile<<"variable : ID	"<<endl;
		$1->asmStr="";
		$$->childList.push_back($1);

	 }		
	 | ID LTHIRD expression RTHIRD 
	 {
		
		string text = $1->getName();
		text+= "[";
		text+= $3->getName();
		text+= "]";
		string type="";

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
		$$->rule = "variable : ID LTHIRD expression RTHIRD";
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
			$$->rule = "expression : logic_expression";
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
			$$->rule = "expression : variable ASSIGNOP logic_expression";
			$$->sl = $1->sl;
			$$->el = $3->el;
			$$->parseText = generateParseText("expression : variable ASSIGNOP logic_expression",$$->sl,$$->el);
			logfile<<"expression : variable ASSIGNOP logic_expression"<<endl;
			$$->childList.clear();
			$$->childList.push_back($1);
			$$->childList.push_back($2);
			$$->childList.push_back($3);
			
	   } 	
	   ;
			
logic_expression : rel_expression 
		{
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->rule = "logic_expression : rel_expression";
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("logic_expression : rel_expression ",$$->sl,$$->el);
			logfile<<"logic_expression : rel_expression "<<endl;
			$$->childList.push_back($1);
			$$->asmStr=$1->asmStr;
			$1->asmStr="";

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
			$$->rule = "logic_expression : rel_expression LOGICOP rel_expression";
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
			$$->rule = "rel_expression : simple_expression";
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("rel_expression : simple_expression ",$$->sl,$$->el);
			logfile<<"rel_expression : simple_expression "<<endl;
			$$->childList.push_back($1);
			$$->asmStr=$1->asmStr;
			$1->asmStr="";

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
			$$->rule = "rel_expression : simple_expression RELOP simple_expression";
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
			$$->rule = "simple_expression : term";
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("simple_expression : term ",$$->sl,$$->el);
			logfile<<"simple_expression : term "<<endl;
			$$->childList.push_back($1);
			$$->asmStr=$1->asmStr;
			$1->asmStr="";

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
			$$->rule = "simple_expression : simple_expression ADDOP term";
			$$->sl = $1->sl;
			$$->el = $3->el;
			$$->parseText = generateParseText("simple_expression : simple_expression ADDOP term",$$->sl,$$->el);
			logfile<<"simple_expression : simple_expression ADDOP term "<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				$$->childList.push_back($3);
				$$->asmStr = addop($1->asmStr,$2->getName(),$3->asmStr,line_count);
			$1->asmStr="";
			$3->asmStr="";
		// have to handle typecasting here
		  }
		  ;
					
term :	unary_expression
	{
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->rule = "term : unary_expression";
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("term : unary_expression",$$->sl,$$->el);
		logfile<<"term :	unary_expression"<<endl;
		$$->childList.push_back($1);
		$$->asmStr=$1->asmStr;
			$1->asmStr="";
	
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
		$$->rule = "term : term MULOP unary_expression";
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
			$$->rule = "unary_expression : ADDOP unary_expression";
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
			$$->rule = "unary_expression : NOT unary_expression";
			$$->sl = $2->sl;
			$$->el = $2->el;
			$$->parseText = generateParseText("logic_expression : rel_expression ",$$->sl,$$->el);
			logfile<<"unary_expression	: NOT unary_expression"<<endl;
			$$->childList.push_back($1);
				$$->childList.push_back($2);
				

		 } 
		 | factor {
			$$ = new symbolInfo($1->getName(),$1->getType());
			$$->rule = "unary_expression : factor";
			$$->sl = $1->sl;
			$$->el = $1->el;
			$$->parseText = generateParseText("unary_expression : factor ",$$->sl,$$->el);
			logfile<<"unary_expression : factor "<<endl;	
			$$->childList.push_back($1);
			$$->asmStr=$1->asmStr;
			$1->asmStr="";
			
		 }
		 ;
	
factor	: variable 
		{
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->rule = "factor : variable";
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("factor : variable ",$$->sl,$$->el);
		logfile<<"factor	 : variable"<<endl;
		$$->childList.push_back($1);
		$$->asmStr=$1->asmStr;
		$1->asmStr="";
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
		$$->rule = "factor : ID LPAREN argument_list RPAREN";
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
		$$->rule = "factor : LPAREN expression RPAREN";
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
		$$->rule = "factor : CONST_INT";
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("factor : CONST_INT",$$->sl,$$->el);
		logfile<<"factor	: CONST_INT	"<<endl;
		$$->childList.push_back($1);
		$$->asmStr=movFunc("AX",$1->getName(),line_count);
		$$->asmStr.append(pushFunc("AX"));
		
	
		} 
	| CONST_FLOAT
		{
		$$ = new symbolInfo($1->getName(),$1->getType());
		$$->rule = "factor : CONST_FLOAT";
		$$->sl = $1->sl;
		$$->el = $1->el;
		$$->parseText = generateParseText("factor : CONST_FLOAT",$$->sl,$$->el);
		logfile<<"factor	: CONST_FLOAT"<<endl;
		$$->childList.push_back($1);
		$$->asmStr=$1->getName();
		}
	| variable INCOP 
		{
		$$ = new symbolInfo($1->getName()+"++",$1->getType());
		$$->rule = "factor : variable INCOP";
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
		$$->rule = "factor : variable DECOP";
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
					$$->rule = "argument_list : arguments";
					$$->sl = $1->sl;
					$$->el = $1->el;
					$$->parseText = generateParseText("argument_list : arguments",$$->sl,$$->el);
					logfile<<"argument_list : arguments"<<endl;
					$$->childList.push_back($1);

				}
			  |{
				$$ = new symbolInfo("","");
				$$->rule = "argument_list :";
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
				$$->rule = "arguments : arguments COMMA logic_expression";
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
			$$->rule = "arguments : logic_expression";
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
	codefile.open("code.asm");
	pfile.open("print_library.txt");
	optfile.open("optimized_code.asm");

	yyin= fin;
	yyparse();
	logfile<<"Total lines: "<<line_count<<endl;
	logfile<<"Total errors: "<<err_count<<endl;
	
	logfile.close();
	tokenfile.close();
	errfile.close();
	parsefile.close();
	codefile.close();
	pfile.close();
	optfile.close();
	fclose(yyin);
	table = nullptr;
	/* clearAndDeleteSymbolInfoVector(varlist);
	clearAndDeleteSymbolInfoVector(paramlist);
	clearAndDeleteSymbolInfoVector(scopeVars); */

	return 0;
}


