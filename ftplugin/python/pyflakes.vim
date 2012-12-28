if exists("b:pyflakes")
    finish
else
    let b:pyflakes = 1
endif

if !exists("*s:check")
    function s:check()
        call s:info("Start code checking...")
        python << EOF
import vim
from pyflakes import checker
import _ast
from operator import attrgetter

buffer = vim.current.buffer
filename = buffer.name
errors = []

def check(filename):
    try:
        codeString = file(filename, 'U').read() + '\n'
        codelines = codeString.splitlines()
        tree = compile(codeString, filename, "exec", _ast.PyCF_ONLY_AST)
        w = checker.Checker(tree, filename)
        for w in sorted(w.messages, key=attrgetter('lineno')):
            codeline = codelines[w.lineno-1]
            if 'pyflakes: ignore %s' % w.__class__.__name__ in codeline:
                continue
            yield dict(
                lnum=w.lineno,
                col=w.col or 0,
                text=str(w.message % w.message_args),
            )

    except SyntaxError, e:
        yield dict(
                lnum=e.lineno,
                col=e.offset or 0,
                text=e.args[0],
            )

for e in check(filename):
    e.update(dict(filename=filename, bufnr=buffer.number, type='pyflakes'))
    errors.append(e)

vim.command("call setqflist(%r, 'r')" % errors)

has_signs = vim.eval("has('signs')")
if has_signs:
    vim.command('sign unplace *')

if errors:
    vim.command('copen %d' % max(min(len(errors), 6), 3))
    if has_signs:
        for error in errors:
            vim.command('sign place 1 line={lnum} name={type} buffer={bufnr}'.format(**error))
    vim.command('call s:info("Code checking is completed. %d error%s found.")' % (
        len(errors), '' if len(errors) == 1 else 's'))
else:
    vim.command('cclose')
    vim.command('call s:info("Code checking is completed. No errors found.")')
EOF
    endfunction
endif

if !exists('*s:info')
    function s:info(msg)
        let x=&ruler | let y=&showcmd
        set noruler noshowcmd
        redraw
        echohl Debug | echo a:msg | echohl none
        let &ruler=x | let &showcmd=y
    endfunction
endif


autocmd BufWritePost <buffer> :call s:check()
