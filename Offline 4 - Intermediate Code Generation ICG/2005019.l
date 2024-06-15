%option noyywrap

%x LITERAL_STATE 
%x SINGLE_STRING_STATE
%x MULTI_STRING_STATE
%x SINGLE_LINE_COMMENT
%x MULTI_LINE_COMMENT
%x CHECK_CHAR


%{
#include<bits/stdc++.h>
#include "2005019.h"
#include "y.tab.h"
using namespace std;

extern YYSTYPE yylval;
extern symbolTable* table;
extern bool insideFunction;
extern bool insideSpecialCurls;
extern int SO;
extern int label;

void yyerror(char *);




bool response;
bool multiChar;
int startline;



extern int line_count;
extern int err_count;
extern ofstream logfile;
extern ofstream tokenfile;

string str;
vector<char> scan;

string s = "";

char getAscii(const char* str);
string UpperCase(const string& input);
%}

WHITESPACE [ \t\f\r\v]+
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \r?\n
INTEGER (0|[1-9]{DIGIT}*)
FLOAT {DIGIT}+(\.{DIGIT}+)?(E[+-]?{DIGIT}+)?
IDENTIFIER [_a-zA-Z]({LETTER}|{DIGIT}|_)*

REDUNDANT_DECIMALS {DIGIT}*((\.{DIGIT}*))((\.{DIGIT}*))+(E[+-]?{DIGIT}+)?
ILL_FORMED_NUMBER {DIGIT}+E+{DIGIT}*[+-]*(\.{DIGIT}*)+
INVALID_IDNUM {DIGIT}+{IDENTIFIER}


