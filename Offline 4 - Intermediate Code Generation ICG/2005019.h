#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include<bits/stdc++.h>

using namespace std;


class symbolInfo{
    
    string name;
    string type;
    bool isFunc;
    
    
    symbolInfo* returnType;


    symbolInfo * nextSym;

    public:

    vector<symbolInfo*> childList;
    vector<symbolInfo*> paramlist;
    vector<symbolInfo*> arrElements;
    vector<symbolInfo*> localVariableList;
    vector<symbolInfo*> parameterVariableList;

    int sl;
    int el;
    bool leaf;
    int stackOffset;
    string asmStr;
    bool isGlobal;
    string parseText;
    string rule;
    bool isArray;
    int arrLen;

    symbolInfo(string symbol, string typ);

    ~symbolInfo();

    string getName();

    string getType();

    int getArrLen();

    bool getIsFunc(){return isFunc;}

    bool getIsArray();

    string getParseText(){ return parseText;}

    symbolInfo* getElementAtIndex(int index){ return arrElements[index];}

    symbolInfo* getReturnType(){ return returnType;}

    symbolInfo * getNextSym();

    vector<symbolInfo*> getParams(){ return paramlist;}

    void setName(string s){name = s;}

    void setType(string s){ type = s;}

    void setNextSym(symbolInfo* nextS);

    void setArrLen(int n){arrLen = n;}

    void setIsArray(bool a){isArray = a;}

    void setIsFunc(bool a){isFunc = a;}

    void setParameter(vector<symbolInfo*> a){paramlist = a;}

    void setReturnType(symbolInfo* a){returnType = a; }

    void setElementAtIndex(int index, symbolInfo* a){ arrElements[index] = a;}
    
    
};





class scopeTable{

    symbolInfo** symbols;

    int totalBuckets;

    scopeTable* parentScope;

    int numOfChildScopes;

    string id;
    
    public:

    scopeTable(int bucket, string current_id, scopeTable* parent);

    ~scopeTable();


    int myhash(string st, int buckets);
    string generateID(string currID);

    string getID(){return id;}
    int getNumOfChild(){return numOfChildScopes;}
    void setNumOfChild(int n){numOfChildScopes=n;}
    scopeTable* getParent(){return parentScope;}
    

    symbolInfo* lookupInscope(string symbol,bool helper);
    bool insertSymbolInscope(symbolInfo* s);
    bool deleteSymbolInscope(string symbol);
    void printScope(ofstream& file);

    
};







class symbolTable{

    scopeTable* root;

    scopeTable* currentScope;

    int buckets;

    public:

    symbolTable(int bucketNo);

    ~symbolTable();

    void enterScope();
    void exitScope();
    bool insert(symbolInfo* s);
    bool remove(string symbol);
    symbolInfo* lookup(string symbol);
    symbolInfo* lookupHere(string symbol);
    void printCurrent(ofstream& file);
    void printAll(ofstream& file);
    void quit();


};






#endif