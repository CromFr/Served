module auth;

import pam;

import core.sys.posix.unistd;
import core.sys.posix.pwd;
import core.sys.posix.grp;
version(Posix) private extern (C) int setgroups(size_t size, gid_t* list);

class AuthException : Exception{
	this(in string msg){
		super(msg);
	}
}

class Auth{
	import std.string;
	import std.conv : to;

	static{
		void setUser(in string login)
		{
			version(Posix){
				auto pw = getpwnam(login.toStringz);

				if(pw is null)
					throw new AuthException("Invalid username: '"~login~"'");

				if (pw.pw_gid >= 0) {
					assert(getgrgid(pw.pw_gid) !is null, "Invalid group id!");
					assert(setregid(pw.pw_gid, pw.pw_gid) == 0, "Error setting group id!");
				}

				gid_t grps[1] = [pw.pw_gid];
				setgroups(1, grps.ptr);
				//assert( == 0, "Error setting group id!");

				if (pw.pw_uid >= 0) {
					assert(getpwuid(pw.pw_uid) !is null, "Invalid user id!");
					assert(setreuid(pw.pw_uid, pw.pw_uid) == 0, "Error setting user id!");
				}
			}
		}

		string getUser(in int euid=-1){
			version(Posix){
				auto pw = getpwuid(euid!=-1? euid : geteuid());
				return pw.pw_name.to!string;
			}
			else{
				return "";
			}
		}


		void checkCredentials(in string login, in string passwd)
		{
			version(Posix){
				static __gshared pam_response* convreply;

				int result = 0;

				//Prepare conv
				extern(C)
				int null_conv(int num_msg, const(pam_message*)* msg, pam_response** res, void* appdata_ptr)
				{
					*res = convreply;
					return pam_return.PAM_SUCCESS;
				}
				pam_conv conv = pam_conv(&null_conv, null);

				//Deny empty login
				if(login == ""){
					throw new AuthException("Login can't be null");
				}

				//Start PAM conversation
				pam_handle_t* pamh = null;
				result = pam_start("system-auth", login.toStringz, &conv, &pamh);
				if (result != pam_return.PAM_SUCCESS) {
					throw new AuthException((cast(pam_return)result).to!string~": Bad login");
				}

				//Prepare authentification
				convreply = cast(pam_response*)core.stdc.stdlib.malloc(pam_response.sizeof);
				convreply.resp_retcode = 0;
				//Password copying
				auto p = passwd.to!(char[])~'\0';
				convreply.resp = cast(char*)core.stdc.stdlib.malloc(char.sizeof*(p.length));
				foreach(i ; 0..p.length)
					convreply.resp[i] = p[i];

				//Start authentification
				result = pam_authenticate(pamh, 0);
				if (result != pam_return.PAM_SUCCESS) {
					throw new AuthException((cast(pam_return)result).to!string~": Bad password");
				}

				//End conversation
				pam_end(pamh, result);
			}
		}


		import std.traits : isCallable;
		void executeAs(in string login, void delegate() fun){
			version(Posix){
				string oldlogin = getUser();
				setUser(login);
			}
			fun();
			version(Posix){
				setUser(oldlogin);
			}
		}

		debug void printUID(){
			import std.stdio;
			version(Posix) writeln("uid=",getuid(),"\tgid=",getgid(),"\teuid=",geteuid(),"\tegid=",getegid());
			else           writeln("Only supported on POSIX systems");
		}

	}
}

