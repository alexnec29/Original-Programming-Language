#include "SymTable.h"
#include <fstream>
using namespace std;

ofstream g("output.txt");
ofstream h("debug.txt");

float Value::getFloat() const {
    if (type == "float") {
        return floatValue;
    }
    return 0.0;
}

int Value::getInt() const {
    if (type == "int" || type=="bool") {
        return intValue;
    }
    return 0;
}

char Value::getChar() const {
    if (type == "char") {
        return charValue;
    }
    return '0';
}

string Value::getString() const {
    if (type == "string") {
        return stringValue;
    }
    return "0";
}

Value ASTNode::evaluate() const {
    if (!left && !right) {
        if (type == "int" || type == "float") {
            return value;
        } 
        else if (type == "bool") {
            h << "Evaluating boolean leaf node: " 
                      << (value.getInt() ? "TRUE" : "FALSE") 
                      << " of type " << type << endl;
            return value;
        } 
        else if (type == "id") {
            SymTable* table = symTable;

            cout << "Starting lookup for variable '" << label << "' in scope: "
                << (table ? table->name : "null") << endl;

            while (table != nullptr) {
                if (table->existsId(label.c_str(), "var")) {
                    Value varValue = table->ids[label].value;

                    if (varValue.type.empty() || varValue.type == "unknown") {
                        cout << "Error: Variable '" << label << "' has an uninitialized or invalid value" << endl;
                        return Value();
                    }

                    h << "Found variable '" << label << "' with value: "
                        << (varValue.type == "int" ? varValue.getInt() : varValue.getFloat())
                        << " of type " << varValue.type << " in scope: " << table->name << endl;

                    return varValue;
                }

                table = table->parent;
            }

            cout << "Error: Variable '" << label << "' not defined in any accessible scope" << endl;
            return Value();
        } 
        else if (type == "string") {
            h << "Evaluating string leaf node: \"" 
            << value.getString() 
            << "\" of type " << type << endl;
            return value;
        } 
        else if (type == "char") {
            h << "Evaluating char leaf node: '" 
            << value.getChar() 
            << "' of type " << type << endl;
            return value;
        }
        else {
            cout<<"Error: Unsupported leaf node type '" + type + "'";
            return Value();
        }
    }

    Value leftValue = left ? left->evaluate() : Value();
    Value rightValue = right ? right->evaluate() : Value();

    h << "Evaluating operator " << label
              << " with left: " << (leftValue.type == "int" ? leftValue.getInt() : leftValue.getFloat())
              << " and right: " << (rightValue.type == "int" ? rightValue.getInt() : rightValue.getFloat())
              << " of type " << leftValue.type << " and " << rightValue.type << endl;

        if (label == "+") {
            if (leftValue.type != rightValue.type) {
                cout<<"Type mismatch in '+' operation";
                return Value();
            }
            return (leftValue.type == "int")
                       ? Value(leftValue.getInt() + rightValue.getInt(), "int")
                       : Value(leftValue.getFloat() + rightValue.getFloat(), "float");
        }
        if (label == "-") {
            if (leftValue.type != rightValue.type) {
                cout<<"Type mismatch in '-' operation";
                return Value();
            }
            return (leftValue.type == "int")
                       ? Value(leftValue.getInt() - rightValue.getInt(), "int")
                       : Value(leftValue.getFloat() - rightValue.getFloat(), "float");
        }
        if (label == "*") {
            if (leftValue.type != rightValue.type) {
                cout<<"Type mismatch in '*' operation";
                return Value();
            }
            return (leftValue.type == "int")
                       ? Value(leftValue.getInt() * rightValue.getInt(), "int")
                       : Value(leftValue.getFloat() * rightValue.getFloat(), "float");
        }
        if (label == "/") {
            if (leftValue.type != rightValue.type) {
                cout<<"Type mismatch in '/' operation";
                return Value();
            }
            if ((leftValue.type == "int" && rightValue.getInt() == 0) ||
                (leftValue.type == "float" && rightValue.getFloat() == 0.0)) {
                cout<<"Division by zero";
                return Value();
            }
            return (leftValue.type == "int")
                       ? Value(leftValue.getInt() / rightValue.getInt(), "int")
                       : Value(leftValue.getFloat() / rightValue.getFloat(), "float");
        }
        if (label == "%") {
            if (leftValue.type != "int" || rightValue.type != "int") {
                cout << "Modulo operation is only valid for integers" << endl;
                return Value();
            }
            if (rightValue.getInt() == 0) {
                cout << "Modulo by zero is undefined" << endl;
                return Value();
            }
            return Value(leftValue.getInt() % rightValue.getInt(), "int");
        }

        if (label == "&&") {
            return Value(leftValue.getInt() && rightValue.getInt(), "bool");
        }
        if (label == "||") {
            return Value(leftValue.getInt() || rightValue.getInt(), "bool");
        }
        if (label == "!") {
            return Value(!leftValue.getInt(), "bool");
        }

        if (label == "<" || label == ">" || label == "<=" || label == ">=") {
            h << "Comparing '" << label << "' with left type: " << leftValue.type
                    << " and right type: " << rightValue.type << endl;

            if (leftValue.type != rightValue.type) {
                cout<<"Type mismatch: Cannot compare values of different types";
                return Value();
            }

            if (leftValue.type == "int") {
            h << "Comparing int values: " << leftValue.getInt() << " " << label << " " << rightValue.getInt() << endl;
                return Value(label == "<" ? leftValue.getInt() < rightValue.getInt() :
                            label == ">" ? leftValue.getInt() > rightValue.getInt() :
                            label == "<=" ? leftValue.getInt() <= rightValue.getInt() :
                            leftValue.getInt() >= rightValue.getInt(), "bool");
            } else if (leftValue.type == "float") {
            h << "Comparing float values: " << leftValue.getFloat() << " " << label << " " << rightValue.getFloat() << endl;
                return Value(label == "<" ? leftValue.getFloat() < rightValue.getFloat() :
                            label == ">" ? leftValue.getFloat() > rightValue.getFloat() :
                            label == "<=" ? leftValue.getFloat() <= rightValue.getFloat() :
                            leftValue.getFloat() >= rightValue.getFloat(), "bool");
            } else {
                cout << "ERROR: Unsupported type for comparison: " << leftValue.type << endl;
                cout<<"Type mismatch: Unsupported type for comparison";
                return Value();
            }
        }

        if (label == "==" || label == "!=") {
            h << "Comparing '" << label << "' with left type: " << leftValue.type
                   << " and right type: " << rightValue.type << endl;

            if (leftValue.type != rightValue.type) {
                cout<<"Type mismatch: Cannot compare values of different types";
                return Value();
            }

            if (leftValue.type == "int") {
                h << "Comparing int values: " << leftValue.getInt() << " " << label << " " << rightValue.getInt() << endl;
                return Value(label == "==" ? leftValue.getInt() == rightValue.getInt() :
                            leftValue.getInt() != rightValue.getInt(), "bool");
            } else if (leftValue.type == "float") {
                h << "Comparing float values: " << leftValue.getFloat() << " " << label << " " << rightValue.getFloat() << endl;
                return Value(label == "==" ? leftValue.getFloat() == rightValue.getFloat() :
                            leftValue.getFloat() != rightValue.getFloat(), "bool");
            } else if (leftValue.type == "bool") {
                h << "Comparing bool values: " << (leftValue.getInt() ? "TRUE" : "FALSE")
                        << " " << label << " " << (rightValue.getInt() ? "TRUE" : "FALSE") << endl;
                return Value(label == "==" ? leftValue.getInt() == rightValue.getInt() :
                            leftValue.getInt() != rightValue.getInt(), "bool");
            } else {
                cout << "ERROR: Unsupported type for equality comparison: " << leftValue.type << endl;
                cout<<"Type mismatch: Unsupported type for equality comparison";
                return Value();
            }
        }
        cout<<"Unknown operator: " + label;
        return Value();
    }

