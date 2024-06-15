#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include<bits/stdc++.h>

using namespace std;


class symbolInfo{
    
    string name;
    string type;

    symbolInfo * nextSym;

    public:

    symbolInfo(string symbol, string typ);

    ~symbolInfo();

    string getName();

    string getType();

    symbolInfo * getNextSym();

    void setNextSym(symbolInfo* nextS);
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
    bool insertSymbolInscope(string symbol, string type);
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
    bool insert(string symbol, string type);
    bool remove(string symbol);
    symbolInfo* lookup(string symbol);
    void printCurrent(ofstream& file);
    void printAll(ofstream& file);
    void quit();


};






#endif