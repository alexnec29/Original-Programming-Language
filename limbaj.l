%{
#include <stdio.h>
#include "limbaj.tab.h"
%}
%option noyywrap
%%

"int"|"float"|"char"|"string"|"bool" {yylval.string = strdup(yytext);return VAR_TYPE;}
"void" {yylval.string = strdup(yytext);return VOID_TYPE;}
"return" {yylval.string = strdup(yytext);return RETURN;}

"class" {return CLASS;}
"private"|"public" {return ACCESS;}

"if" {return IF;}
"while" {return WHILE;}
"else" {return ELSE;}
"elif" {return ELSE_IF;}
"for" {return FOR;}

"true" {return TRUE;}
"false" {return FALSE;}

"Print" {return PRINT;}
"TypeOf" {return TYPEOF;}

"&&" {return AND_OP;}
"||" {return OR_OP;}
"<=" {return MAIMIC_EQ;}
">=" {return MAIMARE_EQ;}
"==" {return EGAL;}
"!=" {return DIFERIT;}
"<" {return MAIMIC;}
">" {return MAIMARE;}

"++" {return(PLUSPLUS);}
"--" {return(MINMIN);}

"=" {return ASSIGN;}
"+=" {return(PLUS_EGAL); }
"-=" {return(MINUS_EGAL); }
"*=" {return(ORI_EGAL); }
"/=" {return(DIV_EGAL); }
"%=" {return(MOD_EGAL); }
"&=" {return(AND_EGAL); }
"|=" {return(OR_EGAL); }

"begin_progr" {return BGIN;}
"end_progr" {return END;}

[a-zA-Z][a-zA-Z0-9]* {yylval.string = strdup(yytext); return ID;}
0|[1-9][0-9]*\.[0-9]+ {
    yylval.floatval = atof(yytext);
    return FLOAT;
}
0|[1-9][0-9]* {
    yylval.intval = atoi(yytext);
    return NR;
}

\"[^\"]*\" {
    yylval.string = strdup(yytext + 1);
    yylval.string[strlen(yylval.string) - 1] = '\0';
    return STRING;
}

\'.\' {
    yylval.charval = yytext[1];
    return CHAR;
}


[ \t] ;
\n {yylineno++;}
. {return yytext[0];}

 
