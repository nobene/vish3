/*-
 * SPDX-License-Identifier: BSD-2-Clause
 * See ./LICENSE file for details.
 */

module main

import os {
	chdir,
	expand_tilde_to_home,
	home_dir,
	input,
}


import regex

fn main() {
	vsh_startloop()
	exit(0)
}

pub fn vsh_startloop() {
	mut userid := '$'
	for {
		if os.getuid() == 0 {
			userid = '#'
		} else {
			userid = '$'
		}
		prompt := '${os.loginname() or { '???' } }@${os.hostname() or { '???' } }:${userid}${os.getwd()} >> '
		cmd := input(prompt)
		if cmd == '<EOF>' {
			exit(0)
		}
		args := vsh_parseargs(cmd)
		vsh_exec(args)
	}
	return
}

fn vsh_parseargs(cmd string) []string {
	return cmd.split_any(' \t\r\n\a')
}

fn vsh_exec(args []string) {
	if args.len == 0 {
		return
	}
	query1 := r'^[\.\/]'
	query2 := r'^\W{2,}'
	mut re1 := regex.regex_opt(query1) or { panic(err) }
	mut re2 := regex.regex_opt(query2) or { panic(err) }
	match args[0] {
		'exit' {
			if args.len > 1 {
				exit(args[1].int())
			} else {
				exit(0)
			}
		}
		'cd' {
			mut path := home_dir()
			if args.len > 1 {
				path = expand_tilde_to_home(args[1])
			}
			chdir(path) or {
				eprintln(err)
				return
			}
		}
		'help' {
			println('Vish3 Buitins: ')
			println('  cd\n  exit\n  help\n pwd\n')
			println('https://github.com/nobene/vish3')
		}
//		'|' {
//			println(args[0])
//		}
//		"[']" {
//			exit(0)
//		}
		else {
			if args[0].len == 0 {
//				println('vish3 error: zero input')
			return
			}
//			println(args[0].bytes())
			if args[0].bytes()[0] == 27 && args[0].len == 1 {
			println('vish3 stopped by pressed ESC...')
				exit(0)
			}
//			println('\n')
			if '|' in args {
			vsh_exec_piped(args)
			println('returning from vsh_exec')
			return
			}
			if re1.matches_string(args[0].split(' >> ')[0]) {
//				println('dbg: matched . or /')
				vsh_launch(args)
				return
			}
			if re2.matches_string(args[0].split(' >> ')[0]) {
//				println('dbg: matched stop char')
				return
//				exit(0)
			}
			vsh_launch(args)
		}
	}
}

fn vsh_exec_piped(args []string) {
	if args.len == 0 {
		return
	}
//	query1 := r'^[\.\/]'
//	query2 := r'^\W{2,}'
//	mut re1 := regex.regex_opt(query1) or { panic(err) }
//	mut re2 := regex.regex_opt(query2) or { panic(err) }
	match args[0] {
//		'exit' {
//			if args.len > 1 {
//				exit(args[1].int())
//			} else {
//				exit(0)
//			}
//		}
		'cd' {
			mut path := home_dir()
			if args.len > 1 {
				path = expand_tilde_to_home(args[1])
			}
			chdir(path) or {
				eprintln(err)
				return
			}
		} else {
			if args[0].len == 0 {
//				println('vish3 error: zero input')
			return
			}
//			println(args[0].bytes())
			if args[0].bytes()[0] == 27 && args[0].len == 1 {
			println('vish3 stopped by pressed ESC...')
				exit(0)
			}
			if args[0].bytes()[0] == 124 {
				println('error: "|" can not be 1st char of command')
				return
			}
			println('in _piped \n')
//			println(args)
//			println('\n')
			println(args[0])
			if u8(124) in args[0].bytes() {
				println('error: no spaces around "|" in argument 1')
				return
			}
			if args.len > 2 {
				if u8(124) in args[2].bytes() {
					println('error: no spaces around "|" in argument 3')
					return
				}
			}
			if args.len > 1 {
				println(args[1])
			}
			if args.len > 2 {
				println(args[2])
				println(args[3])
				println('\n')
				mut cmd0 := os.find_abs_path_of_executable(args[0]) or { args[0] }
				if cmd0.len == 0 {
					cmd0 = 'test'
				}
				mut p0 := os.new_process(cmd0)
				p0.run()
				p0.set_redirect_stdio()
//				r := p0.pipe_read(.stdout).str()
//				if p0.is_pending(.stdout) { dump( p0.stdout_read() ) }
				r := p0.stdout_read()
				p0.close()
				mut cmd2 := os.find_abs_path_of_executable(args[0]) or { args[0] }
				if cmd2.len == 0 {
					cmd2 = 'test'
				}
				mut p2 := os.new_process(cmd2)
//				ln := args.len - 1
				p2.set_args(args[3..3])
				p2.run()
				p2.set_redirect_stdio()
				p2.stdin_write(r)
				p0.wait()
				p2.wait()
//				println(r)
				return
			}
//			if re1.matches_string(args[0].split(' >> ')[0]) {
//				println('dbg: matched . or /')
//				vsh_launch(args)
//				return
//			}
//			if re2.matches_string(args[0].split(' >> ')[0]) {
//				println('dbg: matched stop char')
//				return
//				exit(0)
//			}
//			vsh_launch(args)
		}
	}
}

fn vsh_launch(args []string) {
	mut cmd := 'test'
//	println(cmd)
//	println('mark 1')
//	mut realargs := args.clone()
//	println(realargs[0])
//	println('mark 2')
//	println( args[1])
	if args[0].len == 0 {
		println('vish3 : zero input')
		return
	}
	if args[0][0] == byte(`/`) {
		cmd = args[0]
	} else {
		cmd = os.find_abs_path_of_executable(args[0]) or { args[0] }
	}
	if cmd.len == 0 {
		cmd = 'test'
	}
//	println(cmd)
//	println('mark 3')
	mut p := os.new_process(cmd)
//	if args[1].len != 0 {
	p.set_args(args[1..])
//	}
	p.run()
	p.wait()
	return
}




