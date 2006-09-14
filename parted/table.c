/*
 * TODO: - make right and centered alignment possible
 */
/*
    parted - a frontend to libparted
    Copyright (C) 2006
    Free Software Foundation, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
*/



#include <stdio.h>
#include <stdlib.h>

#include <assert.h>

#include <config.h>

#ifdef ENABLE_NLS
#       define _GNU_SOURCE
#       include <wchar.h>
        int wcswidth (const wchar_t *s, size_t n);
#else
#       ifdef wchar_t
#               undef wchar_t
#       endif
#       define _GNU_SOURCE
#       include <string.h>
#       define wchar_t char
#       define wcslen strlen
#       define wcswidth strnlen
#       define wcscat strcat
#       define wcsdup strdup
        size_t strnlen (const char *, size_t);
#endif

#include "strlist.h"


static const unsigned int       MAX_WIDTH = 512;
#ifdef ENABLE_NLS
static const wchar_t*           DELIMITER = L"  ";
static const wchar_t*           COLSUFFIX = L"\n";
#else
static const wchar_t*           DELIMITER = "  ";
static const wchar_t*           COLSUFFIX = "\n";
#endif

typedef struct
{
        unsigned int    ncols;
        unsigned int    nrows;
        wchar_t***      rows;
        int*            widths;
} Table;


Table* table_new(int ncols)
{
        assert ( ncols >= 0 );
        
        Table *t = malloc(sizeof(Table));

        t->ncols = ncols;
        t->nrows = 0;
        t->rows = (wchar_t***)NULL;
        t->widths = NULL;
        
        return t;
}


void table_destroy (Table* t)
{
        unsigned int r, c;
        
        assert (t);
        assert (t->ncols > 0);
        
        for (r = 0; r < t->nrows; ++r)
        {
                for (c = 0; c < t->ncols; ++c)
                        free (t->rows[r][c]);
                free (t->rows[r]);
        }

        if (t->rows)
                free (t->rows);

        if (t->widths)
                free (t->widths);

        free (t);
}


static int max (int x, int y)
{
        return x > y ? x : y;
}


static void table_calc_column_widths (Table* t)
{
        unsigned int r, c;
        
        assert(t);
        assert(t->ncols > 0);
        
        if (!t->widths)
                t->widths = (int*)malloc(t->ncols * sizeof(int));

        for (c = 0; c < t->ncols; ++c)
                t->widths[c] = 0;
        
        for (r = 0; r < t->nrows; ++r)
                for (c = 0; c < t->ncols; ++c)
                {
                        t->widths[c] = max ( t->widths[c],
                                             wcswidth(t->rows[r][c],
                                                      MAX_WIDTH) );
                }
}


/* 
 * add a row which is a string array of ncols elements.
 * 'row' will get freed by table_destroy;  you must not free it
 * yourself.
 */
void table_add_row (Table* t, wchar_t** row)
{
        assert(t);

        /*unsigned int i;
        printf("adding row: ");
        for (i = 0; i < t->ncols; ++i)
                printf("[%s]", row[i]);
        printf("\n");*/

        t->rows = (wchar_t***)realloc (t->rows, (t->nrows + 1)
                                                * sizeof(wchar_t***));
         
        t->rows[t->nrows] = row;

        ++t->nrows;

        table_calc_column_widths (t);
}


void table_add_row_from_strlist (Table* t, StrList* list)
{
        wchar_t** row = (wchar_t**)malloc(str_list_length(list)
                                          * sizeof(wchar_t**));
        int i = 0;

        while (list)
        {
                row[i] = (wchar_t*)list->str;

                list = list->next;
                ++i;
        }

        table_add_row (t, row);
}


/* render a row */
static void table_render_row (Table* t, int rownum, int ncols, wchar_t** s)
{
        wchar_t** row = t->rows[rownum];
        int len = 1, i;
        size_t newsize;

        assert(t);
        assert(s != NULL);
        
        for (i = 0; i < ncols; ++i)
                len += t->widths[i] + wcslen(DELIMITER);

        len += wcslen(COLSUFFIX);

        newsize = (wcslen(*s) + len + 1) * sizeof(wchar_t);
        *s = realloc (*s, newsize);

        for (i = 0; i < ncols; ++i)
        {
                int j;
                int nspaces = max(t->widths[i] - wcswidth(row[i], MAX_WIDTH),
                                  0);
                wchar_t* pad = malloc ( (nspaces + 1) * sizeof(wchar_t) );

                for (j = 0; j < nspaces; ++j)
                       pad[j] = L' '; 

#ifdef ENABLE_NLS
                pad[nspaces] = L'\0';
#else
                pad[nspaces] = '\0';
#endif
                
                wcscat (*s, row[i]);
                wcscat (*s, pad);
                if (i + 1 < ncols) 
                        wcscat (*s, DELIMITER);

                free (pad);
        }

        wcscat (*s, COLSUFFIX);
}


/* 
 * Render the rows.
 * \p s must be a null-terminated string.
 */
static void table_render_rows (Table* t, wchar_t** s)
{
        unsigned int i;

#ifdef ENABLE_NLS
        assert (**s == L'\0');
#else
        assert (**s == '\0');
#endif
        
        for (i = 0; i < t->nrows; ++i)
                table_render_row (t, i, t->ncols, s);
}

/* 
 * Render the table to a string.
 * You are responsible for freeing the returned string.
 */
wchar_t* table_render(Table* t)
{
        wchar_t* s = malloc(sizeof(wchar_t));
#ifdef ENABLE_NLS
        *s = L'\0';
#else
        *s = '\0';
#endif
        
        table_render_rows (t, &s);
        
        return s;
}

