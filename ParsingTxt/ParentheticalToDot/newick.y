%{
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
extern int yylex();
extern FILE* yyin;
extern void* saferealloc(void *ptr, size_t size);
int yywrap() { return 1;}
void yyerror(const char* s) {fprintf(stderr,"Error:\"%s\".\n",s);}
struct tree_t
        {
        int id;
        char* label;
        char* length;
        struct tree_t* child;
        struct tree_t* next;
        };
typedef struct tree_t Tree;
static int id_generator=0;
static Tree* newTree()
        {
        Tree* t=saferealloc(0,sizeof(Tree));
        memset(t,0,sizeof(Tree));
        t->id=(++id_generator);
        return t;
        }
static void freeTree(Tree* t)
        {
        if(t==NULL) return;
        free(t->label);
        free(t->length);
        freeTree(t->child);
        freeTree(t->next);
        free(t);
        }
static void escape(FILE* out,const char* s)
        {
        if(s==NULL) { fputs("null",out); return;}
        while(*s!=0)
                {
                switch(*s)
                        {
                        case '\'': fputs("\\\'",out); break;
                        case '\"': fputs("\\\"",out); break;
                        case '\\': fputs("\\\\",out); break;
                        case '\n': fputs("\\n",out); break;
                        case '\r': fputs("\\r",out); break;
                        case '\t': fputs("\\t",out); break;
                        default : fputc(*s,out); break;
                        }
                ++s;
                }
        }
static void num(FILE* out,const char* d)
        {
        if(d==NULL) { fputs("null",out);; return;}
        fputs(d,out);
        }
static void printTree(FILE* out,const Tree* t)
        {
        fprintf(out,"id%d[label=\"",t->id);
        if(t->label!=NULL) escape(out,t->label);
        if(t->length!=NULL) {if(t->label!=NULL) fputc(':',out);escape(out,t->length);}
        fputs("\"];\n",out);
        if(t->child!=0)
                {
                const Tree* c=t->child;
                while(c!=NULL)
                        {
                        printTree(out,c);
                        fprintf(out,"id%d ->  id%d\n",t->id,c->id);
                        c=c->next;
                        }
                }
        }
%}
%union  {
        char* s;
        char* d;
        struct tree_t* tree;
        }
%error-verbose
%token OPAR
%token CPAR
%token COMMA
%token COLON SEMICOLON 
%token<s> STRING
%token<d> NUMBER
%type<s> label optional_label
%type<d> number optional_length
%type<tree> subtree descendant_list_item descendant_list
%start input
%%
input: descendant_list optional_label optional_length SEMICOLON
        {
        Tree* tree=newTree();
        //tree->type=ROOT;
        tree->child=$1;
        tree->label=$2;
        tree->length=$3;
        fputs("digraph G {\n",stdout);
        printTree(stdout,tree);
        freeTree(tree);
        fputs("}\n",stdout);
        };
descendant_list: OPAR  descendant_list_item CPAR
        {
        $$=$2;
        };
descendant_list_item: subtree
                {
                $$=$1;
                }
        |descendant_list_item COMMA subtree
                {
                Tree* last=$1;
                $$=$1;
                while(last->next!=NULL)
                        {
                        last=last->next;
                        }
                last->next=$3;
                }
        ;
subtree : descendant_list optional_label optional_length
                {
                $$=newTree();
                $$->child=$1;
                $$->label=$2;
                $$->length=$3;
                }
         | label optional_length
                {
                $$=newTree();
                $$->label=$1;
                $$->length=$2;
                }
         ;
 
optional_label:  { $$=NULL;} | label  { $$=$1;};
optional_length:  { $$=NULL;} | COLON number { $$=$2;};
label: STRING { $$=$1;};
number: NUMBER { $$=$1;};
%%
int main(int argc,char** argv)
        {
        yyin=stdin;
        yyparse();
        return EXIT_SUCCESS;
        }