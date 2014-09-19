map <Leader>t :call RunCurrentTestFile()<CR>
map <Leader>l :call RunLastTest()<CR>
map <Leader>a :call RunAllTests()<CR>

if !exists('g:test_runner_default_project_type')
  let g:test_runner_default_project_type = 'ruby'
endif

if !exists('g:test_runner_rspec_command')
  let g:test_runner_rspec_command = 'rspec {tests_path}'
endif

if !exists('g:test_runner_phpunit_command')
  let g:test_runner_phpunit_command = 'bin/phpunit {tests_path}'
endif

if !exists('g:test_runner_phpspec_command')
  let g:test_runner_phpspec_command = 'bin/phpspec run {tests_path}'
endif

if !exists('g:test_runner_run_command')
  let g:test_runner_run_command = "!clear && echo {test_command} && {test_command}"
endif

function! RunAllTests()
  let l:test_command = s:GetTestCommand()
  call RunTests(l:test_command)
endfunction

function! RunCurrentTestFile()
  if InTestFile()
    let l:current_file = @%
    let l:test_command = s:GetTestCommand(l:current_file)
    call RunTests(l:test_command)
  else
    call RunLastTest()
  endif
endfunction

function s:GetTestCommand(...)
  let l:tests_path = a:0 > 0? a:1 : ''
  if s:IsPhpProject()
    let l:test_command_template = s:GetPhpTestCommandTemplate()
    let l:tests_path = l:tests_path == ''? s:GetPhpTestsPath() : l:tests_path
  else 
    let l:test_command_template = s:GetRubyTestCommandTemplate()
    let l:tests_path = l:tests_path == ''? s:GetRubyTestsPath() : l:tests_path
  endif

  let l:test_command = substitute(l:test_command_template, "{tests_path}", l:tests_path, "g")

  return l:test_command
endfunction

function s:GetPhpTestCommandTemplate()
  return s:InPhpspecContext()? g:test_runner_phpspec_command : g:test_runner_phpunit_command
endfunction

function s:InPhpspecContext()
  return s:InPhpspecFile() || (!s:InPhpunitFile() && s:LastTestWasPhpspec())
endfunction

function s:LastTestWasPhpspec()
  if !exists('s:last_test_command')
    return 0
  endif

  return match(s:last_test_command, 'phpspec') != -1
endfunction

function s:GetRubyTestCommandTemplate()
  return 'rspec {tests_path}'
endfunction

function s:GetPhpTestsPath()
  return s:InPhpspecContext()? '' : 'tests'
endfunction

function s:GetRubyTestsPath()
  return 'spec'
endfunction

function s:IsRubyProject()
  return s:IsProjectType('ruby')
endfunction

function s:IsPhpProject()
  return s:IsProjectType('php')
endfunction

function s:IsProjectType(project_type)
  let l:type = s:GetProjectType()
  return (l:type  == a:project_type) || (!s:IsSupportedProjectType(l:type) && s:IsDefaultProjectType(a:project_type))
endfunction

function s:IsDefaultProjectType(project_type)
  return g:test_runner_default_project_type == a:project_type
endfunction

function s:IsSupportedProjectType(project_type)
  let l:supported_projects = ['ruby', 'php']
  return index(supported_projects, a:project_type) >= 0 
endfunction

function s:GetProjectType()
  return &filetype 
endfunction

function! RunLastTest()
  if exists("s:last_test_command")
    call RunTests(s:last_test_command)
  else
    echom 'nothing to run'
  endif
endfunction

function! InTestFile()
  return s:FileMatches('\(_spec.rb\|Test.php\|Spec.php\)$')
endfunction

function s:InPhpunitFile()
  return s:FileMatches('Test.php$')
endfunction

function s:InPhpspecFile()
  return s:FileMatches('Spec.php$')
endfunction

function s:FileMatches(regex)
  return match(expand("%"), a:regex) != -1
endfunction

function! SetLastTestCommand(test_command)
  let s:last_test_command = a:test_command
endfunction

function! RunTests(test_command)
  call SetLastTestCommand(a:test_command)
  execute s:GetRunCommand(a:test_command)
endfunction

function s:GetRunCommand(cmd)
  return substitute(g:test_runner_run_command, '{test_command}', a:cmd, 'g')
endfunction
