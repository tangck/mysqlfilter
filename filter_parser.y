/* Copyright (c) 2012, Heng.Wang. All rights reserved.

This program is aimed to filter the sensitive value of given field, if
you have more effective processing methods or some ideas to solve
the problem, thanks for your sharing with the developers. It's pleasure
for you to contact me.
@Author: Heng.Wang
@Email: heng.wang@qunar.com
              heng.wang@outlook.com
              wangheng.king@gmail.com
              king_wangheng@163.com
@Github: https://github.com/HengWang/
*/

%{
#include <stdlib.h>
#include <stdio.h>
#include "filter.h"

int yylex(void);
extern int line_no;
extern char *yytext;

extern sensitive_db_head* sensitive_filter;
static sensitive_table_head* s_tables = NULL;

static void yyerror(const char *s)
{
	fprintf(stderr, "error at line number %d at %s:%s\n", line_no, yytext,
		s);
}

int yywrap(void)
{
	return 1;
}

%}

%token ID DATABASE TABLE

%union {
	char *name;
	int val;
	struct st_sensitive_table_fields_head* table_head;
	struct st_key_value_head* field_head;
}
%type <name> ID
%type <val> start database 
%type <table_head>  table
%type <field_head> field
%start start
%%

start   : start database
	{
		$$ = $1;
	}
	|
	{
		$$ = 1;
	}
        ;
database   :       DATABASE ID '{' table '}'
	{
		sensitive_db* s_db = NULL;
		if(init_db(&s_db, $2, $4)){
			fprintf(stderr, "initialize the db failed when parsing at line number %d, the name of db: %s\n",	line_no, $2);
			$$ = 0;
			return $$;
		}
		if(add_db(sensitive_filter, s_db)){
			uninit_db(s_db);
			fprintf(stderr, "add database failed when parsing at line number %d, the name of db: %s\n",	line_no, $2);
			$$ = 0;
			return $$;
		}
		s_tables = NULL;
		$$ = 1;
	}
	    ;

table
        :     TABLE  ID '{' field '}'
	{
		sensitive_table* s_table = NULL;
		if(!s_tables){
			s_tables = (sensitive_table_head*) my_malloc(sizeof(sensitive_table_head), MYF(MY_WME));
		    if(!s_tables)
		    {
				fprintf(stderr, "malloc the sensitive table head failed when parsing at line number %d\n",	line_no);
				$$ =  0;
				return $$;		    
		    }
		    TAILQ_INIT(s_tables);
	    }
		if(init_table(&s_table, $2, $4)){
			fprintf(stderr, "initialize the table failed when parsing at line number %d, the name of db: %s\n",	line_no, $2);
			$$ = (sensitive_table_head*) NULL;
			return $$;
		}		
		if(add_table(s_tables, s_table)){
			uninit_table(s_table);
			clear_tables(s_tables);
			fprintf(stderr, "add table failed when parsing at line number %d, the name of db: %s\n",	line_no, $2);
			$$ =  (sensitive_table_head*) NULL;
			return $$;
		}
		$$ = s_tables;
	}
	 |       table TABLE  ID '{' field '}'
	{
		sensitive_table* s_table = NULL;
		sensitive_table_head* s_tables = $1;
		if(init_table(&s_table, $3, $5)){
			fprintf(stderr, "initialize the table failed when parsing at line number %d, the name of db: %s\n",	line_no, $3);
			$$ =  (sensitive_table_head*) NULL;
			return $$;
		}
		if(add_table(s_tables, s_table)){
			uninit_table(s_table);
			clear_tables(s_tables);
			fprintf(stderr, "add table failed when parsing at line number %d, the name of db: %s\n",	line_no, $3);
			$$ =  (sensitive_table_head*) NULL;
			return $$;
		}
		$$ = s_tables;
	}
	    ;

field
        :       ID '=' ID ';'
	{
		sensitive_field* s_field = NULL;
		sensitive_field_head* s_fields = NULL;
		if (init_field(&s_field, $1, $3)) {
			fprintf(stderr, "initialize the field failed when parsing at line number %d, the key: %s value: %s\n",
				line_no, $1, $3);
			$$ =  (sensitive_field_head*) NULL;
			return $$;
		}
		if(!(s_fields = (sensitive_field_head*) my_malloc(sizeof(sensitive_field_head), MYF(MY_WME)))){
			uninit_field(s_field);
			fprintf(stderr, "malloc sensitive field head failed when parsing at line number %d\n",	line_no);
			$$ =  (sensitive_field_head*) NULL;
			return $$;
		}
		TAILQ_INIT(s_fields);
		if(add_field(s_fields,s_field))
		{
			uninit_field(s_field);
			my_free(s_fields);
			fprintf(stderr, "add the field failed when parsing at line number %d, the field key: %s value: %s\n",
				line_no, $1, $3);
			$$ = (sensitive_field_head*) NULL;
			return $$;
		}
		$$ = s_fields;
	}
	        |       field ID '=' ID ';'
	{
		sensitive_field* s_field = NULL;
		sensitive_field_head* s_fields = NULL;
		s_fields = $1;
		if (init_field(&s_field, $2, $4)) {
			fprintf(stderr, "initialize the field failed when parsing at line number %d, the key: %s value: %s\n",
				line_no, $2, $4);
			$$ = (sensitive_field_head*) NULL;
			return $$;
		}
		if(add_field(s_fields,s_field))
		{
			uninit_field(s_field);
			fprintf(stderr, "add the field failed when parsing at line number %d, the field key: %s value: %s\n",
				line_no, $2, $4);
			$$ = (sensitive_field_head*) NULL;
			return $$;
		}
		$$ = s_fields;
	}
        ;
%%
