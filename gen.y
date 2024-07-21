%code {
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <assert.h>
// #include "utilities.h"
#include "symboltable.h"

typedef int TEMP;  /* temporary variable.
                       temporary variables are named t1, t2, ... 
                       in the generated code but
					   inside the compiler they may be represented as
					   integers. For example,  temporary 
					   variable 't3' is represented as 3.
					*/
  
// number of errors found by the compiler 
int errors = 0;					

extern int yylex (void);
void yyerror (const char *s);

static int newtemp(), newlabel();
void emit (const char *format, ...);
void emitlabel (int label);
/* no support for break stmts this semester (2024B) */
#if 0 
/* stack of "exit labels".  An "exit label" is the target 
   of a goto used to exit a statement (e.g. 
   a while statement)
   The stack is used to implement 'break' statements which may appear
   in while statements or in for statements.
   A stack is needed because such statements may be nested.
   The label at the top of the stack is the "exit label"  for
   the innermost while (or for) statement currently being processed.
   
   Labels are represented here by integers. For example,
   L_3 is represented by the integer 3.
*/

typedef intStack labelStack;
labelStack exitLabelsStack;
#endif

enum type currentType;  // type specified in current declaration

char* getType(enum type type) ;

} // %code

%code requires {
    void errorMsg (const char *format, ...);
    enum {NSIZE = 100};             // max size of variable names
    enum type {_INT, _DOUBLE };
	 enum op { PLUS, MINUS, MUL, DIV, PLUS_PLUS, MINUS_MINUS };
	
	typedef int LABEL;               /*  symbolic label. Symbolic labels are named
                                       L_1, L_2, ... in the generated code 
                                       but inside the compiler they may be represented as
                                       integers. For example,  symbolic label 'L_3' 
                                       is represented as 3.
                                    */
    struct exp {                    /* semantic value for expression */
	    char result[NSIZE];          /* result of expression is stored 
   		                              in this variable. If result is a constant number
		                                 then the number is stored here (as a string) */
	    enum type type;              // type of expression
	};
	
	/* example: say one of the cases inside a switch 
	            statement is: 
             case 3:  a = b + c;
			 
	   and we  generate the following code for this case:
   	      L_5:  t10 = b + c
		        a = b + c
		        goto L_2  // L_2 is the "exit label"
				
	   then the following information is saved for this 
	   case  in a 'struct case_': 'label' is L_5, 
	                             'constant' is 3
    */							   
	                                 
	struct case_ { LABEL label; int constant; };
	
	struct caselist {                /* semantic value for 'caselist' */
		int number_of_cases;
		struct case_ cases[100];
		LABEL exitlabel;/* code for each case ends with a jump to exitlabel */
    };			   


} // code requires

/* this will be the type of all semantic values. 
   yylval will also have this type 
*/
%union {
   char name[NSIZE];
   int ival;
   double dval;
   enum op op;
   struct exp e;
   LABEL label;
   const char *relop;
   enum type type;
   struct caselist cl;
   
}

%token <ival> INT_NUM
%token <dval> DOUBLE_NUM
%token <relop> RELOP
%token <name> ID
%token <op> ADDOP MULOP
%token IN
%token DOTS
%token WHILE FOR IF ELSE DO SWITCH  CASE DEFAULT 
%token INT DOUBLE INPUT OUTPUT

%nterm <e> expression
%nterm <label> boolexp  start_label exit_label test_label
%nterm <label> default_label
%nterm <type> type
%nterm <idlist> idlist
%nterm <cl> caselist


/* this tells bison to generate better error messages
   when syntax errors are encountered (these error messages
   are passed as an argument to yyerror())
*/
%define parse.error verbose

/* if you are using an old version of bison use this instead:
%error-verbose */

/* enable trace option (for debugging). 
   To request trace info: assign non zero value to yydebug */
%define parse.trace
/* formatting semantic values (when tracing): */
%printer {fprintf(yyo, "%s", $$); } ID
%printer {fprintf(yyo, "%d", $$); } INT_NUM
%printer {fprintf(yyo, "%f", $$); } DOUBLE_NUM

