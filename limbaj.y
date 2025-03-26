%{
#include <iostream>
#include <fstream>
#include <vector>
#include <cstring>
#include "SymTable.h"
ofstream f("debug2.txt");
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
extern int yylex();
void yyerror(const char * s);
class SymTable* current;
class SymTable* global;
class ParamList parameters;
int errorCount = 0;
%}
%union {
     class ASTNode* node;
     class ParamList* param;
     char* string;
     int intval;
     float floatval;
     char charval;
     bool boolVal;
}

%token BGIN END ASSIGN 
%token<intval> NR 
%token<floatval> FLOAT
%token CLASS ACCESS
%token AND_OP OR_OP MAIMIC_EQ MAIMARE_EQ EGAL DIFERIT MAIMIC MAIMARE
%token IF WHILE ELSE ELSE_IF FOR
%token PLUSPLUS MINMIN
%token PLUS_EGAL MINUS_EGAL ORI_EGAL DIV_EGAL MOD_EGAL AND_EGAL OR_EGAL
%token PRINT TYPEOF
%token<bool> TRUE FALSE
%token RETURN
%token<string> ID VAR_TYPE VOID_TYPE STRING
%token<charval> CHAR

%type<node> expression term factor boolean_expression
%type<string> comparison_operator assign_operator
%type<param> call_list

%left OR_OP
%left AND_OP
%nonassoc '!'
%left MAIMIC MAIMARE MAIMIC_EQ MAIMARE_EQ EGAL DIFERIT
%left '+' '-'
%left '*' '/' '%'

%start progr
%%

progr : global_declarations main
      {
          if (errorCount == 0)
              cout << "The program is correct!" << endl;
          current->printVars();
      }
      ;

global_declarations : class_declarations variable_declarations function_declarations 
                   ;

class_declarations : class_decl
                  | class_declarations class_decl
                  ;

class_decl : CLASS ID '{' { SymTable* w = new SymTable(current, $2); current=w; } class_sections '}' { current->printVars(); 
                    if(!global->existsId($2, "class")) {
                         global->addClass($2, current);
                    } else {
                         errorCount++; 
                         yyerror("Class already defined");
                    }  
                    current=current->parent;
               }
               
           ;

function_declarations : function_decl
                     | function_declarations function_decl
                     ;

function_decl : VAR_TYPE ID '(' { SymTable* w = new SymTable(current, $2); current=w; } list_param ')' {
                    if(!global->existsId($2, "function")) {
                         global->addFunction($1, $2, parameters);
                         parameters.clear(); 
                    } else {
                         errorCount++; 
                         yyerror("Function already defined");
                    }          
               } '{' function_statement '}' { 
                    current->printVars(); 
                    current=current->parent; 
               }
            | VAR_TYPE ID '(' ')' '{' { 
                    SymTable* w = new SymTable(current, $2); current=w;
                    if(!global->existsId($2, "function")) {
                         global->addFunction($1, $2, parameters);
                         parameters.clear(); 
                    } else {
                         errorCount++; 
                         yyerror("Function already defined");
                    } 
               } function_statement '}' { 
                    current->printVars(); 
                    current=current->parent; 
               }
            | VOID_TYPE ID '(' { SymTable* w = new SymTable(current, $2); current=w; } list_param ')' {
                    if(!global->existsId($2, "function")) {
                         global->addFunction($1, $2, parameters);
                         parameters.clear(); 
                    } else {
                         errorCount++; 
                         yyerror("Function already defined");
                    } 
               } '{' statements '}' { 
                    current->printVars(); 
                    current=current->parent; 
               }
            | VOID_TYPE ID '(' ')' '{' { 
                    SymTable* w = new SymTable(current, $2); current=w; 
                    if(!global->existsId($2, "function")) {
                         global->addFunction($1, $2, parameters);
                         parameters.clear(); 
                    } else {
                         errorCount++; 
                         yyerror("Function already defined");
                    }  
               } statements '}' { 
                    current->printVars(); 
                    current=current->parent; 
               }
             ;

function_statement: return_statement
                    | statements return_statement;

return_statement: RETURN expression ';' {
                    string functionType = current->name;
                    if (!current->parent->existsId(functionType.c_str(), "function")) {
                        errorCount++;
                        yyerror((string("Function '") + functionType + "' not defined in global scope").c_str());
                    } else {
                        string returnType = current->parent->ids[functionType].type;
                        Value returnValue = $2->evaluate();
                        if (returnType != returnValue.type) {
                            errorCount++;
                            yyerror((string("Return type mismatch: Expected '") + returnType + "', but got '" + returnValue.type + "'").c_str());
                        } else {
                            f << "Return statement: Returned value of type '" << returnType << "' matches the function's return type." << endl;
                        }
                    }
               };
               | RETURN boolean_expression ';' {
                    string functionType = current->name;
                    if (!current->parent->existsId(functionType.c_str(), "function")) {
                        errorCount++;
                        yyerror((string("Function '") + functionType + "' not defined in global scope").c_str());
                    } else {
                        string returnType = current->parent->ids[functionType].type;
                        Value returnValue = $2->evaluate();
                        if (returnType != returnValue.type) {
                            errorCount++;
                            yyerror((string("Return type mismatch: Expected '") + returnType + "', but got '" + returnValue.type + "'").c_str());
                        } else {
                            f << "Return statement: Returned value of type '" << returnType << "' matches the function's return type." << endl;
                        }
                    }
               };

variable_declarations : local_decl
                     | variable_declarations local_decl
                     ;

