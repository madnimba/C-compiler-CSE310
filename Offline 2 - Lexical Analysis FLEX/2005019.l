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
using namespace std;

int line_count=1;
int err_count=0;
int warning_count=0;
bool response;
bool multiChar;
int startline;




ofstream logfile;
ofstream tokenfile;

string str;
vector<char> scan;

symbolTable* table = new symbolTable(10);
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

"if"|"else"|"for"|"while"|"do"|"break"|"int"|"char"|"float"|"double"|"void"|"return"|"case"|"default"|"continue"|"switch"		{
			tokenfile<<"<"<<UpperCase(yytext)<<", "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <"<<UpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
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

"++"|"--"	{
			tokenfile<<"<INCOP, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <INCOP> Lexeme "<<yytext<<" found\n";
		}

"&&"|"||"	{
			tokenfile<<"<LOGICOP, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <LOGICOP> Lexeme "<<yytext<<" found\n";
		}

"&"|"|"|"^"|"<<"|">>"	{

			tokenfile<<"<BITOP, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <BITOP> Lexeme "<<yytext<<" found\n";
		}

"<="|"<"|">="|">"|"!="|"=="	{

			tokenfile<<"<RELOP, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <RELOP> Lexeme "<<yytext<<" found\n";
		}

"!"		{
			tokenfile<<"<NOT, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <NOT> Lexeme "<<yytext<<" found\n";
		}

"="		{
			tokenfile<<"<ASSIGNOP, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <ASSIGNOP> Lexeme "<<yytext<<" found\n";
		}

"+"|"-"		{
			tokenfile<<"<ADDOP, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <ADDOP> Lexeme "<<yytext<<" found\n";
		}

"*"|"/"|"%"		{
			tokenfile<<"<MULOP, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <MULOP> Lexeme "<<yytext<<" found\n";
		}

"("		{
			tokenfile<<"<LPAREN, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <LPAREN> Lexeme "<<yytext<<" found\n";
		}

")"		{
			tokenfile<<"<RPAREN, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <RPAREN> Lexeme "<<yytext<<" found\n";
		}

"{"		{
			tokenfile<<"<LCURL, "<<yytext<<">\n";
			table->enterScope();
			logfile<<"Line# "<<line_count<<": Token <LCURL> Lexeme "<<yytext<<" found\n";
		}

"}"		{
			tokenfile<<"<RCURL, "<<yytext<<">\n";
			table->exitScope();
			logfile<<"Line# "<<line_count<<": Token <RCURL> Lexeme "<<yytext<<" found\n";
		}

"["		{
			tokenfile<<"<LSQUARE, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <LSQUARE> Lexeme "<<yytext<<" found\n";
		}

"]"		{
			tokenfile<<"<RSQUARE, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <RSQUARE> Lexeme "<<yytext<<" found\n";
		}

","		{
			tokenfile<<"<COMMA, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <COMMA> Lexeme "<<yytext<<" found\n";
		}

";"		{
			tokenfile<<"<SEMICOLON, "<<yytext<<">\n";
			logfile<<"Line# "<<line_count<<": Token <SEMICOLON> Lexeme "<<yytext<<" found\n";
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



<CHECK_CHAR>"\'"		{
			if(!multiChar)
			{
			tokenfile<<"<CONST_CHAR, "<<str<<">\n";
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



<CHECK_CHAR>{NEWLINE}		{

			err_count++;
			logfile<<"Error at line# "<<line_count<<": UNFINISHED_CONST_CHAR ";
			for (char ch : scan) 
				{logfile << ch;}
			logfile<<endl;
			BEGIN INITIAL;
			line_count++;
}

<CHECK_CHAR>"\\\'"			{

			str.append(yytext);
			scan.push_back('\\');
			scan.push_back('\'');
}

<CHECK_CHAR>{CHAR_EXCEPT_QUOTE}		{
			
			if(yytext==";")
			{
				tokenfile<<"<SEMICOLON, "<<yytext<<">\n";
				logfile<<"Line# "<<line_count<<": Token <SEMICOLON> Lexeme "<<yytext<<" found\n";

				err_count++;
				logfile<<"Error at line# "<<line_count<<": UNFINISHED_CONST_CHAR "<<scan[0]<<str<<endl;
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
			tokenfile<<"<SINGLE LINE STRING, "<<str<<">\n";
			logfile<<"Line# "<<startline<<": ";
			logfile<<"Token <SINGLE LINE STRING> Lexeme ";
			for (char ch : scan) 
				{logfile << ch;}
			logfile<<" found\n";
			BEGIN INITIAL;
}

<MULTI_STRING_STATE>"\""		{

			scan.push_back('\"');
			tokenfile<<"<MULTI LINE STRING, "<<str<<">\n";
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
				tokenfile<<"<CONST_INT, "<<yytext<<">\n";
				logfile<<"Line# "<<line_count<<": Token <CONST_INT> Lexeme "<<yytext<<" found\n";
				
			}

{FLOAT} 	{
				tokenfile<<"<CONST_FLOAT, "<<yytext<<">\n";
				logfile<<"Line# "<<line_count<<": Token <CONST_FLOAT> Lexeme "<<yytext<<" found\n";
				//insert in symbol table and print symbol table content(only non empty buckets)
			}



{WHITESPACE}	{}

{IDENTIFIER}	{
				tokenfile<<"<ID, "<<yytext<<">\n";
				logfile<<"Line# "<<line_count<<": Token <ID> Lexeme "<<yytext<<" found\n";
				response = table->insert(yytext,"ID");
				if(response)
				{
					table->printAll(logfile);
				}
				else
				{ logfile<<"\t"<<yytext<<" already exists in the current ScopeTable\n"; }
				
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


int main(int argc,char *argv[]){
	
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

	yyin= fin;
	yylex();
	fclose(yyin);
	table->printAll(logfile);
	logfile<<"Total lines: "<<line_count<<endl;
	logfile<<"Total errors: "<<err_count<<endl;
	logfile<<"Total warnings: "<<warning_count<<endl;
	logfile.close();
	tokenfile.close();
	table = nullptr;

	return 0;
}