%printer {fprintf(yyo, "result=%s, type=%s",
            $$.result, $$.type == _INT ? "int" : "double");} expression


/* token ADDOP has lower precedence than token MULOP.
   Both tokens have left associativity.

   This solves the shift/reduce conflicts in the grammar 
   because of the productions:  
      expression: expression ADDOP expression | expression MULOP expression   
*/
%left ADDOP
%left MULOP

%%
program: declarations { /*initStack(&exitLabelsStack);*/ } 
         stmtlist;

declarations: declarations decl;

declarations: %empty;

/* example: int a, b, c; */
decl:  type idlist ';';


type: INT    
{  $$ = _INT;
   currentType= _INT;
} 
| DOUBLE 
{  $$ = _DOUBLE; 
   currentType= _DOUBLE;
};
	  
idlist:  idlist ',' ID 
{ 
   putSymbol($3, currentType);
};

idlist:  ID 
{
   putSymbol($1, currentType);
};
			
stmt: assign_stmt  |
      while_stmt   |
      for_stmt    |
	  if_stmt      |
	  switch_stmt  |
	  input_stmt   |
	  output_stmt  |
	  block_stmt
	  ;

assign_stmt:  ID '=' expression ';'
                 {
                     struct symbol *sym = lookup($1);
                     if (sym == NULL) {
                           errorMsg("Undeclared variable %s\n", $1);
                           emit("HERE");
                     } else if (sym->type != $3.type) {
                           emit("%s = static_cast<%s> %s\n", $1, getType(sym->type), $3.result);
                     } else {
                           emit("%s = %s\n", $1, $3.result);
                     }
                    };
				 
expression : expression ADDOP expression
                {
        char temp[NSIZE];
        if ($1.type != $3.type) {
            sprintf(temp, "t%d", newtemp());
            if ($1.type == _INT) {
                emit("%s = static_cast<%s> %s\n", temp, getType($3.type), $1.result);
                sprintf($$.result, "t%d", newtemp());
                emit("%s = %s %s %s\n", $$.result, temp,
                ($2 == PLUS ? "[+]" : "[-]"), $3.result);
            }
            else {
                emit("%s = static_cast<%s> %s\n", temp, getType($1.type), $3.result);
                sprintf($$.result, "t%d", newtemp());
                emit("%s = %s %s %s\n", $$.result, $1.result,
                ($2 == PLUS ? "[+]" : "[-]"), temp);
            }
        } else {
            sprintf($$.result, "t%d", newtemp());
            if ($1.type == _DOUBLE) {
                emit("%s = %s %s %s\n", $$.result, $1.result,
                ($2 == PLUS ? "[+]" : "[-]"), $3.result);

            }else{
                emit("%s = %s %c %s\n", $$.result, $1.result,
                ($2 == PLUS ? '+' : '-'), $3.result);
            }
        }
        $$.type = ($1.type == _DOUBLE || $3.type == _DOUBLE) ? _DOUBLE : _INT;
    };

expression : expression MULOP expression
                {
        char temp[NSIZE];
        if ($1.type != $3.type) {
            sprintf(temp, "t%d", newtemp());
            if ($1.type == _INT) {
                emit("%s = static_cast<%s> %s\n", temp, getType($3.type), $1.result);
                sprintf($$.result, "t%d", newtemp());
                emit("%s = %s %s %s\n", $$.result, temp,
                ($2 == MUL ? "[*]" : "[/]"), $3.result);

            }
            else {
                emit("%s = static_cast<%s> %s\n", temp, getType($1.type), $3.result);
                sprintf($$.result, "t%d", newtemp());
                emit("%s = %s %s %s\n", $$.result, $1.result,
                ($2 == MUL ? "[*]" : "[/]"), temp);
            }
        } else {
            sprintf($$.result, "t%d", newtemp());
            if ($1.type == _DOUBLE) {
                emit("%s = %s %s %s\n", $$.result, $1.result,
                ($2 == MUL ? "[*]" : "[/]"), $3.result);
            } else {
                emit("%s = %s %c %s\n", $$.result, $1.result,
                ($2 == MUL ? '*' : '/'), $3.result);
            }
        }
        $$.type = ($1.type == _DOUBLE || $3.type == _DOUBLE) ? _DOUBLE : _INT;
    }; 
                  
