#include "2005019.h"
#include <bits/stdc++.h>



//-------SYMBOL INFO -----------------

symbolInfo::symbolInfo(string symbol, string typ)
    {
        name = symbol;
        type = typ;
        nextSym = nullptr;
        parseText="";
        leaf=false;
    }

    symbolInfo::~symbolInfo()
    {
        for (symbolInfo* info : paramlist) {
        delete info;
        }
        paramlist.clear();
        for (symbolInfo* info : arrElements) {
        delete info;
        }
        arrElements.clear();
        //cout<<"\tDestructing symbolinfo "<<name<<endl;
    }

    string symbolInfo::getName()
    {
        return name;
    }

    string symbolInfo::getType()
    {
        return type;
    }

    symbolInfo * symbolInfo::getNextSym()
    {
        return nextSym;
    }

    int symbolInfo::getArrLen()
    {
        return arrLen;
    }

    bool symbolInfo::getIsArray()
    {
        return isArray;
    }

    void symbolInfo::setNextSym(symbolInfo* nextS)
    {
        nextSym = nextS;
    }
    



//-----------------SCOPE TABLE ---------------



   scopeTable::scopeTable(int bucket, string current_id, scopeTable* parent)
    {
        totalBuckets = bucket;
        numOfChildScopes = 0;

        symbols = new symbolInfo* [bucket];

        
        for (int i = 0; i < bucket; i++)
        {
            symbols[i] = nullptr;
        }

        
        parentScope = parent;

        if(parent==nullptr)
            id=current_id;
        else
            id = to_string(stoi(current_id) + 1);


        cout<<"\tScopeTable#"<<" "<<id<<" "<<"created"<<endl;
        
    }

    scopeTable::~scopeTable()
    {
    
        for (int i = 0; i < totalBuckets; i++)
        {
            symbolInfo* current =symbols[i];
            while (current!= nullptr)
            {
                symbolInfo* next =current->getNextSym();
                delete current;
                current =next;
            }
        }

        delete[] symbols;
        
        //cout<<"\tDestructing scopetable# "<<id<<endl;
        
    }


    


symbolInfo* scopeTable::lookupInscope(string symbol,bool helper){

    for (int i = 0; i < totalBuckets; i++)
    {

    int serial=1;
    symbolInfo* sym = symbols[i];
        while(sym!=nullptr)
        {
            if(symbol==sym->getName())
                {
                    
                    // if(!helper)
                    //     cout<<"\t'"<<symbol<<"' found at position <"<<to_string(i+1)<<", "<<serial<<"> of ScopeTable# "<<id<<endl;
                    return sym;
                }
            sym = sym->getNextSym();
            serial++;
        } 
    }

    return nullptr;

}

bool scopeTable::insertSymbolInscope(symbolInfo* s)
{
    string sym = s->getName();
    string type = s->getType();

    bool isFunc = s->getIsFunc();
    bool isArr = s->getIsArray();
    
    
    if(lookupInscope(sym,true)!=nullptr)
        {
            //cout<<"\t'"<<sym<<"' already exists in the current ScopeTable# "<<id<<endl;
            return false;
        }
    
    int myBucket = myhash(sym,totalBuckets);
    int serial = 1;


    symbolInfo* fresh = new symbolInfo(sym,type);

    if(isFunc) 
    {
        fresh->setIsFunc(true);
        fresh->setReturnType(s->getReturnType());
        fresh->setParameter(s->getParams());
    }

     if(isArr)
    {
        fresh->setIsArray(true);
        fresh->setArrLen( s->getArrLen());
    }

    symbolInfo* head = symbols[myBucket];

    if(head==nullptr)
        symbols[myBucket]= fresh;
    else
        {
            symbolInfo *trav = head;
            serial++;

            while(trav->getNextSym()!=nullptr)
                {
                    trav = trav->getNextSym();
                    serial++;
                }
            trav->setNextSym(fresh);
        }

    //cout<<"\tInserted  at position <"<<to_string(myBucket+1)<<", "<<serial<<"> of ScopeTable# "<<id<<endl;
   
    return true;
}

bool scopeTable::deleteSymbolInscope(string symbol)
{
    symbolInfo* toDelete = lookupInscope(symbol,true);
    if(toDelete==nullptr)
        {
            //cout<<"\tNot found in the current ScopeTable# "<<id<<endl;
            return false;
        }

    int myBucket = myhash(symbol,totalBuckets);

    symbolInfo* head = symbols[myBucket];
    
    symbolInfo* tail = head;
    int serial = 1;
    if(tail!=nullptr)
        tail = head->getNextSym();
    if(head->getName()==symbol)
        symbols[myBucket] = head->getNextSym();
    else{
        while(tail->getName()!=symbol)
        {
            head = head->getNextSym();
            tail= tail->getNextSym();
            serial++;
        }
        head->setNextSym(tail->getNextSym());
        
        
        
    }

    delete toDelete;

    //cout<<"\tDeleted '"<<symbol<<"' from position <"<<to_string(myBucket+1)<<", "<<serial<<"> of ScopeTable# "<<id<<endl;
    return true;


}


