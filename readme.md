# Original Programming Language

This repository contains the source code for a custom programming language created using Flex and Bison, with a C++ backend for semantic analysis, scope management, and interpretation.

## 🚀 Features
- Statically-typed variables: int, float, string, char, bool
- User-defined classes with public/private members
- Functions with typed parameters and return types
- Control flow: if, else, elif, while, for
- Boolean logic: &&, ||, !, comparisons
- Operators: +, -, *, /, %, compound assignment (e.g., +=, *=)
- Scope management via custom symbol tables
- Runtime evaluation using an AST (Abstract Syntax Tree)
- Built-in functions: Print, TypeOf

## 🛠 How to Build and Run

Requirements
- flex
- bison
- g++
- Linux Operationg System

### Build commands:
```bash
bison -d limbaj.y
flex limbaj.l
g++ -o limbaj limbaj.tab.c lex.yy.c SymTable.cpp -lfl
```

### Run
```bash
./limbaj [inputfile]
```

### ✅ Sample Input:
```bash
class Class1
    {
        public:
        int a=10;
        int b=20;
        int c;
        int fct1 (bool p){
            if(p?){
                a = a*b;
                Print(a);
            }
                return a;
        }
        int fct2(int c){
            if(a+b>c){
                b = b - a;
            } 
            else {
                a = a-a;
            }
            return a;
        }
    }

int gx = 100;
int gy;
int ga[10];
float gfl = 3.5;
char gc ='c';
string gs = "well done";
bool gb;
bool gf;
Class1 cls;

int f1(int a, int b){
    int i;
    i=5;
    int j;
    j = 50;
    for(i=1|i<10|i=i+1)
    {
        if(j>i)
        {
            Print(i*10);
            bool c;
            c=true;
            while( c? || gf?)
            {
                int i;
                i = 33;
                Print(i*3);
                c = false;
                Print(c);
                Print(gs);
            }
        }
    }
    j = 200;
    Print (j);
    return 5;
}

bool f2(bool p1, char p2){
    if (5>3)
    {
        bool p3;
        p3=5>3;
    }   
    else
    {
        bool p3;
        p3=5>3;
    }  
    return false;
}

bool f2(bool p1, char p2){
    if (5>3)
    {
        bool p3;
        p3=5>3;
    }   
    else
    {
        bool p3;
        p3=5>3;
    }  
    return false;
}

begin_progr
    Print(gx);
    ga[3] = 3;
    cls.b = 50;
    gx = gx + 5*100 + (gx * f1(5, gx)) + ga[3] - cls.fct2(100);
    Print(gx);
    bool boolii;
    gf=true;
    boolii=f2(gf,'p')?;
    bool bl;
    bl = f2(boolii?, 'p')?;
    Print(gfl);
    gfl = gfl + 6.5 + gfl*10.0 - 35.0;
    Print(gfl);
    Print(gs);
    gs = "you rock!";
    bool bollo;
    bollo=f2(gb, 'c')?;
    Print(gs);
    Print((f1(5, 2*10) + 100) > 10 && f2(gb, 'c')?);
    TypeOf(3+5*gx);
    TypeOf(1000>gx && gf? || f1(5,10)>300);
    Print(gx);
    gx=gx*10;
    Print(gx);
    TypeOf(gs);
    poo=5;
    string gs;
    string gs;
    f5(4);
    poo aur;
    aur.t=3;
    cls.p=3;
    cls.a='c';
    gb=5;
    int pa;
    pa=5+gb;
end_progr
```

### 📓 Debugging Info
- output.txt – contains the final symbol tables after parsing
- debug.txt – logs the evaluation of expressions