local_decl : VAR_TYPE ID ';' { 
                    if(!current->existsId($2, "var")) {
                         current->addVar($1,$2);
                         f << "Declared variable '" << $2 << "' of type '" << $1 << "'" << endl;
                    } else {
                         errorCount++; 
                         yyerror("Variable already defined");
                    }
                }
          | VAR_TYPE ID ASSIGN expression ';' {
               if (!current->existsId($2, "var")) {
                    current->addVar($1, $2);
                    f << "Declared variable '" << $2 << "' of type '" << $1 << "'" << endl;
                    Value exprValue = $4->evaluate();
                    if ($1 != exprValue.type) {
                         errorCount++;
                         yyerror("Type mismatch in variable declaration and assignment");
                    } else {
                         current->ids[$2].value = exprValue;
                         f << "Assigned " << (exprValue.type == "int" ? exprValue.getInt() : exprValue.getFloat())
                         << " to variable '" << $2 << "' of type '" << $1 << "'" << endl;
                    }
               } else {
                    errorCount++;
                    yyerror("Variable already defined");
               }
          }
          | VAR_TYPE ID ASSIGN boolean_expression ';' {
               if (!current->existsId($2, "var")) {
                    current->addVar($1, $2);
                    f << "Declared variable '" << $2 << "' of type '" << $1 << "'" << endl;
                    Value exprValue = $4->evaluate();

                    if ($1 != "bool") {
                         errorCount++;
                         yyerror("Type mismatch: Only boolean variables can hold boolean expressions");
                    } else if (exprValue.type != "bool") {
                         errorCount++;
                         yyerror("Expression does not evaluate to a boolean value");
                    } else {
                         current->ids[$2].value = exprValue;

                         f << "Assigned boolean value '" 
                         << (exprValue.getInt() ? "true" : "false")
                         << "' to variable '" << $2 
                         << "' of type '" << $1 << "'" << endl;
                    }
               } else {
                    errorCount++;
                    yyerror("Variable already defined");
               }
               }
          | VAR_TYPE ID '[' NR ']' ';' {
                    if(!current->existsId($2, "vector")) {
                         current->addVector($1,$2, $4);
                    } else {
                         errorCount++; 
                         yyerror("Variable already defined");
                    }
                }
          | ID ID ';' {
               SymTable* globalScope = global;
               if (!globalScope->existsId($1, "class")) {
                    errorCount++; 
                    yyerror((string("Class '") + $1 + "' not defined").c_str());
               } else if (current->existsId($2, "var")) {
                    errorCount++;
                    yyerror((string("Variable '") + $2 + "' already defined").c_str());
               } else {
                    current->addVar($1, $2);
                    f << "Created object '" << $2 << "' of class '" << $1 << "'" << endl;

                    SymTable* classScope = global->getClassScope($1);
                    if (!classScope) {
                         errorCount++;
                         yyerror((string("Class '") + $1 + "' definition not found").c_str());
                    } else {
                         for (const auto& [memberName, memberInfo] : classScope->ids) {
                              string fullMemberName = string($2) + "." + memberName;
                              current->addVar(memberInfo.type.c_str(), fullMemberName.c_str());
                              f << "Added member '" << fullMemberName << "' of type '" << memberInfo.type 
                              << "' to object '" << $2 << "'" << endl;
                         }
                    }
               }
          }
          ;

class_sections : ACCESS ':' class_members
               | class_sections ACCESS ':' class_members
               ;

class_members : class_member
              | class_members class_member
              ;

class_member : VAR_TYPE ID ';' { 
                    if(!current->existsId($2, "var")) {
                         current->addVar($1,$2);
                    } else {
                         errorCount++; 
                         yyerror("Variable already defined");
                    }
                }
               | VAR_TYPE ID ASSIGN expression ';' { 
                    if (!current->existsId($2, "var")) {
                         current->addVar($1, $2);

                         Value exprValue = $4->evaluate();
                         if ($1 != exprValue.type) {
                              errorCount++;
                              yyerror("Type mismatch in variable declaration and assignment");
                         } else {
                              current->ids[$2].value = exprValue;
                              f << "Declared variable '" << $2 << "' of type '" << $1 
                                   << "' with value: " 
                                   << (exprValue.type == "int" ? std::to_string(exprValue.getInt()) :
                                        exprValue.type == "float" ? std::to_string(exprValue.getFloat()) :
                                        exprValue.type == "string" ? "\"" + exprValue.getString() + "\"" :
                                        exprValue.type == "char" ? "'" + std::string(1, exprValue.getChar()) + "'" :
                                        "UNKNOWN")
                                   << " in class '" << current->name << "'" << endl;
                         }
                    } else {
                         errorCount++;
                         yyerror("Variable already defined");
                    }
               }
             | VAR_TYPE ID '(' {
                    SymTable* w = new SymTable(current, $2); current=w; current->parent->addFunction($1, $2, parameters);
               } list_param  ')' '{' function_statement '}' {
                    current->parent->addFunction($1, $2, parameters);
                    parameters.clear();
                    current = current->parent;
                    f << "Added member function '" << $2 << "' of type '" << $1 
                      << "' to class '" << current->name << "'" << endl;
               }
             | VAR_TYPE ID '(' ')' '{' {
                    SymTable* w = new SymTable(current, $2); current=w; current->parent->addFunction($1, $2, parameters);
               } function_statement '}' {
                    current = current->parent;
                    f << "Added member function '" << $2 << "' of type '" << $1 
                      << "' to class '" << current->name << "'" << endl;
               }
             | VOID_TYPE ID '(' {
                    SymTable* w = new SymTable(current, $2); current=w;
               } list_param ')' '{' statements '}' {
                    current->parent->addFunction("void", $2, parameters);
                    parameters.clear();
                    current = current->parent;
                    f << "Added void member function '" << $2 
                      << "' to class '" << current->name << "'" << endl;
               }
             | VOID_TYPE ID '(' ')' '{' {
                    SymTable* w = new SymTable(current, $2); current=w;
               } statements '}' { 
                    current->parent->addFunction("void", $2, parameters);
                    current = current->parent;
                    f << "Added void member function '" << $2 
                      << "' to class '" << current->name << "'" << endl;
               }
             ;

list_param : param
           | list_param ',' param
           ;

param : VAR_TYPE ID { 
                    if(!current->existsId($2, "var")) {
                         current->addVar($1,$2);
                         parameters.addParam($1,$2);
                    } else {
                         errorCount++; 
                         yyerror("Variable already defined");
                    }
                }
      ;

main : BGIN { SymTable* w = new SymTable(current, "main"); current=w; }statements END{ current->printVars(); current=current->parent; }
     ;

statements : statement
           | statements statement
           ;

