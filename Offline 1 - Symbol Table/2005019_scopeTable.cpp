#include <iostream>
#include "2005019_symbolInfo.cpp"
using namespace std;


class scopeTable{

    symbolInfo** symbols;

    int totalBuckets;

    scopeTable* parentScope;

    int numOfChildScopes;

    string id;
    
    public:

    scopeTable(int bucket, string current_id, scopeTable* parent)
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
            id = generateID(current_id);


        cout<<"\tScopeTable#"<<" "<<id<<" "<<"created"<<endl;
        
    }

    ~scopeTable()
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


    int myhash(string st, int buckets);
    string generateID(string currID);

    string getID(){return id;}
    int getNumOfChild(){return numOfChildScopes;}
    void setNumOfChild(int n){numOfChildScopes=n;}
    scopeTable* getParent(){return parentScope;}
    

    symbolInfo* lookupInscope(string symbol,bool helper);
    bool insertSymbolInscope(string symbol, string type);
    bool deleteSymbolInscope(string symbol);
    void printScope();

    


};


symbolInfo* scopeTable::lookupInscope(string symbol,bool helper){

    for (int i = 0; i < totalBuckets; i++)
    {

    int serial=1;
    symbolInfo* sym = symbols[i];
        while(sym!=nullptr)
        {
            if(symbol==sym->getName())
                {
                    
                    if(!helper)
                        cout<<"\t'"<<symbol<<"' found at position <"<<to_string(i+1)<<", "<<serial<<"> of ScopeTable# "<<id<<endl;
                    
                    return sym;
                }
            sym = sym->getNextSym();
            serial++;
        } 
    }

    return nullptr;

}

bool scopeTable::insertSymbolInscope(string sym, string type)
{

    if(lookupInscope(sym,true)!=nullptr)
        {
            cout<<"\t'"<<sym<<"' already exists in the current ScopeTable# "<<id<<endl;
            return false;
        }
    
    int myBucket = myhash(sym,totalBuckets);
    int serial = 1;


    symbolInfo* head = symbols[myBucket];

    if(head==nullptr)
        symbols[myBucket]= new symbolInfo(sym,type);
    else
        {
            symbolInfo *trav = head;
            serial++;

            while(trav->getNextSym()!=nullptr)
                {
                    trav = trav->getNextSym();
                    serial++;
                }
            trav->setNextSym(new symbolInfo(sym,type));
        }

    cout<<"\tInserted  at position <"<<to_string(myBucket+1)<<", "<<serial<<"> of ScopeTable# "<<id<<endl;
   
    return true;
}

bool scopeTable::deleteSymbolInscope(string symbol)
{
    symbolInfo* toDelete = lookupInscope(symbol,true);
    if(toDelete==nullptr)
        {
            cout<<"\tNot found in the current ScopeTable# "<<id<<endl;
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

    cout<<"\tDeleted '"<<symbol<<"' from position <"<<to_string(myBucket+1)<<", "<<serial<<"> of ScopeTable# "<<id<<endl;
    return true;


}


void scopeTable::printScope()
{
    
    cout<<"\tScopeTable# "<<id<<endl;
    
    for(int i=0;i<totalBuckets;i++)
    {

        cout<<"\t"<<i+1;
        
         symbolInfo* head = symbols[i];
         
         symbolInfo* temp = head;
         while(temp!=nullptr)
         {
            cout<<" --> ";
            cout<<("(");
            cout<<temp->getName();
            cout<<(",");
            cout<<(temp->getType());
            cout<<(")");
            
            
            temp = temp->getNextSym();

        }
        cout<<("\n");
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