expression :  '(' expression ')' { $$ = $2; }
           |  ID         { 
                  strcpy($$.result, $1);
                  struct symbol *sym = lookup($1);
                  if (sym == NULL) {
                     errorMsg("Undeclared variable %s\n", $1);
                     $$.type = _INT;
                  } else {
                     $$.type = sym->type;
                  }
            }           
           |  INT_NUM    {
                  sprintf($$.result, "%d", $1); 
                  $$.type = _INT;
             }
           |  DOUBLE_NUM {
                  sprintf($$.result, "%.2f", $1); 
                  $$.type = _DOUBLE;
             }
           ;
                  /* L1 */   /* in the example:L2 */
while_stmt: WHILE start_label '('  boolexp  ')' 
			stmt 
                      { emit("goto L_%d\n", $2);
                        emitlabel($4);
					  };



start_label: %empty { $$ = newlabel(); emitlabel($$); };

boolexp:  expression RELOP expression 
             {  $$ = newlabel();
			    emit("ifFalse %s %s %s goto L_%d\n", 
			          $1.result, $2, $3.result, $$);
             };

if_stmt:  IF exit_label '(' boolexp ')' stmt
               { emit("goto L_%d\n", $2);
                 emitlabel($4);
               }				 
          ELSE stmt { emitlabel($2); };
		  
exit_label: %empty { $$ = newlabel(); };

switch_stmt:  SWITCH '(' expression ')' '{'
              test_label /* $6 */
              caselist /* $7 */
			  default_label /* $8 */
			  DEFAULT ':' stmtlist
              '}'
                { emit("goto L_%d\n", $7.exitlabel);
				  emitlabel($6); /* test label */
			      for(int i = 0; i < $7.number_of_cases;i++) {
				      emit("if %s == %d goto L_%d\n",
						      $3.result, $7.cases[i].constant,
							  $7.cases[i].label);
				  }
				  emit("goto L_%d\n", $8);/* goto default */
                  emitlabel($7.exitlabel);
                }				  
			    ;

caselist: caselist CASE INT_NUM ':'
                 {   /* example of using a midrule action
				        having a semantic value: */
				     $<label>$ = newlabel(); 
				     emitlabel($<label>$);
				 }
		  stmtlist
			     {  /* to keep things simple:
				       no fall through: code is generated as if
					   there is a break at the end of each case */
				     emit("goto L_%d\n", $1.exitlabel);
				  
				     $$ = $1;
				     LABEL current_label = $<label>5;
					 int current_case = $1.number_of_cases;
				     $$.cases[current_case].label =
					      current_label;
					 $$.cases[current_case].constant = $3;
				     $$.number_of_cases++;
				  }
         		  ;
                     					 

caselist: %empty { $$.exitlabel = newlabel();
                   $$.number_of_cases = 0;} ;

test_label: %empty { $$ = newlabel(); emit("goto L_%d\n", $$); }

default_label: %empty { $$ = newlabel(); emitlabel($$); }     
                           ;	






















 
for_stmt: FOR '(' INT ID IN INT_NUM DOTS INT_NUM ')' 
{
   // Ensure the loop variable is in the symbol table
    struct symbol *sym = lookup($4);
    if (sym == NULL) {
        sym = putSymbol($4, _INT);
    } else {
        // Handle error if the variable is already declared
        errorMsg("Variable '%s' already declared\n", $4);
        YYERROR;
    }
    // Create labels for loop start, condition check, and exit
    LABEL loop_start = newlabel();
    LABEL loop_end = newlabel();

//---------initialize---------------------------------
   // Emit code to initialize loop variable
    emit("%s = %d\n", $4, $6);

//------------loop_start-----------------------------------
   // Emit code for loop condition check
    emitlabel(loop_start);
    emit("ifFalse %s <= %d goto L_%d\n", $4, $8, loop_end);

   // Store the labels for use in the next action
      $<label>1 = loop_start;
      $<label>2 = loop_end;
}
stmt
{
   // Emit code to increment loop variable
     emit("%s = %s + 1\n", $4, $4);

   // Emit code to jump back to loop condition check
     emit("goto L_%d\n", $<label>1);

    // End of loop
      emitlabel($<label>2);
};