statement : assignment ';'
          | local_decl
          | if_statement
          | while_statement
          | for_statement
          | ID '.' ID ASSIGN expression ';' { 
               SymTable* table = current; 
               bool variableFound = false;

               while (table != nullptr) {
                    if (table->existsId($1, "var")) {
                         variableFound = true;
                         string varType = table->ids[$1].type;

                         SymTable* classScope = global->getClassScope(varType.c_str());
                         if (!classScope) {
                              errorCount++;
                              yyerror((string("Variable '") + $1 + "' is not of a valid class type").c_str());
                         } else {
                              string fullMemberName = string($1) + "." + string($3);

                              if (!classScope->existsId($3, "var")) {
                                   errorCount++;
                                   yyerror((string("Member '") + $3 + "' not defined in class '" + varType + "'").c_str());
                              } else {
                                   string memberType = classScope->ids[$3].type;
                                   Value exprValue = $5->evaluate();

                                   if (memberType != exprValue.type) {
                                   errorCount++;
                                   yyerror((string("Type mismatch: Cannot assign value of type '") +
                                             exprValue.type + "' to member '" + $3 + "' of type '" + memberType + "'").c_str());
                                   } else {
                                   classScope->ids[$3].value = exprValue;

                                   f << "Assigned value to member '" << $3
                                        << "' of object '" << $1
                                        << "' with value: "
                                        << (exprValue.type == "int" ? exprValue.getInt() : exprValue.getFloat())
                                        << " and type: " << exprValue.type << endl;
                                   }
                              }
                         }
                         break;
                    }
                    table = table->parent;
               }

               if (!variableFound) {
                    errorCount++;
                    yyerror((string("Variable '") + $1 + "' not defined in any accessible scope").c_str());
               }
          }
          | ID '.' ID ASSIGN boolean_expression ';' { 
               SymTable* table = current; 
               bool variableFound = false;

               while (table != nullptr) {
                    if (table->existsId($1, "var")) {
                         variableFound = true;
                         string varType = table->ids[$1].type;

                         SymTable* classScope = global->getClassScope(varType.c_str());
                         if (!classScope) {
                              errorCount++;
                              yyerror((string("Variable '") + $1 + "' is not of a valid class type").c_str());
                         } else {
                              string fullMemberName = string($1) + "." + string($3);

                              if (!classScope->existsId($3, "var")) {
                                   errorCount++;
                                   yyerror((string("Member '") + $3 + "' not defined in class '" + varType + "'").c_str());
                              } else {
                                   string memberType = classScope->ids[$3].type;
                                   Value exprValue = $5->evaluate();

                                   if (memberType != exprValue.type) {
                                   errorCount++;
                                   yyerror((string("Type mismatch: Cannot assign value of type '") +
                                             exprValue.type + "' to member '" + $3 + "' of type '" + memberType + "'").c_str());
                                   } else {
                                   classScope->ids[$3].value = exprValue;

                                   f << "Assigned value to member '" << $3
                                        << "' of object '" << $1
                                        << "' with value: "
                                        << (exprValue.type == "int" ? exprValue.getInt() : exprValue.getFloat())
                                        << " and type: " << exprValue.type << endl;
                                   }
                              }
                         }
                         break;
                    }
                    table = table->parent;
               }

               if (!variableFound) {
                    errorCount++;
                    yyerror((string("Variable '") + $1 + "' not defined in any accessible scope").c_str());
               }
          }
          | ID PLUSPLUS ';' { 
               SymTable* table = current;
               bool variableFound = false;

               while (table != nullptr) {
                    if (table->existsId($1, "var")) {
                         variableFound = true;

                         Value& varValue = table->ids[$1].value;

                         if (varValue.type != "int" && varValue.type != "float") {
                              errorCount++;
                              yyerror("Type mismatch: Increment operation is only valid for integers or floats");
                         } else {
                              if (varValue.type == "int") {
                                   int currentValue = varValue.getInt();
                                   varValue = Value(currentValue + 1, "int");
                              } else if (varValue.type == "float") {
                                   float currentValue = varValue.getFloat();
                                   varValue = Value(currentValue + 1.0f, "float");
                              }
                         }

                         break;
                    }

                    table = table->parent;
               }

               if (!variableFound) {
                    errorCount++;
                    yyerror("Variable not defined in any accessible scope");
               }
               }
               | PLUSPLUS ID ';' { 
               SymTable* table = current;
               bool variableFound = false;

               while (table != nullptr) {
                    if (table->existsId($2, "var")) {
                         variableFound = true;

                         Value& varValue = table->ids[$2].value;

                         if (varValue.type != "int" && varValue.type != "float") {
                              errorCount++;
                              yyerror("Type mismatch: Increment operation is only valid for integers or floats");
                         } else {
                              if (varValue.type == "int") {
                                   int currentValue = varValue.getInt();
                                   varValue = Value(currentValue + 1, "int");
                              } else if (varValue.type == "float") {
                                   float currentValue = varValue.getFloat();
                                   varValue = Value(currentValue + 1.0f, "float");
                              }
                         }

                         break;
                    }

                    table = table->parent;
               }

               if (!variableFound) {
                    errorCount++;
                    yyerror("Variable not defined in any accessible scope");
               }
               }
               | ID MINMIN ';' { 
               SymTable* table = current;
               bool variableFound = false;

               while (table != nullptr) {
                    if (table->existsId($1, "var")) {
                         variableFound = true;

                         Value& varValue = table->ids[$1].value;

                         if (varValue.type != "int" && varValue.type != "float") {
                              errorCount++;
                              yyerror("Type mismatch: Decrement operation is only valid for integers or floats");
                         } else {
                              if (varValue.type == "int") {
                                   int currentValue = varValue.getInt();
                                   varValue = Value(currentValue - 1, "int");
                              } else if (varValue.type == "float") {
                                   float currentValue = varValue.getFloat();
                                   varValue = Value(currentValue - 1.0f, "float");
                              }
                         }

                         break;
                    }

                    table = table->parent;
               }

               if (!variableFound) {
                    errorCount++;
                    yyerror("Variable not defined in any accessible scope");
               }
               }
               | MINMIN ID ';' { 
               SymTable* table = current;
               bool variableFound = false;

               while (table != nullptr) {
                    if (table->existsId($2, "var")) {
                         variableFound = true;

                         Value& varValue = table->ids[$2].value;

                         if (varValue.type != "int" && varValue.type != "float") {
                              errorCount++;
                              yyerror("Type mismatch: Decrement operation is only valid for integers or floats");
                         } else {
                              if (varValue.type == "int") {
                                   int currentValue = varValue.getInt();
                                   varValue = Value(currentValue - 1, "int");
                              } else if (varValue.type == "float") {
                                   float currentValue = varValue.getFloat();
                                   varValue = Value(currentValue - 1.0f, "float");
                              }
                         }

                         break;
                    }

                    table = table->parent;
               }

               if (!variableFound) {
                    errorCount++;
                    yyerror("Variable not defined in any accessible scope");
               }
          }

          | ID '(' call_list ')' ';' { 
                    SymTable* globalScope = global;
                    if (!globalScope->existsId($1, "function")) {
                         errorCount++;
                         yyerror((string("Function '") + $1 + "' not defined in the global scope").c_str());
                    } else {
                         IdInfo functionInfo = globalScope->ids[$1];
                         ParamList expectedParams = functionInfo.params;

                         ParamList* providedParams = $3;
                         if (expectedParams.params.size() != providedParams->params.size()) {
                              errorCount++;
                              yyerror((string("Function '") + $1 + "' parameter count mismatch").c_str());
                         } else {
                              for (size_t i = 0; i < expectedParams.params.size(); ++i) {
                                   if (expectedParams.params[i].type != providedParams->params[i].type) {
                                        errorCount++;
                                        yyerror((string("Function '") + $1 + "' parameter type mismatch at position " 
                                             + to_string(i + 1)).c_str());
                                        break;
                                   }
                              }
                         }

                         if (functionInfo.type != "void") {
                              errorCount++;
                              yyerror((string("Function '") + $1 + "' must be of type 'void' when called without returning a value").c_str());
                         }

                         delete providedParams;
                    }
               }
               | ID '(' ')' ';' { 
               SymTable* globalScope = global;
               if (!globalScope->existsId($1, "function")) {
                    errorCount++;
                    yyerror((string("Function '") + $1 + "' not defined in the global scope").c_str());
               } else {
                    IdInfo functionInfo = globalScope->ids[$1];
                    ParamList expectedParams = functionInfo.params;
                    if (!expectedParams.params.empty()) {
                         errorCount++;
                         yyerror((string("Function '") + $1 + "' expects parameters, but none were provided").c_str());
                    }

                    if (functionInfo.type != "void") {
                         errorCount++;
                         yyerror((string("Function '") + $1 + "' must be of type 'void' when called without returning a value").c_str());
                    }
               }
          }
          | PRINT '(' expression ')' ';' {
                    Value result = $3->evaluate();

                    f << "Evaluated expression with type: " << result.type << endl;

                    if (result.type.empty() || result.type == "unknown") {
                         yyerror("Print error - Value has an unknown or invalid type");
                         errorCount++;
                    }

                    if (result.type == "int") {
                         cout << "Print: " << result.getInt() << endl;
                    } else if (result.type == "float") {
                         cout << "Print: " << result.getFloat() << endl;
                    } else if (result.type == "bool") {
                         cout << "Print: " << (result.getInt() == 1 ? "TRUE" : "FALSE") << endl;
                    } else if (result.type == "string") {
                         cout << "Print: " << result.getString() << endl;
                    } else if (result.type == "char") {
                         cout << "Print: " << result.getChar() << endl;
                    } else {
                         yyerror("Print error - Unsupported type for expression.");
                         errorCount++;
                    }
                    }
          | PRINT '(' boolean_expression ')' ';' {
               Value result = $3->evaluate();
               f << "Evaluated boolean expression with type: " << result.type << endl;
               if (result.type != "bool") {
                    yyerror("Print error: Unsupported type for boolean expression.");
                    errorCount++;
               } 
               else {
                    cout << "Print: " << (result.getInt() ? "TRUE" : "FALSE") << endl;
               }
          }
          | TYPEOF '(' expression ')' ';' {
                    Value result = $3->evaluate();
                    f << "Evaluated expression with type: " << result.type << endl;
                    if (result.type == "int") {
                         cout << "Type: int" << endl;
                    } else if (result.type == "float") {
                         cout << "Type: float" << endl;
                    } else if (result.type == "string") {
                         cout << "Type: string" << endl;
                    } else if (result.type == "char") {
                         cout << "Type: char" << result.getChar() << endl;
                    } else {
                         yyerror("TYPEOF error: Unsupported type for expression");
                    }
               }
               | TYPEOF '(' boolean_expression ')' ';' {
                    Value result = $3->evaluate();
                    f << "Evaluated boolean expression with type: " << result.type << endl;

                    if (result.type == "bool") {
                         cout << "Type: bool" << endl;
                    } else {
                         yyerror("TYPEOF error: Unsupported type for boolean expression");
                    }
               }
          ;

