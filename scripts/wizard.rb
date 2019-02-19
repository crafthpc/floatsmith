#!/usr/bin/env ruby
#
# FloatSmith interactive driver
#

# needed for opening stderr as well as stdin/stdout
# when spawning new system processes
require 'open3'

# needed for file manipulation and directory removal
require 'fileutils'

# needed for inter-tool JSON parsing and generating
require 'json'

#{{{ input routines

# read a boolean (yes/no) from standard input
def input_boolean(prompt, default)
    if not default.nil? then
        prompt += " [default='#{default ? "y" : "n"}'] "
    end
    print prompt
    r = gets.chomp.downcase
    r = (default ? "y" : "n") if r == "" and not default.nil?
    while not "yn".chars.include?(r)
        puts "Invalid response: #{r}"
        print prompt
        r = gets.chomp.downcase
        r = (default ? "y" : "n") if r == "" and not default.nil?
    end
    return r == 'y'
end

# read a single-letter option from standard input
def input_option(prompt, valid_opts)
    print prompt
    opt = gets.chomp.downcase
    while not valid_opts.chars.include?(opt)
        puts "Invalid option '#{opt}'"
        print prompt
        opt = gets.chomp.downcase
    end
    return opt
end

# read a path from standard input (optionally check for existence)
def input_path(prompt, default, must_exist=true)
    if not default.nil? then
        prompt += " [default='#{default}'] "
    end
    print prompt
    path = gets.chomp
    ok = false
    while not ok
        ok = true
        if path == "" then
            if default.nil? then
                puts "ERROR: must enter a path"
                ok = false
            else
                path = default
            end
        end
        if must_exist and not Dir.exist?(path) then
            puts "ERROR: #{path} does not exist (or is a regular file)"
            ok = false
        end
        if not ok then
            print prompt
            path = gets.chomp
        end
    end
    return path
end

# }}}

# {{{ exec_cmd - run a command and optionally echo or return output
def exec_cmd(cmd, echo_stdout=true, echo_stderr=false, return_stdout=false)
    stdout = []
    Open3.popen3(cmd) do |io_in, io_out, io_err|
        io_out.each_line do |line|
            puts line if echo_stdout
            stdout << line if return_stdout
        end
        io_err.each_line { |line| puts line } if echo_stderr
    end
    return stdout.join("\n")
end # }}}

# {{{ save_cmd - run a command and save standard output to a file
def save_cmd(cmd, stdout_fn)
    Open3.popen3(cmd) do |io_in, io_out, io_err|
        io_out.each_line { |line| puts line } if echo_stdout
        io_err.each_line { |line| puts line } if echo_stderr
    end
end # }}}

