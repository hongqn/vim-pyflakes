if exists('s:loaded')
    finish
endif
let s:loaded = 1

python << EOF
import sys, vim, os
here = os.path.dirname(vim.eval('expand("<sfile>:p")'))
pyflakes_path = os.path.join(os.path.dirname(here), 'pylibs', 'pyflakes')
sys.path.insert(0, pyflakes_path)
EOF

if has('signs')
    sign define pyflakes text=>> texthl=Error
endif
