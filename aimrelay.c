/*	wrapper2.c
	jms1@jms1.net 1997-11-20

	setuid wrapper for a fixed command

	header files etc. written for linux, compiles ok on solaris 2.6

	set program and parameters (if any) in my_args[]
	  the my_args[] array must have a NULL at the end of the list.

	compile with a command like this:
		gcc -o blah wrapper2.c
	then set the resulting binary so it's owned by root and has the
	"setuid" bit turned on.

	any parameters passed on the command line of the resulting binary
	will be ignored, the parameters in the ma[] array will be passed
	to the final command instead.

	any environment variables will be passed to the final command as-is.
	if you wish to "clear" the environment as a safety measure, run the
	final binary as "env - blah" instead of just "blah".

	---------------------------------------------------------------------

	Copyright (C) 1997,2007 John Simpson.

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License, version 3, as
	published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include <sys/types.h>
#include <unistd.h>

/* you MUST set the command information in this next line */
char *my_args[] = { "/http/clearimage/private/livetalk/aimrelay.pl" , NULL } ;

int main ( int argc , char *argv[] , char *envp[] )
{
	if ( setuid ( 500 ) )
	{
		perror ( "setuid" ) ;
		return 1 ;
	}

	if ( seteuid ( 500 ) )
	{
		perror ( "seteuid" ) ;
		return 1 ;
	}

	execve ( my_args[0] , my_args , envp ) ;

	perror ( "execv" ) ;
	return 1 ;
}