assignment : ID assign_operator expression { 
                    SymTable* table = current;
                    bool variableFound = false;
                    while (table != nullptr) {
                         if (table->existsId($1, "var")) {
                              variableFound = true;
                              string varType = table->ids[$1].type;
                              Value currentValue = table->ids[$1].value;
                              Value exprValue = $3->evaluate();
                              if (varType != exprValue.type) {
                                   errorCount++;
                                   yyerror("Type mismatch in assignment operation");
                              } else {
                                   Value result;

                                   if (string($2) == "+=") {
                                        result = (varType == "int")
                                                  ? Value(currentValue.getInt() + exprValue.getInt(), "int")
                                                  : Value(currentValue.getFloat() + exprValue.getFloat(), "float");
                                   } else if (string($2) == "-=") {
                                        result = (varType == "int")
                                                  ? Value(currentValue.getInt() - exprValue.getInt(), "int")
                                                  : Value(currentValue.getFloat() - exprValue.getFloat(), "float");
                                   } else if (string($2) == "*=") {
                                        result = (varType == "int")
                                                  ? Value(currentValue.getInt() * exprValue.getInt(), "int")
                                                  : Value(currentValue.getFloat() * exprValue.getFloat(), "float");
                                   } else if (string($2) == "/=") {
                                        if ((varType == "int" && exprValue.getInt() == 0) || 
                                             (varType == "float" && exprValue.getFloat() == 0.0)) {
                                             errorCount++;
                                             yyerror("Division by zero");
                                        } else {
                                        result = (varType == "int")
                                                  ? Value(currentValue.getInt() / exprValue.getInt(), "int")
                                                  : Value(currentValue.getFloat() / exprValue.getFloat(), "float");
                                        }
                                   } else if (string($2) == "%=") {
                                        if (varType != "int") {
                                             errorCount++;
                                             yyerror("Modulo operation is only valid for integers");
                                        } else {
                                             result = Value(currentValue.getInt() % exprValue.getInt(), "int");
                                        }
                                   }

                                   table->ids[$1].value = result;

                                   f << "Updated variable '" << $1 << "' with result: "
                                   << (result.type == "int" ? result.getInt() : result.getFloat())
                                   << " using operator '" << $2 << "'" << " in scope '" << table->name << "'" << endl;
                              }

                              break;
                         }

                         table = table->parent;
                    }

                    if (!variableFound) {
                         errorCount++;
                         yyerror("Variable not defined in any accessible scope");
                    }
               }
               | ID ASSIGN expression { 
                    SymTable* table = current;
                    bool variableFound = false;

                    while (table != nullptr) {
                         if (table->existsId($1, "var")) {
                              variableFound = true;
                              string varType = table->ids[$1].type;
                              Value exprValue = $3->evaluate();

                              if (exprValue.type.empty() || exprValue.type == "unknown") {
                                   errorCount++;
                                   yyerror("Expression evaluated to an unknown or invalid type");
                              } 
                              else if (varType != exprValue.type) {
                                   errorCount++;
                                   yyerror("Type mismatch in assignment");
                              } 
                              else {
                                   table->ids[$1].value = exprValue;

                                   if (varType == "int") {
                                        f << "Assigned " << exprValue.getInt()
                                        << " to variable '" << $1 << "' of type 'int' in scope '" << table->name << "'" << endl;
                                   } 
                                   else if (varType == "float") {
                                        f << "Assigned " << exprValue.getFloat()
                                        << " to variable '" << $1 << "' of type 'float' in scope '" << table->name << "'" << endl;
                                   } 
                                   else if (varType == "bool") {
                                        f << "Assigned " << (exprValue.getInt() ? "TRUE" : "FALSE")
                                        << " to variable '" << $1 << "' of type 'bool' in scope '" << table->name << "'" << endl;
                                   } 
                                   else if (varType == "string") {
                                        f << "Assigned \"" << exprValue.getString()
                                        << "\" to variable '" << $1 << "' of type 'string' in scope '" << table->name << "'" << endl;
                                   } 
                                   else if (varType == "char") {
                                        f << "Assigned '" << exprValue.getChar()
                                        << "' to variable '" << $1 << "' of type 'char' in scope '" << table->name << "'" << endl;
                                   }
                              }

                              break;
                         }
                         table = table->parent;
                    }
                    if (!variableFound) {
                         errorCount++;
                         yyerror("Variable not defined in any accessible scope");
                    }
                    }
          | ID ASSIGN boolean_expression {
               SymTable* table = current;
               bool variableFound = false;

               while (table != nullptr) {
                      if (table->existsId($1, "var")) {
                           variableFound = true; 
                           string varType = table->ids[$1].type;
                           Value exprValue = $3->evaluate();
                           if (exprValue.type != "bool") {
                                errorCount++;
                                yyerror("Type mismatch: Expected a boolean type");
                           } 
                           else if (varType != exprValue.type) {
                                  errorCount++;
                                  yyerror("Type mismatch in assignment");
                           } 
                           else {
                                    table->ids[$1].value = exprValue;

                                    f << "Assigned " 
                                    << (exprValue.type == "int" ? exprValue.getInt() : exprValue.getFloat())
                                    << " to variable '" << $1 << "' of type '" << varType 
                                    << "' in scope '" << table->name << "'" << endl;
                            }

                            break;
                         }
                         table = table->parent;
                   }
                   if (!variableFound) {
                        errorCount++;
                        yyerror("Variable not defined in any accessible scope");
                   }
               }
          | ID '[' NR ']' assign_operator expression { 
                    if(!current->existsIdAll($1, "vector")) {
                         errorCount++; 
                         yyerror("Variable not defined");
                    }
                }
          | ID '[' NR ']' ASSIGN expression  { 
                    if(!current->existsIdAll($1, "vector")) {
                         errorCount++; 
                         yyerror("Variable not defined");
                    }
                }
          ;

