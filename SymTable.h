#include <iostream>
#include <map>
#include <string>
#include <vector>

using namespace std;
class SymTable;

class Value{
    public:
    float floatValue;
    int intValue;
    char charValue;
    string stringValue;
    std::string type;

    Value() : floatValue(0), intValue(0), type("") {}
    Value(float val, const std::string& type = "float")
        : floatValue(val), intValue(0), type(type) {}

    Value(string val, const std::string& type = "string")
        : stringValue(val), intValue(0), type(type) {}

    Value(char val, const std::string& type = "char")
        : charValue(val), intValue(0), type(type) {}

    Value(int val, const std::string& type)
        : floatValue(0), intValue(val), type(type) {}

    float getFloat() const;
    int getInt() const;
    string getString() const;
    char getChar() const;
};

class ASTNode{
    public:
        string label;
        ASTNode* left = nullptr;
        ASTNode* right = nullptr;
        string type;
        SymTable* symTable = nullptr;
        Value value;

    ASTNode(const char* label) : label(label), left(nullptr), right(nullptr), symTable(nullptr) {}
    ASTNode(const char* type, Value value) : type(type), value(value), left(nullptr), right(nullptr), symTable(nullptr) {}
    ASTNode(const char* label, const char* type, SymTable* symTable) : label(label), type(type), symTable(symTable), left(nullptr), right(nullptr) {}

    Value evaluate() const;
    ~ASTNode() {
        delete left;
        delete right;
    }
};

class ParamInfo{
    public:
        string type;
        string name;
        ParamInfo(const char* type, const char* name) : type(type),name(name) {}
};

class ParamList {
    public:
        vector<ParamInfo> params;
        void addParam(const char* type, const char* name);
        void clear();
        void printParams() const;
};

class IdInfo {
    public:
        int size;//for vectors
        Value value;
        string idType;
        string type;
        string name;
        ParamList params; //for functions
        SymTable* classScope; //for classes
        IdInfo() {}
        IdInfo(const char* type, const char* name, const char* idType) : type(type),name(name),idType(idType) {}
        IdInfo(const char* name, const char* idType) : name(name),idType(idType) {}
        IdInfo(const char* name, const char* idType, SymTable* classScope) : name(name),idType(idType), classScope(classScope) {}
        IdInfo(const char* type, const char* name, const char* idType, int size) : type(type),name(name),idType(idType), size(size) {}
};

class SymTable {
    public:
        map<string, IdInfo> ids;
        string name;
        SymTable* parent;
        public:
        SymTable(SymTable* parent, const char* name) :  parent(parent), name(name) {}
        SymTable(const char* name) : name(name) {}
        bool existsId(const char* name, const char* type);
        bool existsIdAll(const char* name, const char* type);
        void addVar(const char* type, const char* name );
        void addVector(const char* type, const char* name, int size);
        void addFunction(const char* type, const char* name, const ParamList& params);
        void addClass(const char* name, SymTable* classScope);
        SymTable* getClassScope(const char* className);
        void printVars();
        ~SymTable();
};
