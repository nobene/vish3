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
			println('  cd\n  exit\n  help\n')
			println('https://github.com/nobene/vish3')
		}
		else {
//			println(args)
//			println('\n')
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

fn vsh_launch(args []string) {
	mut cmd := 'test'
//	println(cmd)
//	println('mark 1')
//	mut realargs := args.clone()
//	println(realargs[0])
//	println('mark 2')
//	println( args[1])
	if args[0].len == 0 {
		println('vsh: zero input')
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
}