assign_operator : PLUS_EGAL { $$ = strdup("+="); }
               | MINUS_EGAL { $$ = strdup("-="); }
               | OR_EGAL { $$ = strdup("|="); }
               | AND_EGAL { $$ = strdup("&="); }
               | ORI_EGAL { $$ = strdup("*="); }
               | DIV_EGAL { $$ = strdup("/="); }
               | MOD_EGAL { $$ = strdup("%="); }

if_statement: IF '(' boolean_expression ')' block {
                    if ($3->type != "bool") {
                         yyerror("Type mismatch: Expected a boolean expression in 'if' condition");
                         errorCount++;
                    } else {
                         f << "Valid 'if' condition of type: " << $3->type << endl;
                    }
               }
            | IF '(' boolean_expression ')' block ELSE block {
                    if ($3->type != "bool") {
                         yyerror("Type mismatch: Expected a boolean expression in 'if' condition");
                         errorCount++;
                    } else {
                         f << "Valid 'if-else' condition of type: " << $3->type << endl;
                    }
               }
            ;

block: '{' {SymTable* w = new SymTable(current, "block"); current=w;} statements '}' {/*current->printVars();*/ current = current->parent;}
     | '{' '}'

for_statement: FOR '(' for_assignments '|' boolean_expression '|' for_assignments ')' block
               ;

for_assignments: assignment
               | assignment ',' for_assignments
               ;    

while_statement: WHILE '(' boolean_expression ')' block
               ;

expression: term {
               $$ = $1;
          }
          | expression '+' term{
               if ($1->type != $3->type) {
                   yyerror("Type mismatch in '+' operation");
                   errorCount++;
               }
               $$ = new ASTNode("+");
               $$->left = $1;
               $$->right = $3;
               $$->type = $1->type;
          }
          | expression '-' term{
               if ($1->type != $3->type) {
                   yyerror("Type mismatch in '-' operation");
                   errorCount++;
               }
               $$ = new ASTNode("-");
               $$->left = $1;
               $$->right = $3;
               $$->type = $1->type;
          }

term: factor {
               $$ = $1;
          }
    | term '*' factor{
               if ($1->type != $3->type) {
                   yyerror("Type mismatch in '*' operation");
                   errorCount++;
               }
               $$ = new ASTNode("*");
               $$->left = $1;
               $$->right = $3;
               $$->type = $1->type;
          }
    | term '/' factor{
               if ($1->type != $3->type) {
                   yyerror("Type mismatch in '/' operation");
                   errorCount++;
               }
               $$ = new ASTNode("/");
               $$->left = $1;
               $$->right = $3;
               $$->type = $1->type;
          }
    | term '%' factor{
               if ($1->type != "int" || $3->type != "int") {
                   yyerror("Modulo operation is only valid for integers");
                   errorCount++;
               }
               $$ = new ASTNode("%");
               $$->left = $1;
               $$->right = $3;
               $$->type = $1->type;
          };