void ParamList::addParam(const char* type, const char* name) {
    params.emplace_back(type, name);
}

void ParamList::clear() {
    params.clear();
}

void ParamList::printParams() const {
    for (const auto& param : params) {
        g << "Param: " << param.name << ", Type: " << param.type << endl;
    }
}

void SymTable::addVar(const char* type, const char*name) {
    IdInfo var(type, name, "var");
    ids[name] = var; 
}

void SymTable::addClass(const char* name, SymTable* classScope) {
    IdInfo classInfo(name, "class", classScope);
    ids[name] = classInfo;
}

void SymTable::addVector(const char* type, const char*name, int size) {
    IdInfo var(type, name, "vector",size);
    ids[name] = var; 
}

void SymTable::addFunction(const char* type, const char* name, const ParamList& params) {
    IdInfo funcInfo(type, name, "function");
    funcInfo.params = params;
    ids[name] = funcInfo;
}

bool SymTable::existsId(const char* name, const char* type) {
    for (const pair<string, IdInfo>& v : ids) {
        if(v.second.name==name && v.second.idType==type) return true;
    }
    return false; 
}

bool SymTable::existsIdAll(const char* name, const char* type) {
    SymTable* currentScope = this;
    while (currentScope) {
        if (currentScope->existsId(name, type)) {
            h << "Variable '" << name << "' found in scope '" << currentScope->name << "'" << endl;
            return true;
        }
        currentScope = currentScope->parent;
    }
    cout << "Variable '" << name << "' not found in any accessible scope" << endl;
    return false;
}

void SymTable::printVars() {
    g<<"Variables in scope " << name <<":\n";
    for (const pair<string, IdInfo>& v : ids) {
        const IdInfo& info = v.second;
        g << "Name: " << info.name << ", Type: " << info.type << ", IdType: " << info.idType;

        if (info.idType != "function") {
            if (info.value.type == "int") {
                g << ", Value: " << info.value.getInt();
            } else if (info.value.type == "float") {
                g << ", Value: " << info.value.getFloat();
            } else if (info.value.type == "bool") {
                g << ", Value: " << (info.value.getInt() ? "TRUE" : "FALSE");
            } else if (info.value.type == "string") {
                g << ", Value: \"" << info.value.getString() << "\"";
            } else if (info.value.type == "char") {
                g << ", Value: '" << info.value.getChar() << "'";
            } else {
                g << ", Value: (uninitialized)";
            }
        }
        g << endl;
        if (info.idType == "function") {
            g << "Parameters:\n";
            info.params.printParams();
        }
    }
    g<<"\n";
}

SymTable* SymTable::getClassScope(const char* className) {
    auto it = ids.find(className);
    if (it != ids.end() && it->second.idType == "class") {
        return it->second.classScope;
    }
    return nullptr;
}

SymTable::~SymTable() {
    ids.clear();
}
