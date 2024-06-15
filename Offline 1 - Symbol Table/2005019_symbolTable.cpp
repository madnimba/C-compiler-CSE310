#include <iostream>
#include <fstream>
#include <cstring>
#include "2005019_scopeTable.cpp"

using namespace std;


class symbolTable{

    scopeTable* root;

    scopeTable* currentScope;

    int buckets;

    public:

    symbolTable(int bucketNo)
    {
        root = new scopeTable(bucketNo,"1",nullptr);
        currentScope = root;
        buckets = bucketNo;
    }

    ~symbolTable()
    {
        while(currentScope!=nullptr)
         {
            scopeTable* temp= currentScope->getParent();
            delete currentScope;
            currentScope=temp;
         }
        //cout<<"\tDestructing main scope"<<endl;
    }

    void enterScope();
    void exitScope();
    bool insert(string symbol, string type);
    bool remove(string symbol);
    symbolInfo* lookup(string symbol);
    void printCurrent();
    void printAll();
    void quit();


};

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

    cout<<"\t'"<<symbol<<"' not found in any of the ScopeTables"<<endl;
    return nullptr;
}

bool symbolTable::insert(string symbol,string type)
{
    if(currentScope->lookupInscope(symbol,true)!=nullptr)
       { 
        cout<<"\t'"<<symbol<<"' already exists in the current ScopeTable# "<<currentScope->getID()<<endl;
        return false;
       }
    
    return currentScope->insertSymbolInscope(symbol,type);
} 

bool symbolTable::remove(string symbol)
{
    return currentScope->deleteSymbolInscope(symbol);
}

void symbolTable::printCurrent()
{
    currentScope->printScope();
}

void symbolTable::printAll()
{
    scopeTable *temp = currentScope;
    while(temp!=nullptr)
    {
        
        temp->printScope();

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
        
        cout<<"\tScopeTable# "<<currentScope->getID()<<" deleted"<<endl;
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



int main() {
  
  ifstream inputFile("input.txt");
  freopen("output.txt","w",stdout);
  string line;
  string command [3];
  
  int i;
  int cmdnum=0;
  int bucketNumber;
  inputFile >> bucketNumber;

  symbolTable myTable(bucketNumber);
  getline(inputFile,line);

  while(getline(inputFile,line))
  {
    cmdnum++;
    cout << "Cmd "<<cmdnum<<": ";

    char cmd[line.size()+1];
    strcpy(cmd,line.c_str());

    char* token = strtok(cmd, " ");
    i=0;
    while (token != nullptr ) 
    {
        if(i<=2)
            command[i] = token;
        token = strtok(nullptr, " ");
        i++;
    }

    cout<<line;
    cout<<endl;


    if(command[0]=="I")
        {
            if(i!=3)
                cout<<"\tWrong number of arugments for the command I"<<endl;
            else
                myTable.insert(command[1],command[2]);
        }
    else if(command[0]=="L")
    {
        if(i!=2)
            cout<<"\tWrong number of arugments for the command L"<<endl;
        else 
            myTable.lookup(command[1]);
    }
    else if(command[0]=="P")
    {
        if(i!=2)
            cout<<"\tWrong number of arugments for the command P"<<endl;
        else if(command[1]=="C")
        {
            myTable.printCurrent();
        }
        else if(command[1]=="A")
            myTable.printAll();
        else
            cout<<"\tInvalid argument for the command P"<<endl;
        
    }
    else if(command[0]=="D")
    {
        if(i!=2)
            cout<<"\tWrong number of arugments for the command D"<<endl;
        else
            myTable.remove(command[1]);
    }
    else if(command[0]=="S")
    {
        if(i!=1)
            cout<<"\tWrong number of arugments for the command S"<<endl;
        else 
            myTable.enterScope();
    }
    else if(command[0]=="E")
    {
        if(i!=1)
            cout<<"\tWrong number of arugments for command E"<<endl;
        else 
            myTable.exitScope();
    }
    else if(command[0]=="Q")
    {
        if(i!=1)
            cout<<"\tWrong number of arugments for command Q"<<endl;
        else 
            myTable.quit();
    }
    else{
        cout<<"\tInvalid Command"<<endl;
    }

    
  }
  
    fclose(stdout);
  return 0;
}