factor: '(' expression ')' {
          $$ = $2;
      }
      | ID '[' expression ']' {
               SymTable* table = current;
               bool found = false;

               while (table != nullptr) {
                    if (table->existsId($1, "vector")) {
                         string varType = table->ids[$1].type;
                         int vectorSize = table->ids[$1].size;
                         Value defaultValue;

                         Value indexValue = $3->evaluate();

                         if (indexValue.type != "int") {
                              errorCount++;
                              yyerror((string("Index for vector '") + $1 + "' must be of type 'int'").c_str());
                              $$ = nullptr;
                              break;
                         }

                         int index = indexValue.getInt();

                         if (index < 0 || index >= vectorSize) {
                              errorCount++;
                              yyerror((string("Index out of bounds for vector '") + $1 +
                                        "'. Valid range is [0, " + to_string(vectorSize - 1) + "]").c_str());
                              $$ = nullptr;
                              break;
                         }

                         if (varType == "int") {
                              defaultValue = Value(0, "int");
                              $$ = new ASTNode("int", defaultValue);
                         } else if (varType == "float") {
                              defaultValue = Value(static_cast<float>(0.0), "float");
                              $$ = new ASTNode("float", defaultValue);
                         } else {
                              yyerror((string("Unsupported type for vector '") + $1 + "'").c_str());
                              errorCount++;
                              $$ = nullptr;
                              break;
                         }

                         $$->type = varType;

                         f << "Vector '" << $1 << "' found with type: " << varType
                         << " and accessing index: " << index << endl;

                         found = true;
                         break;
                    }

                    table = table->parent;
               }

               if (!found) {
                    yyerror((string("Vector '") + $1 + "' not defined in any accessible scope").c_str());
                    errorCount++;
                    $$ = nullptr;
               }
               }
      | ID '(' call_list ')' {
               SymTable* globalScope = global;
               if (!globalScope->existsId($1, "function")) {
                    errorCount++;
                    yyerror((string("Function '") + $1 + "' not defined in global scope").c_str());
               } else {
                    ParamList expectedParams = globalScope->ids[$1].params;
                    ParamList* providedParams = $3;

                    if (expectedParams.params.size() != providedParams->params.size()) {
                         errorCount++;
                         yyerror((string("Function '") + $1 + "' parameter count mismatch").c_str());
                    } else {
                         for (size_t i = 0; i < expectedParams.params.size(); ++i) {
                              if (expectedParams.params[i].type != providedParams->params[i].type) {
                                   errorCount++;
                                   yyerror((string("Function '") + $1 + "' parameter type mismatch at position " + to_string(i + 1)).c_str());
                                   break;
                              }
                         }
                    }
                    delete providedParams;
                    string functionType = globalScope->ids[$1].type;
                    if (functionType == "int") {
                         $$ = new ASTNode("int", Value(0, "int"));
                    } else if (functionType == "float") {
                         $$ = new ASTNode("float", Value(static_cast<float>(0.0), "float"));
                    } else if (functionType == "char") {
                         $$ = new ASTNode("char", Value('0', "char"));
                    } else if (functionType == "string") {
                         $$ = new ASTNode("string", Value("0", "string"));
                    } else {
                         errorCount++;
                         yyerror((string("Function '") + $1 + "' has an unsupported return type").c_str());
                         $$ = nullptr;
                    }
               }
          }
          | ID '(' ')' {
               SymTable* globalScope = global;
               if (!globalScope->existsId($1, "function")) {
                    errorCount++;
                    yyerror((string("Function '") + $1 + "' not defined in global scope").c_str());
               } else {
                    ParamList expectedParams = globalScope->ids[$1].params;

                    if (!expectedParams.params.empty()) {
                         errorCount++;
                         yyerror((string("Function '") + $1 + "' expects parameters but none were provided").c_str());
                    }
                    string functionType = globalScope->ids[$1].type;
                    if (functionType == "int") {
                         $$ = new ASTNode("int", Value(0, "int"));
                    } else if (functionType == "float") {
                         $$ = new ASTNode("float", Value(static_cast<float>(0.0), "float"));
                    } else {
                         errorCount++;
                         yyerror((string("Function '") + $1 + "' has an unsupported return type").c_str());
                         $$ = nullptr;
                    }
               }
          }
      | NR {
          Value intValue($1, "int");
          $$ = new ASTNode("int", intValue);
          $$->type = "int";
      }
      | ID {
          SymTable* table=current;
          bool found = false;
          while(table!=nullptr){
               if(table->existsId($1,"var")){
                    $$ = new ASTNode($1, "id", table);
                    $$->type = table->ids[$1].type;
                    $$->value = table->ids[$1].value;
                    f << "Variable '" << $1 << "' found with type: " << $$->type
                         << " and value: " << ($$->value.type == "int" ? $$->value.getInt() : $$->value.getFloat())
                         << endl;
                    found = true;
                    break;
               }
               table=table->parent;
          }
          if (!found) {
               yyerror("Variable not defined");
               errorCount++;
               $$ = nullptr;
          }
      }
      | STRING {
          Value stringValue($1, "string");
          $$ = new ASTNode("string", stringValue);
          $$->type = "string";
          f << "Recognized string literal with value: \"" << $1 << "\"" << endl;
      }
      | CHAR {
          Value charValue($1, "char");
          $$ = new ASTNode("char", charValue);
          $$->type = "char";
          f << "Recognized char literal with value: '" << $1 << "'" << endl;
     }
      | FLOAT {
          Value floatValue($1, "float");
          $$ = new ASTNode("float", floatValue);
          $$->type = "float";
      }
      | ID '.' ID {
               SymTable* table = current;
               bool found = false;

               while (table != nullptr) {
                    if (table->existsId($1, "var")) {
                         string varType = table->ids[$1].type;

                         SymTable* classScope = global->getClassScope(varType.c_str());
                         if (!classScope) {
                              string errorMsg = "Variable '" + string($1) + "' is not of a valid class type";
                              yyerror(errorMsg.c_str());
                              errorCount++;
                              $$ = nullptr;
                              break;
                         }

                         string fullMemberName = string($1) + "." + string($3);

                         if (!table->existsId(fullMemberName.c_str(), "var")) {
                              string errorMsg = "Member '" + string($3) + "' not found in object '" + string($1) + "'";
                              yyerror(errorMsg.c_str());
                              errorCount++;
                              $$ = nullptr;
                              break;
                         }
                         string memberType = table->ids[fullMemberName].type;
                         Value memberValue = table->ids[fullMemberName].value;

                         if (memberType == "int") {
                              $$ = new ASTNode("int", memberValue);
                              $$->type = "int";
                         } else if (memberType == "float") {
                              $$ = new ASTNode("float", memberValue);
                              $$->type = "float";
                         } else {
                              string errorMsg = "Unsupported type for member '" + string($3) + "'";
                              yyerror(errorMsg.c_str());
                              errorCount++;
                              $$ = nullptr;
                         }

                         found = true;
                         break;
                    }

                    table = table->parent;
               }

               if (!found) {
                    string errorMsg = "Variable '" + string($1) + "' not defined in any accessible scope";
                    yyerror(errorMsg.c_str());
                    errorCount++;
                    $$ = nullptr;
               }
               }
          | ID '.' ID '(' call_list ')' {
               SymTable* table = current;
               bool found = false;

               while (table != nullptr) {
                    if (table->existsId($1, "var")) {
                         string varType = table->ids[$1].type;
                         SymTable* classScope = global->getClassScope(varType.c_str());
                         if (!classScope) {
                              string errorMsg = "Variable '" + string($1) + "' is not of a valid class type";
                              yyerror(errorMsg.c_str());
                              errorCount++;
                              $$ = nullptr;
                              break;
                         }
                         if (!classScope->existsId($3, "function")) {
                              string errorMsg = "Method '" + string($3) + "' not found in class '" + varType + "'";
                              yyerror(errorMsg.c_str());
                              errorCount++;
                              $$ = nullptr;
                              break;
                         }
                         IdInfo& methodInfo = classScope->ids[$3];
                         ParamList expectedParams = methodInfo.params;
                         ParamList* providedParams = $5;

                         if (expectedParams.params.size() != providedParams->params.size()) {
                              string errorMsg = "Method '" + string($3) +
                                                  "' parameter count mismatch. Expected " + to_string(expectedParams.params.size()) +
                                                  ", but got " + to_string(providedParams->params.size());
                              yyerror(errorMsg.c_str());
                              errorCount++;
                              $$ = nullptr;
                              break;
                         }
                         for (size_t i = 0; i < expectedParams.params.size(); ++i) {
                              if (expectedParams.params[i].type != providedParams->params[i].type) {
                                   string errorMsg = "Method '" + string($3) +
                                                       "' parameter type mismatch at position " + to_string(i + 1) +
                                                       ". Expected '" + expectedParams.params[i].type + "', but got '" +
                                                       providedParams->params[i].type + "'";
                                   yyerror(errorMsg.c_str());
                                   errorCount++;
                                   $$ = nullptr;
                                   break;
                              }
                         }
                         string methodType = methodInfo.type;
                         if (methodType == "int") {
                              $$ = new ASTNode("int", Value(0, "int"));
                              $$->type = "int";
                         } else if (methodType == "float") {
                              $$ = new ASTNode("float", Value(0.0f, "float"));
                              $$->type = "float";
                         } else if (methodType == "void") {
                              $$ = new ASTNode("void", Value());
                              $$->type = "void";
                         } else {
                              string errorMsg = "Unsupported return type for method '" + string($3) + "'";
                              yyerror(errorMsg.c_str());
                              errorCount++;
                              $$ = nullptr;
                              break;
                         }

                         found = true;
                         break;
                    }

                    table = table->parent;
               }

               if (!found) {
                    string errorMsg = "Variable '" + string($1) + "' not defined in any accessible scope";
                    yyerror(errorMsg.c_str());
                    errorCount++;
                    $$ = nullptr;
               }
          };