# {{{ run_wizard - main driver routine
def run_wizard

    puts ""
    puts "== FloatSmith Wizard =="
    puts ""
    puts "Welcome to the FloatSmith source tuning wizard."
    puts ""

    # initialize paths
    $WIZARD_ROOT    = File.absolute_path(input_path("Where do you want to " +
                      "save configuration and search files?", "./.craft", false))
    $WIZARD_SANITY  = "#{$WIZARD_ROOT}/sanity"
    $WIZARD_BASE    = "#{$WIZARD_ROOT}/baseline"
    $WIZARD_INITIAL = "#{$WIZARD_ROOT}/initial"
    $WIZARD_TFVARS  = "#{$WIZARD_ROOT}/typeforge_vars.json"
    $WIZARD_INITCFG = "#{$WIZARD_ROOT}/craft_initial.json"
    $WIZARD_ADRUN   = "#{$WIZARD_ROOT}/autodiff"
    $WIZARD_ADOUT   = "#{$WIZARD_ROOT}/craft_recommend.json"
    $WIZARD_SEARCH  = "#{$WIZARD_ROOT}/search"
    $WIZARD_ACQUIRE = "#{$WIZARD_ROOT}/wizard_acquire"
    $WIZARD_BUILD   = "#{$WIZARD_ROOT}/wizard_build"
    $WIZARD_RUN     = "#{$WIZARD_ROOT}/wizard_run"
    $WIZARD_VERIFY  = "#{$WIZARD_ROOT}/wizard_verify"

    # make sure configuration folder exists
    if not File.exist?($WIZARD_ROOT) then
        Dir.mkdir($WIZARD_ROOT)
    elsif not Dir.exist?($WIZARD_ROOT) then
        puts "ERROR: #{$WIZARD_ROOT} already exists as a regular file"
        exit
    end

    # print intro text and generate acquisition script
    if not File.exist?($WIZARD_ACQUIRE) then
        puts "NOTE: We recommend cleaning your project before running this script!"
        puts ""
        puts "To search in parallel automatically, the system must be able to:"
        puts "  1) acquire a copy of your code,"
        puts "  2) build your code using generic CC/CXX variables,"
        puts "  3) run your program using representative inputs, and"
        puts "  4) verify that the output is acceptable."
        puts ""
        puts "How would you like to acquire a copy of your code?"
        puts "  a) Recursive copy from a local folder"
        puts "  b) Clone a git repository"
        opt = input_option("Choose an option above: ", "ab")
        case opt
        when "a"
            path = input_path("Enter project root path: ", ".", true)
            cmd = "cp -rL #{File.absolute_path(path)}/* ."
        when "b"
            print "Enter repository URL: "
            cmd = "git clone #{gets.chomp}"
        end
        File.open($WIZARD_ACQUIRE, 'w') do |f|
            f.puts "#/usr/bin/bash"
            f.puts cmd
        end
        File.chmod(0700, $WIZARD_ACQUIRE)
        puts "Acquisition script created: #{$WIZARD_ACQUIRE}"
        puts ""
    end

    # generate build script
    if not File.exist?($WIZARD_BUILD) then
        puts "How is your project built?"
        puts "  a) \"make\""
        puts "  b) \"./configure && make\""
        puts "  c) \"cmake .\""
        puts "  d) Custom script"
        opt = input_option("Choose an option above: ", "abcd")
        script = []
        case opt
        when "a"
            script << "make || (echo \"status:  error\" && exit)"
        when "b"
            script << "(./configure && make) || (echo \"status:  error\" && exit)"
        when "c"
            script << "cmake . || (echo \"status:  error\" && exit)"
        when "d"
            puts "Enter Bash code to build your program."
            puts "Print \"status:  error\" if the build fails."
            puts "Enter an empty line to finish."
            line = gets.chomp
            while line != ""
                script << line
                line = gets.chomp
            end
        end
        File.open($WIZARD_BUILD, 'w') do |f|
            f.puts "#/usr/bin/bash"
            script.each { |line| f.puts line }
        end
        File.chmod(0700, $WIZARD_BUILD)
        puts "Build script created: #{$WIZARD_BUILD}"
        puts ""
    end

    # generate run script
    if not File.exist?($WIZARD_RUN) then
        puts "Enter command(s) to run your program with representative input."
        puts "If you need to save the output for verification purposes, please"
        puts "write it to \"stdout\" in the current folder. Enter an empty line"
        puts "to finish."
        puts ""
        script = []
        line = gets.chomp
        while line != ""
            script << line
            line = gets.chomp
        end
        File.open($WIZARD_RUN, 'w') do |f|
            f.puts "#/usr/bin/bash"
            script.each { |line| f.puts line }
        end
        File.chmod(0700, $WIZARD_RUN)
        puts "Run script created: #{$WIZARD_RUN}"
        puts ""
    end

    # generate verification script
    if not File.exist?($WIZARD_VERIFY) then
        puts "How should the output be verified?"
        puts "  a) Exact match with original"
        puts "  b) Contains a line matching a regex"
        puts "  c) Contains no lines matching a regex"
        puts "  d) Custom script"
        opt = input_option("Choose an option above: ", "abcd")
        script = []
        case opt
        when "a"
            FileUtils.rm_rf $WIZARD_BASE
            Dir.mkdir $WIZARD_BASE
            Dir.chdir $WIZARD_BASE
            exec_cmd($WIZARD_ACQUIRE, false)
            exec_cmd($WIZARD_BUILD, false)
            exec_cmd($WIZARD_RUN, false)
            script << "outdiff=$(diff stdout #{$WIZARD_BASE}/stdout)"
            script << "if [[ -z \"$outdiff\" ]]; then"
            script << "    echo \"status:  pass\""
            script << "else"
            script << "    echo \"status:  fail\""
            script << "fi"
        when "b"
            puts "Enter regex: "
            regex = gets.chomp
            script << "search=$(grep -E '#{regex}' stdout)"
            script << "if [[ -z \"$search\" ]]; then"
            script << "    echo \"status:  fail\""
            script << "else"
            script << "    echo \"status:  pass\""
            script << "fi"
        when "c"
            puts "Enter regex: "
            regex = gets.chomp
            script << "search=$(grep -E '#{regex}' stdout)"
            script << "if [[ -z \"$search\" ]]; then"
            script << "    echo \"status:  pass\""
            script << "else"
            script << "    echo \"status:  fail\""
            script << "fi"
        when "d"
            puts "Enter Bash code to verify your program output: (empty line to finish)"
            script = []
            line = gets.chomp
            while line != ""
                script << line
                line = gets.chomp
            end
        end
        File.open($WIZARD_VERIFY, 'w') do |f|
            f.puts "#/usr/bin/bash"
            script.each { |line| f.puts line }
        end
        File.chmod(0700, $WIZARD_VERIFY)
        puts "Verify script created: #{$WIZARD_VERIFY}"
        puts ""
    end

    # run sanity check
    if input_boolean("Do you want to run a sanity check to test the generated scripts?", true) then
        FileUtils.rm_rf $WIZARD_SANITY
        Dir.mkdir $WIZARD_SANITY
        Dir.chdir $WIZARD_SANITY
        exec_cmd $WIZARD_ACQUIRE
        exec_cmd $WIZARD_BUILD
        exec_cmd $WIZARD_RUN
        exec_cmd $WIZARD_VERIFY
        puts ""
    end

    # phase 1a: variable discovery
    if not File.exist?($WIZARD_TFVARS) then
        puts "Finding variables to be tuned."
        FileUtils.rm_rf($WIZARD_INITIAL)
        Dir.mkdir $WIZARD_INITIAL
        Dir.chdir $WIZARD_INITIAL
        script = []
        script << "{ \"version\": \"1\","
        script << "  \"tool_id\": \"FloatSmith\","
        script << "  \"actions\": ["
        script << "    { \"action\": \"list_changes_basetype\","
        script << "      \"scope\": \"\","
        script << "      \"from_type\": \"double\","
        script << "      \"to_type\": \"float\""
        script << "    } ] }"
        File.open("#{$WIZARD_INITIAL}/initial.json", "w") do |f|
            script.each { |line| f.puts line }
        end
        exec_cmd $WIZARD_ACQUIRE
        File.open("#{$WIZARD_INITIAL}/run.sh", "w") do |f|
          script << "      \"name\": \"#{$WIZARD_TFVARS}\","
            f.puts "export CC='typeforge --plugin initial.json --typeforge-out #{$WIZARD_TFVARS} --compile'"
            f.puts "export CXX='typeforge --plugin initial.json --typeforge-out #{$WIZARD_TFVARS} --compile'"
            f.puts "#{$WIZARD_BUILD}"
        end
        File.chmod(0700, "#{$WIZARD_INITIAL}/run.sh")
        exec_cmd "#{$WIZARD_INITIAL}/run.sh"
        puts "Variables discovered: #{$WIZARD_TFVARS}"
        puts ""
    end

    # verify that TypeForge found at least one variable
    cfg = JSON.parse(IO.read($WIZARD_TFVARS))
    if not cfg.has_key?("actions") or cfg["actions"].size == 0 then
        puts "TypeForge did not find any variables to tune."
        puts "Aborting search."
        exit
    end

    # phase 1b: variable review (optional)
    if not File.exist?($WIZARD_INITCFG) then
        puts "Some variables may not be appropriate candidates for tuning (e.g., if they"
        puts "are used for calculating error). You may wish to remove them from the list."
        if input_boolean("Do you wish to review/edit the list of variables?", true) then
            cfg = JSON.parse(IO.read($WIZARD_TFVARS))
            cfg["actions"].each_index do |i|
                a = cfg["actions"][i]
                puts "  #{i}) #{a["name"]} (#{a["scope"]}) [#{a["source_info"].gsub(/.*\//, "")}]"
            end
            puts "Enter ID numbers for any variables you wish to remove, separate by spaces:"
            ids = gets.split(" ").map { |x| x.to_i }
            new_actions = []
            cfg["actions"].each_index do |i|
                new_actions << cfg["actions"][i] if not ids.include?(i)
            end
            cfg["actions"] = new_actions
            IO.write($WIZARD_INITCFG, JSON.pretty_generate(cfg))
        else
            FileUtils.cp($WIZARD_TFVARS, $WIZARD_INITCFG)
        end
        puts "Initial configuration created: #{$WIZARD_INITCFG}"
        puts ""
    end

    # phase 2: ADAPT instrumentation (optional)
    if not Dir.exist?($WIZARD_ADRUN) then
        puts "If you wish, now we can run your program with ADAPT"
        puts "instrumentation. This will most likely cause the search to"
        puts "converge faster, but your program must be compilable using"
        puts "'-std=c++11' and you must have included all of the appropriate"
        puts "pragmas (see documentation)."
        if input_boolean("Do you wish to run ADAPT?", false) then
            Dir.mkdir $WIZARD_ADRUN
            Dir.chdir $WIZARD_ADRUN
            script = []
            script << "{ \"version\": \"1\","
            script << "  \"tool_id\": \"FloatSmith\","
            script << "  \"actions\": ["
            script << "    { \"action\": \"replace_pragma\","
            script << "      \"from_type\": \"adapt output\","
            script << "      \"to_type\": \"AD_dependent($2, \\\"$2\\\", $3);\""
            script << "    }, { \"action\": \"replace_pragma\","
            script << "      \"from_type\": \"adapt begin\","
            script << "      \"to_type\": \"AD_begin();\""
            script << "    }, { \"action\": \"replace_pragma\","
            script << "      \"from_type\": \"adapt end\","
            script << "      \"to_type\": \"AD_end(); AD_report();\""
            script << "    }, { \"action\": \"add_include\","
            script << "      \"name\": \"adapt.h\","
            script << "      \"scope\": \"*\""
            script << "    }, { \"action\": \"add_include\","
            script << "      \"name\": \"adapt-impl.cpp\","
            script << "      \"scope\": \"main\""
            script << "    }, { \"action\": \"ad_intermediate_instrumentation\","
            script << "      \"scope\": \"*\""
            script << "    }, { \"action\": \"change_every_basetype\","
            script << "      \"scope\": \"*:args,ret,body\","
            script << "      \"from_type\": \"double\","
            script << "      \"to_type\": \"AD_real\""
            script << "    }, { \"action\": \"change_every_basetype\","
            script << "      \"scope\": \"$global\","
            script << "      \"from_type\": \"double\","
            script << "      \"to_type\": \"AD_real\""
            script << "    }, { \"action\": \"change_every_basetype\","
            script << "      \"scope\": \"*:args,ret,body\","
            script << "      \"from_type\": \"float\","
            script << "      \"to_type\": \"AD_real\""
            script << "    }, { \"action\": \"change_every_basetype\","
            script << "      \"scope\": \"$global\","
            script << "      \"from_type\": \"float\","
            script << "      \"to_type\": \"AD_real\""
            script << "    } ] }"
            File.open("#{$WIZARD_ADRUN}/instrument.json", "w") do |f|
                script.each { |line| f.puts line }
            end
            exec_cmd $WIZARD_ACQUIRE
            File.open("#{$WIZARD_ADRUN}/run.sh", "w") do |f|
                f.puts "export CXX='typeforge --plugin instrument.json --compile" +
                       " -std=c++11 -I${CODIPACK_ROOT}/include -I${$ADAPT_ROOT}" +
                       " -DCODI_EnableImplicitConversion -DCODI_DisableImplicitConversionWarning'"
                f.puts "#{$WIZARD_BUILD}"
                f.puts "#{$WIZARD_RUN}"
                f.puts "cp craft_recommend.json #{$WIZARD_ADOUT}"
            end
            File.chmod(0700, "#{$WIZARD_ADRUN}/run.sh")
            exec_cmd "#{$WIZARD_ADRUN}/run.sh"
            if File.exist?($WIZARD_ADOUT) then
                puts "AD instrumentation results created: #{$WIZARD_ADOUT}"
            else
                puts "AD instrumentation results were NOT created!"
            end
        end
        puts ""
    end

    # phase 3: mixed-precision search
    if Dir.exist?($WIZARD_SEARCH) then
        run_search = input_boolean("There are existing (possibly incomplete) search results.\n" +
                                   "Do you wish to erase them and run again?", true)
    else
        run_search = true
    end
    if run_search then
        FileUtils.rm_rf $WIZARD_SEARCH
        Dir.mkdir $WIZARD_SEARCH if not Dir.exist?($WIZARD_SEARCH)
        Dir.chdir $WIZARD_SEARCH
        File.open("#{$WIZARD_SEARCH}/craft_builder", "w") do |f|
            f.puts IO.read($WIZARD_ACQUIRE)
            f.puts "export CC=\"typeforge --plugin $1 --compile\""
            f.puts "export CXX=\"typeforge --plugin $1 --compile\""
            f.puts IO.read($WIZARD_BUILD)
            # TODO: print "status:  abort" if build fails
        end
        File.chmod(0700, "#{$WIZARD_SEARCH}/craft_builder")
        File.open("#{$WIZARD_SEARCH}/craft_driver", "w") do |f|
            f.puts "#!/bin/bash"
            f.puts "t_start=$(date +%s.%3N)"
            f.puts IO.read($WIZARD_RUN)
            f.puts "t_stop=$(date +%s.%3N)"
            f.puts "echo \"time:    $(echo \"$t_stop - $t_start\" | bc)\""
            f.puts IO.read($WIZARD_VERIFY)
            # TODO: handle 'error' output
        end
        File.chmod(0700, "#{$WIZARD_SEARCH}/craft_driver")
        cmd = "craft search -V -c ../craft_initial.json"
        if File.exist?($WIZARD_ADOUT) then
            cmd += " -A ../craft_recommend.json"
        end
        puts "CRAFT supports several search strategies:"
        puts "  a) Combinational - try all combinations (very expensive!)"
        puts "  b) Compositional - try individuals then try to compose passing configurations"
        puts "  c) Delta debugging - binary search on the list of variables"
        opt = input_option("Which strategy do you wish to use for the search? ", "abc")
        cmd += " -s compositional" if opt == "b"
        cmd += " -s ddebug" if opt == "c"
        print "How many trials of each configuration do you want to run? [default=5] "
        ntrials = gets.chomp
        ntrials = "5" if ntrials == ""
        cmd += " -t #{ntrials}" if ntrials.to_i > 1
        cpus = exec_cmd("cat /proc/cpuinfo | grep processor | wc -l", false, false, true).chomp
        print "How many worker threads do you want to use? [default=#{cpus}] "
        nworkers = gets.chomp
        nworkers = cpus if nworkers == ""
        cmd += " -j #{nworkers}" if nworkers.to_i > 1
        File.open("#{$WIZARD_SEARCH}/run.sh", "w") do |f|
            f.puts "#!/bin/bash"
            f.puts cmd
        end
        File.chmod(0700, "#{$WIZARD_SEARCH}/run.sh")
        exec_cmd "#{$WIZARD_SEARCH}/run.sh"
        puts ""
    end

end # }}}

run_wizard
