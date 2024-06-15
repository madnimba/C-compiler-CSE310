#include <iostream>
using namespace std;

class symbolInfo{
    
    string name;
    string type;

    symbolInfo * nextSym;

    public:

    symbolInfo(string symbol, string typ)
    {
        name = symbol;
        type = typ;
        nextSym = nullptr;
    }

    ~symbolInfo()
    {
        //cout<<"\tDestructing symbolinfo "<<name<<endl;
    }

    string getName()
    {
        return name;
    }

    string getType()
    {
        return type;
    }

    symbolInfo * getNextSym()
    {
        return nextSym;
    }

    void setNextSym(symbolInfo* nextS)
    {
        nextSym = nextS;
    }
    
};