boolean_expression : expression comparison_operator expression {
                    if ($1->type != $3->type) {
                         yyerror("Type mismatch: Cannot compare values of different types in a boolean expression");
                         errorCount++;
                         $$ = nullptr;
                    } else if ($1->type != "int" && $1->type != "float") {
                         yyerror("Invalid types: Comparison operators can only be used with int or float");
                         errorCount++;
                         $$ = nullptr;
                    } else {
                         $$ = new ASTNode($2);
                         $$->left = $1;
                         $$->right = $3;
                         $$->type = "bool";
                         f << "Valid comparison between values of type: " << $1->type << endl;
                    }
               }
               | boolean_expression EGAL boolean_expression {
                         if ($1->type != "bool" || $3->type != "bool") {
                         yyerror("Comparison is only allowed between boolean expressions");
                         errorCount++;
                         $$ = nullptr;
                         } else {
                         $$ = new ASTNode("==");
                         $$->left = $1;
                         $$->right = $3;
                         $$->type = "bool";
                         }
                    }
               | boolean_expression DIFERIT boolean_expression {
                         if ($1->type != "bool" || $3->type != "bool") {
                         yyerror("Comparison is only allowed between boolean expressions");
                         errorCount++;
                         $$ = nullptr;
                         } else {
                         $$ = new ASTNode("!=");
                         $$->left = $1;
                         $$->right = $3;
                         $$->type = "bool";
                         }
                    }
               | boolean_expression AND_OP boolean_expression {
                    $$ = new ASTNode("&&");
                    $$->left = $1;
                    $$->right = $3;
                    $$->type = "bool";
               }
               | boolean_expression OR_OP boolean_expression {
                    $$ = new ASTNode("||");
                    $$->left = $1;
                    $$->right = $3;
                    $$->type = "bool";
               }
               | '!' '(' boolean_expression ')' {
                    $$ = new ASTNode("!");
                    $$->left = $3;
                    $$->type = "bool";
               }
               | '(' boolean_expression ')' {
                    $$ = $2;
               }
               | TRUE {
                    Value trueValue(1, "bool");
                    $$ = new ASTNode("bool", trueValue);
                    $$->type = "bool";
               }
               | FALSE {
                    Value falseValue(0, "bool");
                    $$ = new ASTNode("bool", falseValue);
                    $$->type = "bool";
               }
               | ID '?' {
                    SymTable* table = current;
                    bool found = false;

                    while (table != nullptr) {
                         if (table->existsId($1, "var")) {
                              if (table->ids[$1].type != "bool") {
                                   yyerror((string("Type mismatch: Expected a boolean variable for '") + $1 + "'").c_str());
                                   errorCount++;
                                   $$ = nullptr;
                                   break;
                              }

                              $$ = new ASTNode($1, "bool", table);
                              $$->type = "bool";
                              $$->value = table->ids[$1].value;

                              f << "Boolean variable '" << $1 << "' found with value: "
                                        << ($$->value.getInt() ? "TRUE" : "FALSE") << endl;

                              found = true;
                              break;
                         }

                         table = table->parent;
                    }

                    if (!found) {
                         yyerror((string("Boolean variable '") + $1 + "' not defined in any accessible scope").c_str());
                         errorCount++;
                         $$ = nullptr;
                    }
               }
               | ID '.' ID '?' {
               SymTable* table = current;
               bool found = false;

               while (table != nullptr) {
                    if (table->existsId($1, "var")) {
                         string varType = table->ids[$1].type;

                         SymTable* classScope = global->getClassScope(varType.c_str());
                         if (!classScope) {
                              string errorMsg = "Variable '" + string($1) + "' is not of a valid class type";
                              yyerror(errorMsg.c_str());
                              errorCount++;
                              $$ = nullptr;
                              break;
                         }

                         string fullMemberName = string($1) + "." + string($3);
                         if (!table->existsId(fullMemberName.c_str(), "var")) {
                              string errorMsg = "Member '" + string($3) + "' not found in object '" + string($1) + "'";
                              yyerror(errorMsg.c_str());
                              errorCount++;
                              $$ = nullptr;
                              break;
                         }
                         string memberType = table->ids[fullMemberName].type;
                         Value memberValue = table->ids[fullMemberName].value;

                         if (memberType == "bool") {
                              $$ = new ASTNode("bool", memberValue);
                              $$->type = "bool";
                              }
                         else {
                              string errorMsg = "Unsupported type for member '" + string($3) + "'";
                              yyerror(errorMsg.c_str());
                              errorCount++;
                              $$ = nullptr;
                         }

                         found = true;
                         break;
                    }

                    table = table->parent;
               }

               if (!found) {
                    string errorMsg = "Variable '" + string($1) + "' not defined in any accessible scope";
                    yyerror(errorMsg.c_str());
                    errorCount++;
                    $$ = nullptr;
               }
               }
          | ID '.' ID '(' call_list ')' '?'{
                    SymTable* table = current;
                    bool found = false;

                    while (table != nullptr) {
                         if (table->existsId($1, "var")) {
                              string varType = table->ids[$1].type;
                              SymTable* classScope = global->getClassScope(varType.c_str());
                              if (!classScope) {
                                   string errorMsg = "Variable '" + string($1) + "' is not of a valid class type";
                                   yyerror(errorMsg.c_str());
                                   errorCount++;
                                   $$ = nullptr;
                                   break;
                              }
                              if (!classScope->existsId($3, "function")) {
                                   string errorMsg = "Method '" + string($3) + "' not found in class '" + varType + "'";
                                   yyerror(errorMsg.c_str());
                                   errorCount++;
                                   $$ = nullptr;
                                   break;
                              }
                              IdInfo& methodInfo = classScope->ids[$3];
                              ParamList expectedParams = methodInfo.params;
                              ParamList* providedParams = $5;

                              if (expectedParams.params.size() != providedParams->params.size()) {
                                   string errorMsg = "Method '" + string($3) +
                                                       "' parameter count mismatch. Expected " + to_string(expectedParams.params.size()) +
                                                       ", but got " + to_string(providedParams->params.size());
                                   yyerror(errorMsg.c_str());
                                   errorCount++;
                                   $$ = nullptr;
                                   break;
                              }
                              for (size_t i = 0; i < expectedParams.params.size(); ++i) {
                                   if (expectedParams.params[i].type != providedParams->params[i].type) {
                                        string errorMsg = "Method '" + string($3) +
                                                            "' parameter type mismatch at position " + to_string(i + 1) +
                                                            ". Expected '" + expectedParams.params[i].type + "', but got '" +
                                                            providedParams->params[i].type + "'";
                                        yyerror(errorMsg.c_str());
                                        errorCount++;
                                        $$ = nullptr;
                                        break;
                                   }
                              }
                              string methodType = methodInfo.type;
                              if (methodType == "bool") {
                                   $$ = new ASTNode("bool", Value(0, "bool"));
                                   $$->type = "bool";
                              } else {
                                   string errorMsg = "Unsupported return type for method '" + string($3) + "'";
                                   yyerror(errorMsg.c_str());
                                   errorCount++;
                                   $$ = nullptr;
                                   break;
                              }

                              found = true;
                              break;
                         }

                         table = table->parent;
                    }

                    if (!found) {
                         string errorMsg = "Variable '" + string($1) + "' not defined in any accessible scope";
                         yyerror(errorMsg.c_str());
                         errorCount++;
                         $$ = nullptr;
                    }
               }
               | ID '(' call_list ')' '?' {
               SymTable* globalScope = global;
               if (!globalScope->existsId($1, "function")) {
                    errorCount++;
                    yyerror((string("Function '") + $1 + "' not defined in global scope").c_str());
               } else {
                    ParamList expectedParams = globalScope->ids[$1].params;
                    ParamList* providedParams = $3;

                    if (expectedParams.params.size() != providedParams->params.size()) {
                         errorCount++;
                         yyerror((string("Function '") + $1 + "' parameter count mismatch").c_str());
                    } else {
                         for (size_t i = 0; i < expectedParams.params.size(); ++i) {
                              if (expectedParams.params[i].type != providedParams->params[i].type) {
                                   errorCount++;
                                   yyerror((string("Function '") + $1 + "' parameter type mismatch at position " + to_string(i + 1)).c_str());
                                   break;
                              }
                         }
                    }
                    delete providedParams;
                    string functionType = globalScope->ids[$1].type;
                    if (functionType == "bool") {
                         $$ = new ASTNode("bool", Value(0, "bool"));
                    } else {
                         errorCount++;
                         yyerror((string("Function '") + $1 + "' has an unsupported return type").c_str());
                         $$ = nullptr;
                    }
               }
          }
          | ID '(' ')' '?' {
               SymTable* globalScope = global;
               if (!globalScope->existsId($1, "function")) {
                    errorCount++;
                    yyerror((string("Function '") + $1 + "' not defined in global scope").c_str());
               } else {
                    ParamList expectedParams = globalScope->ids[$1].params;

                    if (!expectedParams.params.empty()) {
                         errorCount++;
                         yyerror((string("Function '") + $1 + "' expects parameters but none were provided").c_str());
                    }
                    string functionType = globalScope->ids[$1].type;
                    if (functionType == "bool") {
                         $$ = new ASTNode("bool", Value(0, "bool"));
                    } else {
                         errorCount++;
                         yyerror((string("Function '") + $1 + "' has an unsupported return type").c_str());
                         $$ = nullptr;
                    }
               }
          };

comparison_operator:  MAIMIC    { $$ = strdup("<"); }
          | MAIMARE   { $$ = strdup(">"); }
          | MAIMIC_EQ { $$ = strdup("<="); }
          | MAIMARE_EQ { $$ = strdup(">="); }
          | EGAL      { $$ = strdup("=="); }
          | DIFERIT   { $$ = strdup("!="); };

call_list : expression {
               $$ = new ParamList();
               $$->addParam($1->type.c_str(), "");
           }
          | boolean_expression {
               $$ = new ParamList();
               $$->addParam($1->type.c_str(), "");
           }
          | call_list ',' expression {
               $$ = $1;
               $$->addParam($3->type.c_str(), "");
           }
          | call_list ',' boolean_expression {
               $$ = $1;
               $$->addParam($3->type.c_str(), "");
           }
          ;
%%
void yyerror(const char * s){
     cout << "error:" << s << " at line: " << yylineno << endl;
}

int main(int argc, char** argv){
     yyin=fopen(argv[1],"r");
     current = new SymTable("global");
     global = current;
     yyparse();
     delete current;
} 