input_stmt: INPUT '(' ID ')' ';' 
{
   // Ensure the variable is in the symbol table
    struct symbol *sym = lookup($3);
    if (sym == NULL) {
        errorMsg("Undeclared variable '%s'\n", $3);
        YYERROR;
    }

    // Generate code for reading input
    if (sym->type == _INT) {
        emit("in %s\n", $3);
    } else if (sym->type == _DOUBLE) {
        emit("[in] %s\n", $3);
    } else {
        errorMsg("Unsupported type for variable '%s'\n", $3);
        YYERROR;
    }
};
             
output_stmt: OUTPUT '(' expression ')' ';' 
{
 // Generate code for writing output based on expression type
    if ($3.type == _DOUBLE) {
        emit("[out] %s\n", $3.result);
    } else if ($3.type == _INT) {
        emit("out %s\n", $3.result);
    } else {
        errorMsg("Unsupported type for expression\n");
        YYERROR;
    }
};


























block_stmt:   '{'  stmtlist '}';

stmtlist: stmtlist stmt { emit("\n"); }
        | %empty
		;				


%%
int main (int argc, char **argv)
{
  extern FILE *yyin; /* defined by flex */
  extern int yydebug;
  
  if (argc > 2) {
     fprintf (stderr, "Usage: %s [input-file-name]\n", argv[0]);
	 return 1;
  }
  if (argc == 2) {
      yyin = fopen (argv [1], "r");
      if (yyin == NULL) {
          fprintf (stderr, "failed to open %s\n", argv[1]);
	      return 2;
	  }
  } // else: yyin will be the standard input (this is flex's default)
  

  yydebug = 0; //  should be set to 1 to activate the trace

  if (yydebug)
      setbuf(stdout, NULL); // (for debugging) output to stdout will be unbuffered
  
  yyparse();
  
  fclose (yyin);
  return 0;
} /* main */

/* called by yyparse() whenever a syntax error is detected */
void yyerror (const char *s)
{
  extern int yylineno; // defined by flex
  
  errorMsg("line %d:%s\n", yylineno,s);
}

/* temporary variables are represented by numbers. 
   For example, 3 means t3
*/
static
TEMP newtemp ()
{
   static int counter = 1;
   return counter++;
} 


// labels are represented by numbers. For example, 3 means L_3
static
LABEL newlabel ()
{
   static int counter = 1;
   return counter++;
} 

// emit works just like  printf  --  we use emit 
// to generate code and print it to the standard output.
void emit (const char *format, ...)
{
/*  /* uncomment following line to stop generating code when errors
	   are detected */
    /* if (errors > 0) return; */ 
    printf ("    ");  // this is meant to add a nice indentation.
                      // Use emitlabel() to print a label without the indentation.    
    va_list argptr;
	va_start (argptr, format);
	// all the arguments following 'format' are passed on to vprintf
	vprintf (format, argptr); 
	va_end (argptr);
}

/* use this  to emit a label without any indentation */
void emitlabel(LABEL label) 
{
    /* uncomment following line to stop generating code when errors
	   are detected */
    /* if (errors > 0) return; */ 
	
    printf ("L_%d:\n",  label);
}

/*  Use this to print error messages to standard error.
    The arguments to this function are the same as printf's arguments
*/
void errorMsg(const char *format, ...)
{
    extern int yylineno; // defined by flex
	
	fprintf(stderr, "line %d: ", yylineno);
	
    va_list argptr;
	va_start (argptr, format);
	// all the arguments following 'format' are passed on to vfprintf
	vfprintf (stderr, format, argptr); 
	va_end (argptr);
	
	errors++;
} 

char* getType(enum type type) {
   if(type == _INT){
      return "int";
   }else{
      return "double";
   }
}