CHAR_EXCEPT_SLASH [^\\]
CHAR_EXCEPT_QUOTE [^\']



%%


{NEWLINE} {line_count++;}

"if"	{
		symbolInfo* s = new symbolInfo(yytext,"IF");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "IF : if 	<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		
		yylval.symbol = s;
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		return IF;
}
"else"	{
		symbolInfo* s = new symbolInfo(yytext,"ELSE");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "ELSE : else 	<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		return ELSE;
}
"for"	{
		symbolInfo* s = new symbolInfo(yytext,"FOR");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "FOR : for 	<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		return FOR;
}
"while"	{
		symbolInfo* s = new symbolInfo(yytext,"WHILE");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "WHILE : while 	<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		return WHILE;
}
"do"	{
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		
}
"break"	{
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
}
"int"	{
		symbolInfo* s = new symbolInfo(yytext,"INT");
		s->sl = line_count;
		s->el = line_count;
		s->leaf = true;
		string t = "INT : int 	<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		return INT;
}
"char"	{
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		return CHAR;
}
"float"	{
		symbolInfo* s = new symbolInfo(yytext,"FLOAT");
		s->sl = line_count;
		s->el = line_count;
		s->leaf = true;
		string t = "FLOAT : float 	<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		return FLOAT;
}
"double"	{
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		return DOUBLE;
}
"void"		{
		symbolInfo* s = new symbolInfo(yytext,"VOID");
		s->sl = line_count;
		s->el = line_count;
		s->leaf = true;
		string t = "VOID : void 	<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		return VOID;
}
"return"	{
		symbolInfo* s = new symbolInfo(yytext,"RETURN");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "RETURN : return 	<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		return RETURN;
}
"case"		{
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		
}
"default"	{
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		
}
"continue"	{
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		
}
"switch"	{
		logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
		
}
"println"	{
		symbolInfo* s = new symbolInfo(yytext,"PRINTLN");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "PRINTLN : printf 	<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
		logfile<<"Line# "<<line_count<<": Token <"<<"PRINTLN"<<"> Lexeme "<<yytext<<" found\n";
		return PRINTLN;
}



"\/\/"	{
			BEGIN SINGLE_LINE_COMMENT;
			startline=line_count;
			scan.clear();
			str="";
			scan.push_back('/');
			scan.push_back('/');
		}

"\/\*"	{
			BEGIN MULTI_LINE_COMMENT;
			startline=line_count;
			scan.clear();
			str="";
			str.append("/*");

}

"++"	{
			symbolInfo* s = new symbolInfo(yytext,"INCOP");
			s->sl= line_count;
			s->el=line_count;
			s->leaf=true;
			string t = "INCOP : ++ 	<Line: ";
			t+= to_string(line_count);
			t+= ">";
			s->parseText = t;
			yylval.symbol = s;

			logfile<<"Line# "<<line_count<<": Token <INCOP> Lexeme "<<yytext<<" found\n";
			return INCOP;
		}

"--"	{
			symbolInfo* s = new symbolInfo(yytext,"DECOP");
			s->sl= line_count;
			s->el=line_count;
			s->leaf=true;
			string t = "DECOP : -- 	<Line: ";
			t+= to_string(line_count);
			t+= ">";
			s->parseText = t;
			yylval.symbol = s;
			logfile<<"Line# "<<line_count<<": Token <DECOP> Lexeme "<<yytext<<" found\n";
			return DECOP;
		}

"&&"|"||"	{

		symbolInfo* s = new symbolInfo(yytext,"LOGICOP");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "LOGICOP : ";
		t+= yytext ;	
		t+=" \t<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
			
		logfile<<"Line# "<<line_count<<": Token <LOGICOP> Lexeme "<<yytext<<" found\n";
		return LOGICOP;
		}

"&"|"|"|"^"|"<<"|">>"	{

		symbolInfo* s = new symbolInfo(yytext,"BITOP");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "BITOP : ";
		t+= yytext ;	
		t+=" \t<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
		
		logfile<<"Line# "<<line_count<<": Token <BITOP> Lexeme "<<yytext<<" found\n";
		return BITOP;
		}

"<="|"<"|">="|">"|"!="|"=="	{

		symbolInfo* s = new symbolInfo(yytext,"RELOP");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "RELOP : ";
		t+= yytext;
		t+=" \t<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
			logfile<<"Line# "<<line_count<<": Token <RELOP> Lexeme "<<yytext<<" found\n";
			return RELOP;
		}

"!"		{
			symbolInfo* s = new symbolInfo(yytext,"NOT");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "NOT : ! \t<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
		logfile<<"Line# "<<line_count<<": Token <NOT> Lexeme "<<yytext<<" found\n";
		return NOT;
		}

"="		{
		symbolInfo* s = new symbolInfo(yytext,"ASSIGNOP");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "ASSIGNOP : =  \t<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
		logfile<<"Line# "<<line_count<<": Token <ASSIGNOP> Lexeme "<<yytext<<" found\n";
		return ASSIGNOP;
		}

"+"|"-"		{
		symbolInfo* s = new symbolInfo(yytext,"ADDOP");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "ADDOP : ";
		t+= yytext;
		t+=" \t<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
			logfile<<"Line# "<<line_count<<": Token <ADDOP> Lexeme "<<yytext<<" found\n";
			return ADDOP;
		}

"*"|"/"|"%"		{
			symbolInfo* s = new symbolInfo(yytext,"MULOP");
		s->sl= line_count;
		s->el=line_count;
		s->leaf=true;
		string t = "MULOP : ";
		t+= yytext;
		t+=" \t<Line: ";
		t+= to_string(line_count);
		t+= ">";
		s->parseText = t;
		yylval.symbol = s;
			logfile<<"Line# "<<line_count<<": Token <MULOP> Lexeme "<<yytext<<" found\n";
			return MULOP;
		}

"("		{
			symbolInfo* s = new symbolInfo(yytext,"LPAREN");
			s->sl= line_count;
			s->el=line_count;
			s->leaf=true;
			string t = "LPAREN : ( \t<Line: ";
			t+= to_string(line_count);
			t+= ">";
			s->parseText = t;
			yylval.symbol = s;
			logfile<<"Line# "<<line_count<<": Token <LPAREN> Lexeme "<<yytext<<" found\n";
			return LPAREN;
		}

")"		{
			symbolInfo* s = new symbolInfo(yytext,"RPAREN");
			s->sl= line_count;
			s->el=line_count;
			s->leaf=true;
			string t = "RPAREN : ) \t<Line: ";
			t+= to_string(line_count);
			t+= ">";
			s->parseText = t;
			yylval.symbol = s;
			logfile<<"Line# "<<line_count<<": Token <RPAREN> Lexeme "<<yytext<<" found\n";
			return RPAREN;
		}

"{"		{
			symbolInfo* s = new symbolInfo(yytext,"LCURL");
			s->sl= line_count;
			s->el=line_count;
			s->leaf=true;
			string t = "LCURL : { \t<Line: ";
			t+= to_string(line_count);
			t+= ">";
			s->parseText = t;
			yylval.symbol = s;
			if(insideFunction)
			{
				insideSpecialCurls = true;
			}
			else insideFunction = true;
			SO =0;
			//table->enterScope();
			logfile<<"Line# "<<line_count<<": Token <LCURL> Lexeme "<<yytext<<" found\n";
			return LCURL;
		}

"}"		{
			symbolInfo* s = new symbolInfo(yytext,"RCURL");
			s->sl= line_count;
			s->el=line_count;
			s->leaf=true;
			string t = "RCURL : } \t<Line: ";
			t+= to_string(line_count);
			t+= ">";
			s->parseText = t;
			yylval.symbol = s;
			if(insideFunction&&insideSpecialCurls)
			{}
			else if(insideSpecialCurls)
			{
				insideSpecialCurls = false;
			}
			else insideFunction = false;
			//table->exitScope();
			logfile<<"Line# "<<line_count<<": Token <RCURL> Lexeme "<<yytext<<" found\n";
			return RCURL;
		}

"["		{
			symbolInfo* s = new symbolInfo(yytext,"LTHIRD");
			s->sl= line_count;
			s->el=line_count;
			s->leaf=true;
			string t = "LTHIRD : [ \t<Line: ";
			t+= to_string(line_count);
			t+= ">";
			s->parseText = t;
			yylval.symbol = s;
			logfile<<"Line# "<<line_count<<": Token <LSQUARE> Lexeme "<<yytext<<" found\n";
			return LTHIRD;
		}

"]"		{
			symbolInfo* s = new symbolInfo(yytext,"RTHIRD");
			s->sl= line_count;
			s->el=line_count;
			s->leaf=true;
			string t = "RTHIRD : ] \t<Line: ";
			t+= to_string(line_count);
			t+= ">";
			s->parseText = t;
			yylval.symbol = s;
			logfile<<"Line# "<<line_count<<": Token <RSQUARE> Lexeme "<<yytext<<" found\n";
			return RTHIRD;
		}

","		{
			symbolInfo* s = new symbolInfo(yytext,"COMMA");
			s->sl= line_count;
			s->el=line_count;
			s->leaf=true;
			string t = "COMMA : , \t<Line: ";
			t+= to_string(line_count);
			t+= ">";
			s->parseText = t;
			yylval.symbol = s;
			logfile<<"Line# "<<line_count<<": Token <COMMA> Lexeme "<<yytext<<" found\n";
			return COMMA;
		}

";"		{
			symbolInfo* s = new symbolInfo(yytext,"SEMICOLON");
			s->sl= line_count;
			s->el=line_count;
			s->leaf=true;
			string t = "SEMICOLON : ; \t<Line: ";
			t+= to_string(line_count);
			t+= ">";
			s->parseText = t;
			yylval.symbol = s;
			logfile<<"Line# "<<line_count<<": Token <SEMICOLON> Lexeme "<<yytext<<" found\n";
			return SEMICOLON;
		}

"\'"	{
			BEGIN LITERAL_STATE;
			scan.clear();
			scan.push_back('\'');
			str = "";
		}

"\""	{
			BEGIN SINGLE_STRING_STATE;
			startline = line_count;
			scan.clear();
			scan.push_back('\"');
			str="";
			
		}



<SINGLE_LINE_COMMENT>{NEWLINE}		{ 
		line_count++; 
		logfile<<"Line# "<<startline<<": ";
		logfile<<"Token <SINGLE LINE COMMENT> Lexeme ";
		for (char ch : scan) 
		{logfile << ch;}
		logfile<<" found\n";
		BEGIN INITIAL;
}

<SINGLE_LINE_COMMENT>"\\"{NEWLINE}			{ 
		line_count++;
		str.append(yytext); 
		scan.push_back('\\');
		scan.push_back('\n');
}

<SINGLE_LINE_COMMENT>{CHAR_EXCEPT_SLASH}		{ 
	str.append(yytext);	
	scan.push_back(yytext[0]);}


<MULTI_LINE_COMMENT>"\*\/"		{ 
		str.append(yytext);
		logfile<<"Line# "<<startline<<": ";
		logfile<<"Token <MULTI LINE COMMENT> Lexeme "<<str<<" found"<<endl; 
		BEGIN INITIAL;
}
<MULTI_LINE_COMMENT>{NEWLINE} 					{ line_count++ ; str.append(yytext);}
<MULTI_LINE_COMMENT>{CHAR_EXCEPT_SLASH} 		{ str.append(yytext);}
<MULTI_LINE_COMMENT><<EOF>>			{

			err_count++;
			logfile<<"Error at line# "<<line_count<<": UNFINISHED_COMMENT "<<str<<endl;
			BEGIN INITIAL;
}



<CHECK_CHAR>"\'"						{
			
			if(!multiChar)
			{
			logfile<<"Line# "<<line_count<<": Token <CONST_CHAR> Lexeme "<<str<<" found\n";
			BEGIN INITIAL;
			}
			else
			{
				err_count++;
				logfile<<"Error at line# "<<line_count<<": MULTICHAR_CONST_CHAR "<<scan[0]<<str<<scan[0]<<endl;
				multiChar=false;
				BEGIN INITIAL;
			}
		
		}



<CHECK_CHAR>{NEWLINE}				{

			err_count++;
			logfile<<"Error at line# "<<line_count<<": UNFINISHED_CONST_CHAR ";
			for (char ch : scan) 
				{logfile << ch;}
			logfile<<endl;
			BEGIN INITIAL;
			line_count++;
}

<CHECK_CHAR>"\\""\'"					{
			
			str.append(yytext);
			scan.push_back('\\');
			scan.push_back('\'');
}

<CHECK_CHAR>{CHAR_EXCEPT_QUOTE}			{
			
			if(yytext[0]==';')
			{

				err_count++;
				logfile<<"Error at line# "<<line_count<<": UNFINISHED_CONST_CHAR "<<scan[0]<<str<<endl;

				tokenfile<<"<SEMICOLON, "<<yytext<<">\n";
				logfile<<"Line# "<<line_count<<": Token <SEMICOLON> Lexeme "<<yytext<<" found\n";
				BEGIN INITIAL;
			}
			multiChar = true;
			str.append(yytext);
			scan.push_back(yytext[0]);	

}

<LITERAL_STATE>"'" 	{

			err_count++;
			logfile<<"Error at line# "<<line_count<<": EMPTY_CONST_CHAR "<<scan[0]<<scan[0]<<endl;
			BEGIN INITIAL;
}

<LITERAL_STATE>"\\\'"			{
			
			str.append(yytext);
			scan.push_back('\\');
			scan.push_back('\'');
			BEGIN CHECK_CHAR;
}

<LITERAL_STATE>{CHAR_EXCEPT_SLASH}	{	scan.push_back(yytext[0]);	str.append(yytext); BEGIN CHECK_CHAR;		}


<LITERAL_STATE>"\\\""	{	str.append("\"");	BEGIN CHECK_CHAR;}
<LITERAL_STATE>"\\n"	{	str.append("\n");	BEGIN CHECK_CHAR;}
<LITERAL_STATE>"\\t"	{	str.append("\t");	BEGIN CHECK_CHAR;}
<LITERAL_STATE>"\\b"	{	str.append("\b");	BEGIN CHECK_CHAR;}
<LITERAL_STATE>"\\v"	{	str.append("\v");	BEGIN CHECK_CHAR;}
<LITERAL_STATE>"\\0"	{	str.append("\0");	BEGIN CHECK_CHAR;}
<LITERAL_STATE>"\\r"	{	str.append("\r");	BEGIN CHECK_CHAR;}
<LITERAL_STATE>"\\\\"	{	str.append("\\");	BEGIN CHECK_CHAR;}
<LITERAL_STATE>"\\a"	{	str.append("\a");	BEGIN CHECK_CHAR;}
<LITERAL_STATE>"\\f"	{	str.append("\f");	BEGIN CHECK_CHAR;}



<SINGLE_STRING_STATE>"\\"{NEWLINE}			{

			
			line_count++;
			scan.push_back('\\');
			scan.push_back('\n');
			BEGIN MULTI_STRING_STATE;
			
}


<SINGLE_STRING_STATE>"\""	{

			scan.push_back('\"');
			
			logfile<<"Line# "<<startline<<": ";
			logfile<<"Token <SINGLE LINE STRING> Lexeme ";
			for (char ch : scan) 
				{logfile << ch;}
			logfile<<" found\n";
			BEGIN INITIAL;
			
}

<MULTI_STRING_STATE>"\""		{

			scan.push_back('\"');
			
			logfile<<"Line# "<<startline<<": ";
			logfile<<"Token <MULTI LINE STRING> Lexeme ";
			for (char ch : scan) 
				{logfile << ch;}
			logfile<<" found\n";
			BEGIN INITIAL;
			
}

<SINGLE_STRING_STATE>{NEWLINE}			{

			
			err_count++;
			logfile<<"Error at line# "<<line_count<<": UNFINISHED_STRING ";
			for (char ch : scan) 
				{logfile << ch;}
			logfile<<endl;
			line_count++;
			BEGIN INITIAL;
			
}

<MULTI_STRING_STATE>{NEWLINE}			{

			
			err_count++;
			logfile<<"Error at line# "<<line_count<<": UNFINISHED_STRING ";
			for (char ch : scan) 
				{logfile << ch;}
			logfile<<endl;
			line_count++;
			BEGIN INITIAL;
			
}




<MULTI_STRING_STATE>"\\"{NEWLINE}		{
			line_count++;
			
			scan.push_back('\\');
			scan.push_back('\n');
}



<SINGLE_STRING_STATE>"\'"	{ 	scan.push_back('\\'); 	scan.push_back('\''); 	str.append("\'");}
<SINGLE_STRING_STATE>"\\'"	{	scan.push_back('\\');	scan.push_back('\'');	str.append("\'");	}
<SINGLE_STRING_STATE>"\\\""	{	scan.push_back('\\');	scan.push_back('\"');	str.append("\"");	}

<SINGLE_STRING_STATE>"\\t"	{	scan.push_back('\\');	scan.push_back('t');	str.append("\t");	}
<SINGLE_STRING_STATE>"\\b"	{	scan.push_back('\\');	scan.push_back('b');	str.append("\b");	}
<SINGLE_STRING_STATE>"\\v"	{	scan.push_back('\\');	scan.push_back('v');	str.append("\v");	}
<SINGLE_STRING_STATE>"\\0"	{	scan.push_back('\\');	scan.push_back('0');	str.append("\0");	}
<SINGLE_STRING_STATE>"\\r"	{	scan.push_back('\\');	scan.push_back('r');	str.append("\r");	}
<SINGLE_STRING_STATE>"\\\\"	{	scan.push_back('\\');	scan.push_back('\\');	str.append("\\");	}
<SINGLE_STRING_STATE>"\\a"	{	scan.push_back('\\');	scan.push_back('a');	str.append("\a");	}
<SINGLE_STRING_STATE>"\\f"	{	scan.push_back('\\');	scan.push_back('f');	str.append("\f");	}
<SINGLE_STRING_STATE>"\\n"	{	scan.push_back('\\');	scan.push_back('n');	str.append("\n");	}
<MULTI_STRING_STATE>"\'"	{ 	scan.push_back('\\'); 	scan.push_back('\''); 	str.append("\'");}
<MULTI_STRING_STATE>"\\'"	{	scan.push_back('\\');	scan.push_back('\'');	str.append("\'");	}
<MULTI_STRING_STATE>"\\\""	{	scan.push_back('\\');	scan.push_back('\"');	str.append("\"");	}
<MULTI_STRING_STATE>"\\n"	{	scan.push_back('\\');	scan.push_back('n');	str.append("\n");	}
<MULTI_STRING_STATE>"\\t"	{	scan.push_back('\\');	scan.push_back('t');	str.append("\t");	}
<MULTI_STRING_STATE>"\\b"	{	scan.push_back('\\');	scan.push_back('b');	str.append("\b");	}
<MULTI_STRING_STATE>"\\v"	{	scan.push_back('\\');	scan.push_back('v');	str.append("\v");	}
<MULTI_STRING_STATE>"\\0"	{	scan.push_back('\\');	scan.push_back('0');	str.append("\0");	}
<MULTI_STRING_STATE>"\\r"	{	scan.push_back('\\');	scan.push_back('r');	str.append("\r");	}
<MULTI_STRING_STATE>"\\\\"	{	scan.push_back('\\');	scan.push_back('\\');	str.append("\\");	}
<MULTI_STRING_STATE>"\\a"	{	scan.push_back('\\');	scan.push_back('a');	str.append("\a");	}
<MULTI_STRING_STATE>"\\f"	{	scan.push_back('\\');	scan.push_back('f');	str.append("\f");	}

<SINGLE_STRING_STATE>{CHAR_EXCEPT_SLASH}	{ scan.push_back(yytext[0]); str.append(yytext);}
<MULTI_STRING_STATE>{CHAR_EXCEPT_SLASH}		{ scan.push_back(yytext[0]); str.append(yytext);}
	
{INTEGER} 	{
				symbolInfo* s = new symbolInfo(yytext,"INT");
				s->sl = line_count;
				s->el = line_count;
				s->leaf=true;
				string t = "INT : ";
				t+=yytext;
				t+=" \t<Line: ";
				t+= to_string(line_count);
				t+= ">";
				s->parseText = t;
				yylval.symbol = s;
				logfile<<"Line# "<<line_count<<": Token <CONST_INT> Lexeme "<<yytext<<" found\n";
				return CONST_INT;
				
			}

{FLOAT} 	{
				yylval.symbol = new symbolInfo(yytext,"FLOAT");
				logfile<<"Line# "<<line_count<<": Token <CONST_FLOAT> Lexeme "<<yytext<<" found\n";
				//insert in symbol table and print symbol table content(only non empty buckets)
				return CONST_FLOAT;
			}



{WHITESPACE}	{}

{IDENTIFIER}	{
				symbolInfo* s = new symbolInfo(yytext,"ID");
				s->sl = line_count;
				s->el = line_count;
				s->leaf=true;
				string t = "ID : ";
				t+=yytext;
				t+=" \t<Line: ";
				t+= to_string(line_count);
				t+= ">";
				s->parseText = t;
				yylval.symbol = s;
				logfile<<"Line# "<<line_count<<": Token <ID> Lexeme "<<yytext<<" found\n";
				// response = table->insert(yytext,"ID");
				// if(response)
				// {
				// 	table->printAll(logfile);
				// }
				// else
				// { logfile<<"\t"<<yytext<<" already exists in the current ScopeTable\n"; }
				
				return ID;
			}

{REDUNDANT_DECIMALS}	{
						err_count++;
						logfile<<"Error at line# "<<line_count<<": TOO_MANY_DECIMAL_POINTS "<<yytext<<endl;
}

{ILL_FORMED_NUMBER}		{
						err_count++;
						logfile<<"Error at line# "<<line_count<<": ILLFORMED_NUMBER "<<yytext<<endl;
}

{INVALID_IDNUM}			{
						err_count++;
						logfile<<"Error at line# "<<line_count<<": INVALID_ID_SUFFIX_NUM_PREFIX "<<yytext<<endl;
}

.			{

			err_count++;
			logfile<<"Error at line# "<<line_count<<": UNRECOGNIZED_CHAR "<<yytext<<endl;
}		

%%

string UpperCase(const string& input) {
    
    string result = input;

    for (char& c : result) {
        c = toupper(c);
    }

    return result;
}