void scopeTable::printScope(ofstream& file)
{
    
    file<<"\tScopeTable# "<<id<<endl;
    
    for(int i=0;i<totalBuckets;i++)
    {

        
        
         symbolInfo* head = symbols[i];
         
         symbolInfo* temp = head;
         if(temp==nullptr) continue;

         file<<"\t"<<i+1<<"--> ";

         while(temp!=nullptr)
         {
            
            file<<("<");
            file<<temp->getName();
            file<<(",");
            if(temp->getIsFunc())
            {file<<temp->getType()<<","<<(temp->getReturnType())->getName();}
            else if(temp->getIsArray()){ file<<"ARRAY";}
            else
            {file<<(temp->getType());}
            file<<("> ");
            
            
            temp = temp->getNextSym();

        }
        file<<("\n");
    }
    
}

unsigned long long sdbmhash(const unsigned char* str, int b)
{
    unsigned long long hash=0;
    unsigned long long ch;

    while(ch=*str++)
    {
        hash = ch+ (hash<<6) + (hash<<16) - hash;
        
    }

    return hash;
}

int scopeTable::myhash(string str, int buckets)
{
    const char* inputStr = str.c_str();
    const unsigned char* inputCharPtr = reinterpret_cast<const unsigned char*>(inputStr);
    unsigned long long hashValue = sdbmhash(inputCharPtr,buckets);

    return hashValue%buckets;

}




string scopeTable::generateID(string curr_id)
{
    string myID = parentScope->getID();
    myID.append(".");
    myID.append(curr_id);
    return myID;
}



//------------------------------------SYMBOL TABLE ----------------------







    symbolTable::symbolTable(int bucketNo)
    {
        root = new scopeTable(bucketNo,"1",nullptr);
        currentScope = root;
        buckets = bucketNo;
    }

    symbolTable::~symbolTable()
    {
        while(currentScope!=nullptr)
         {
            scopeTable* temp= currentScope->getParent();
            delete currentScope;
            currentScope=temp;
         }
        //cout<<"\tDestructing main scope"<<endl;
    }

   
symbolInfo* symbolTable::lookup(string symbol)
{
    scopeTable* temp = currentScope;
    while(temp!=nullptr)
    {
        symbolInfo* res = temp->lookupInscope(symbol,false);
        if(res!=nullptr)
            return res;
        temp = temp->getParent();
    }

    //cout<<"\t'"<<symbol<<"' not found in any of the ScopeTables"<<endl;
    return nullptr;
}

symbolInfo* symbolTable::lookupHere(string symbol)
{
    scopeTable* temp = currentScope;
    return temp->lookupInscope(symbol,false);
}



bool symbolTable::insert(symbolInfo* s)
{
    string symbol = s->getName();
    string type = s->getType();
    if(currentScope->lookupInscope(symbol,true)!=nullptr)
       { 
        //cout<<"\t'"<<symbol<<"' already exists in the current ScopeTable# "<<currentScope->getID()<<endl;
        return false;
       }
    //symbolInfo* sm = new symbolInfo(symbol, type);
    return currentScope->insertSymbolInscope(s);
} 

bool symbolTable::remove(string symbol)
{
    return currentScope->deleteSymbolInscope(symbol);
}

void symbolTable::printCurrent(ofstream& file)
{
    currentScope->printScope(file);
}

void symbolTable::printAll(ofstream& file)
{
    scopeTable *temp = currentScope;
    while(temp!=nullptr)
    {
        
        temp->printScope(file);

        temp = temp->getParent();

    }
}


void symbolTable::enterScope()
{
    int scopeNum = currentScope->getNumOfChild();
    scopeNum++;
    currentScope->setNumOfChild(scopeNum);

    scopeTable* newScope = new scopeTable(buckets,to_string(scopeNum),currentScope);
    currentScope = newScope;
} 

void symbolTable::exitScope()
{
    if(currentScope->getParent()!=nullptr)
    {   
        
        //cout<<"\tScopeTable# "<<currentScope->getID()<<" deleted"<<endl;
        scopeTable* temp  = currentScope->getParent();
        delete currentScope;
        currentScope = temp;
        
    }
    else
        cout<<"\tScopeTable# 1 cannot be deleted"<<endl;
    
}

void symbolTable::quit()
{
    while(currentScope->getParent()!=nullptr)
    {
        exitScope();
    }
    cout<<"\tScopeTable# 1 deleted\n";

}