#!/usr/bin/env ruby
#
# FloatSmith interactive driver
#
# This script is meant to be relatively accessible to anyone familiar with
# systems development. It also generates a LOT of helper scripts that can be run
# independently to re-run a particular phase or to help debug an issue. By
# default all of the helper scripts and intermediate/result files are stored in
# a hidden folder (".floatsmith" by default), providing separation between your
# project files and the results of the analysis.
#
# There is a batch mode ('-B') that accepts all defaults when prompted and
# allows you to customize the process with command-line parameters. It is
# recommended that you run at least once interactively before attempting to use
# the batch mode.
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
        return default if $FS_BATCHMODE
        prompt += " [default='#{default ? "y" : "n"}'] "
    end
    print prompt
    r = STDIN.gets.chomp.downcase
    r = (default ? "y" : "n") if r == "" and not default.nil?
    while not "yn".chars.include?(r)
        puts "Invalid response: #{r}"
        print prompt
        r = STDIN.gets.chomp.downcase
        r = (default ? "y" : "n") if r == "" and not default.nil?
    end
    return r == 'y'
end

# read an integer from standard input
def input_integer(prompt, default)
    if not default.nil? then
        return default if $FS_BATCHMODE
        prompt += " [default='#{default}'] "
    end
    print prompt
    num = STDIN.gets.chomp
    num = default if num == "" and not default.nil?
    num = num.to_i
    return num
end

# read a single-letter option from standard input
def input_option(prompt, valid_opts, default)
    if not default.nil? then
        return default if $FS_BATCHMODE
        prompt += " [default='#{default}'] "
    end
    print prompt
    opt = STDIN.gets.chomp.downcase
    opt = default if opt == "" and not default.nil?
    while not valid_opts.chars.include?(opt)
        puts "Invalid option '#{opt}'"
        print prompt
        opt = STDIN.gets.chomp.downcase
    end
    return opt
end

# read a path from standard input (optionally check for existence)
def input_path(prompt, default, must_exist=true)
    if not default.nil? then
        return default if $FS_BATCHMODE
        prompt += " [default='#{default}'] "
    end
    print prompt
    path = STDIN.gets.chomp
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
            path = STDIN.gets.chomp
        end
    end
    return path
end

# }}}

# {{{ command execution routines
def exec_cmd(cmd, echo_stdout=true, echo_stderr=false, return_stdout=false, log_file=nil)
    # run a command and optionally echo or return output
    stdout = []
    io_in, io_out, io_err, wait_thr = Open3.popen3(cmd)
    io_in.close
    Thread.new do
        io_err.each_line do |line|
            puts line if echo_stderr
            File.open(log_file, "a") { |f| f.puts line } if not log_file.nil?
        end
        io_err.close
    end
    Thread.new do
        io_out.each_line do |line|
            puts line if echo_stdout
            stdout << line if return_stdout
            File.open(log_file, "a") { |f| f.puts line } if not log_file.nil?
        end
        io_out.close
    end
    exit_status = wait_thr.value
    return stdout.join("\n")
end # }}}

# run_driver - main driver routine
def run_driver

    # {{{ print help text
    puts ""
    if ARGV.include?("-h") then
        puts "FloatSmith batch mode ('-B') uses all default options unless overridden"
        puts "using any of the following flags:"
        puts ""
        puts "FloatSmith options:"
        puts "  --root \"name\"                   use \"name\" as the temporary file folder"
        puts "  --run \"cmd\"                     use \"cmd\" to run the program"
        puts "  --verify-regex \"regex\"          check for \"regex\" in output as verification"
        puts "  --verify-script \"script\"        run given script for verification"
        puts "  --ignore \"var1 var2 etc\"        ignore all variables with the provided names"
        puts "  --adapt                         run the ADAPT phase (off by default)"
        puts ""
        puts "CRAFT options:"
        puts "  -s <name>                       run the specified CRAFT search strategy"
        puts "      Valid strategy names:"
        puts "        compositional             try individuals then try to compose passing configurations"
        puts "        ddebug                    binary search on the list of variables"
        puts "        combinational             try all combinations (very expensive!)"
        puts "        simple                    hierarchical readth-first search on program structure to find passing configurations"
        puts "        comp_simple               hierarchical + compositional"
        puts " -t <number>                      run the specified number of trials per configuration during the CRAFT search [default=10]"
        puts " -T <number>                      timeout trials after <n> seconds [default=1.5x baseline runtime]"
        puts " -J slurm                         submit configuration runs as SLURM jobs [default=false]"
        puts " -j <number>                      run the specified max number of simultaneous configurations during the CRAFT search [default=num cpus]"
        puts "                                  (-j is generally not used with \"-J slurm\" because SLURM manages the queue)"
        puts " -g <tag>                         group variables by labels beginning with the given tag"
        puts " -M                               merge overlapping groups (no effect without \"-g\""
        puts " -C \"<options>\"                   pass through some other option(s)"
        puts ""
        exit
    end # }}}

    # {{{ check for batch mode and print intro text if necessary
    $FS_BATCHMODE = ARGV.include?("-B")
    if not $FS_BATCHMODE then
        puts "Welcome to the FloatSmith source tuning framework."
        puts ""
        puts "If you wish to run FloatSmith non-interactively, run with the '-B' (batch mode) option."
        puts "Run with '-h' for other options in that mode."
        puts ""
        puts "NOTE: We highly recommend cleaning your project before running this script!"
        puts ""
        puts "To search in parallel automatically, the system must be able to:"
        puts "  1) acquire a copy of your code,"
        puts "  2) build your code using the generic CXX variable,"
        puts "  3) run your program using representative inputs, and"
        puts "  4) verify that the output is acceptable."
        puts ""
    end # }}}

    # {{{ initialize paths
    if ARGV.include?("--root") then
        $FS_ROOT = File.absolute_path(ARGV[ARGV.find_index("--root")+1])
    else
        $FS_ROOT  = File.absolute_path(input_path("Where do you want to " +
                        "save configuration and search files?", "./.floatsmith", false))
    end
    $FS_SANITY  = "#{$FS_ROOT}/sanity"
    $FS_BASE    = "#{$FS_ROOT}/baseline"
    $FS_INITIAL = "#{$FS_ROOT}/initial"
    $FS_TFVARS  = "#{$FS_ROOT}/typeforge_vars.json"
    $FS_INITCFG = "#{$FS_ROOT}/craft_initial.json"
    $FS_ADRUN   = "#{$FS_ROOT}/autodiff"
    $FS_ADOUT   = "#{$FS_ROOT}/adapt_recommend.json"
    $FS_SEARCH  = "#{$FS_ROOT}/search"
    $FS_ACQUIRE = "#{$FS_ROOT}/acquire.sh"
    $FS_BUILD   = "#{$FS_ROOT}/build.sh"
    $FS_RUN     = "#{$FS_ROOT}/run.sh"
    $FS_VERIFY  = "#{$FS_ROOT}/verify.sh"
    $FS_PHASE1  = "#{$FS_ROOT}/phase1.log"
    $FS_PHASE2  = "#{$FS_ROOT}/phase2.log"
    $FS_PHASE3  = "#{$FS_ROOT}/phase3.log"

    # make sure configuration folder exists
    if not File.exist?($FS_ROOT) then
        Dir.mkdir($FS_ROOT)
    elsif not Dir.exist?($FS_ROOT) then
        puts "ERROR: #{$FS_ROOT} already exists as a regular file"
        exit
    end # }}}

    # {{{ setup 1: generate acquisition script
    if not File.exist?($FS_ACQUIRE) then
        if not $FS_BATCHMODE then
            puts "How would you like to acquire a copy of your code?"
            puts "  a) Recursive copy from a local folder"
            puts "  b) Clone a git repository"
        end
        opt = input_option("Choose an option above: ", "ab", "a")
        case opt
        when "a"
            path = input_path("Enter project root path: ", ".", true)
            cmd = "cp -rL #{File.absolute_path(path)}/* ."
        when "b"
            print "Enter repository URL: "
            cmd = "git clone #{STDIN.gets.chomp} ."
        end
        File.open($FS_ACQUIRE, 'w') do |f|
            f.puts "#!/usr/bin/env bash"
            f.puts cmd
        end
        File.chmod(0700, $FS_ACQUIRE)
        puts "Acquisition script created: #{$FS_ACQUIRE}"
        puts ""
    end
    # }}}
    # {{{ setup 2: generate build script
    if not File.exist?($FS_BUILD) then
        if not $FS_BATCHMODE then
            puts "How is your project built? (your build system must use CXX)"
            puts "  a) \"make\""
            puts "  b) \"./configure && make\""
            puts "  c) \"cmake .\""
            puts "  d) Custom script"
        end
        opt = input_option("Choose an option above: ", "abcd", "a")
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
            line = STDIN.gets.chomp
            while line != ""
                script << line
                line = STDIN.gets.chomp
            end
        end
        File.open($FS_BUILD, 'w') do |f|
            f.puts "#!/usr/bin/env bash"
            script.each { |line| f.puts line }
        end
        File.chmod(0700, $FS_BUILD)
        puts "Build script created: #{$FS_BUILD}"
        puts ""
    end
    # }}}
    # {{{ setup 3: generate run script
    if not File.exist?($FS_RUN) then
        if ARGV.include?("--run") then
            script = [ ARGV[ARGV.find_index("--run")+1] ]
        else
            puts "Enter command(s) to run your program with representative input."
            puts "Enter an empty line to finish."
            puts ""
            script = []
            line = STDIN.gets.chomp
            while line != ""
                script << line
                line = STDIN.gets.chomp
            end
        end
        File.open($FS_RUN, 'w') do |f|
            f.puts "#!/usr/bin/env bash"
            f.puts "rm -f stdout"
            script.each { |line| f.puts line+" | tee -a stdout" }
        end
        File.chmod(0700, $FS_RUN)
        puts "Run script created: #{$FS_RUN}"
        puts ""
    end
    # }}}
    # {{{ setup 4: generate verification script
    if not File.exist?($FS_VERIFY) then
        if not $FS_BATCHMODE then
            puts "How should the output be verified?"
            puts "  a) Exact match with original (stdout)"
            puts "  b) Contains a line matching a regex (stdout)"
            puts "  c) Contains no lines matching a regex (stdout)"
            puts "  d) Ensure all floats in output are within an Epsilon (stdout)"
            puts "  e) Custom script"
        end
        script = []
        regex = nil
        if ARGV.include?("--verify-regex") then
            opt = "b"
            regex = ARGV[ARGV.find_index("--verify-regex")+1]
        elsif ARGV.include?("--verify-script") then
            opt = "e"
            fn = ARGV[ARGV.find_index("--verify-script")+1].gsub(/\A"|"\Z/, '')
            script = IO.readlines(fn)
        else
            opt = input_option("Choose an option above: ", "abcde", "a")
        end
        case opt
        when "a"
            puts "Running original program to generate verification output."
            FileUtils.rm_rf $FS_BASE
            Dir.mkdir $FS_BASE
            Dir.chdir $FS_BASE
            exec_cmd($FS_ACQUIRE, false)
            exec_cmd($FS_BUILD, false)
            exec_cmd($FS_RUN, false)
            script << "outdiff=$(diff stdout #{$FS_BASE}/stdout)"
            script << "if [ -z \"$outdiff\" ]; then"
            script << "    echo \"status:  pass\""
            script << "else"
            script << "    echo \"status:  fail\""
            script << "fi"
        when "b"
            if regex.nil? then
                puts "Enter regex: "
                regex = STDIN.gets.chomp
            end
            script << "search=$(grep -E '#{regex}' stdout)"
            script << "if [ -z \"$search\" ]; then"
            script << "    echo \"status:  fail\""
            script << "else"
            script << "    echo \"status:  pass\""
            script << "fi"
        when "c"
            puts "Enter regex: "
            regex = STDIN.gets.chomp
            script << "search=$(grep -E '#{regex}' stdout)"
            script << "if [ -z \"$search\" ]; then"
            script << "    echo \"status:  pass\""
            script << "else"
            script << "    echo \"status:  fail\""
            script << "fi"
        when "d"
            FileUtils.rm_rf $FS_BASE
            Dir.mkdir $FS_BASE
            Dir.chdir $FS_BASE
            exec_cmd($FS_ACQUIRE, false)
            exec_cmd($FS_BUILD, false)
            exec_cmd($FS_RUN, false)
            puts "Enter Epsilon: "
            epsilon = STDIN.gets.chomp
            puts "Enter \"r\" for relative error or \"a\" for absolute error:"
            error_type = STDIN.gets.chomp
            script << "#{__dir__}/find_floats.rb -q -#{error_type} #{$FS_BASE}/stdout stdout #{epsilon}"
        when "e"
            if script.size == 0 then
                puts "Enter Bash code to verify your program output:"
                puts "(standard output will be in a file called stdout; empty line to finish)"
                script = []
                line = STDIN.gets.chomp
                while line != ""
                    script << line
                    line = STDIN.gets.chomp
                end
            end
        end
        File.open($FS_VERIFY, 'w') do |f|
            f.puts "#!/usr/bin/env bash"
            script.each { |line| f.puts line }
        end
        File.chmod(0700, $FS_VERIFY)
        puts "Verify script created: #{$FS_VERIFY}"
        puts ""
    end # }}}

    # {{{ intermission: run sanity check
    if not File.exist?("#{$FS_SANITY}/.FS_DONE") then
        puts "Running sanity check on generated scripts."
        FileUtils.rm_rf $FS_SANITY
        Dir.mkdir $FS_SANITY
        Dir.chdir $FS_SANITY
        exec_cmd $FS_ACQUIRE
        exec_cmd $FS_BUILD
        exec_cmd $FS_RUN
        exec_cmd $FS_VERIFY
        exec_cmd "touch #{$FS_SANITY}/.FS_DONE"
        puts ""
    end # }}}

    # {{{ phase 1a: variable discovery
    if not File.exist?($FS_TFVARS) then

        # setup new build w/ hard-coded TypeForge plugin
        puts "Finding variables to be tuned."
        FileUtils.rm_rf($FS_INITIAL)
        Dir.mkdir $FS_INITIAL
        Dir.chdir $FS_INITIAL
        script = []
        script << "{ \"version\": \"1\","
        script << "  \"tool_id\": \"FloatSmith\","
        script << "  \"actions\": ["
        script << "    { \"action\": \"list_changes_basetype\","
        script << "      \"scope\": \"\","
        script << "      \"from_type\": \"double\","
        script << "      \"to_type\": \"float\""
        script << "    } ] }"
        File.open("#{$FS_INITIAL}/initial.json", "w") do |f|
            script.each { |line| f.puts line }
        end
        exec_cmd $FS_ACQUIRE

        # create phase reproducibility script and run it
        File.open("#{$FS_INITIAL}/run.sh", "w") do |f|
          script << "      \"name\": \"#{$FS_TFVARS}\","
            f.puts "export CC='typeforge --plugin initial.json --typeforge-out #{$FS_TFVARS} --compile'"
            f.puts "export CXX='typeforge --plugin initial.json --typeforge-out #{$FS_TFVARS} --compile'"
            f.puts "#{$FS_BUILD}"
        end
        File.chmod(0700, "#{$FS_INITIAL}/run.sh")
        exec_cmd("#{$FS_INITIAL}/run.sh", true, true, false, $FS_PHASE1)
        puts "Variables discovered: #{$FS_TFVARS}"
        puts ""
    end

    # verify that TypeForge found at least one variable
    cfg = JSON.parse(IO.read($FS_TFVARS))
    if not cfg.has_key?("actions") or cfg["actions"].size == 0 then
        puts "TypeForge did not find any variables to tune."
        puts "Aborting search."
        exit
    end
    # }}}
    # {{{ phase 1b: variable review (optional)
    if not File.exist?($FS_INITCFG) then
        if not $FS_BATCHMODE then
            puts "Some variables may not be appropriate candidates for tuning (e.g., if they"
            puts "are used for calculating error). You may wish to remove them from the list."
        end
        cfg = JSON.parse(IO.read($FS_TFVARS))
        ids = []
        if ARGV.include?("--ignore") then
            names = ARGV[ARGV.find_index("--ignore")+1].split(" ")
            cfg["actions"].each_index do |i|
                # check only last element of fully-qualified name (e.g., "sum" instead of "::main::sum")
                ids << i if names.include?(cfg["actions"][i]["name"].split("::")[-1])
            end
        else
            if input_boolean("Do you wish to review/edit the list of variables?", false) then
                cfg["actions"].each_index do |i|
                    a = cfg["actions"][i]
                    puts "  #{i}) #{a["name"]} (#{a["scope"]}) [#{a["source_info"].gsub(/.*\//, "")}]"
                end
                puts "Enter ID numbers for any variables you wish to remove, separate by spaces:"
                ids = STDIN.gets.split(" ").map { |x| x.to_i }
            end
        end
        puts "Ignoring #{ids.size} variables." if ids.size > 0
        new_actions = []
        cfg["actions"].each_index do |i|
            new_actions << cfg["actions"][i] if not ids.include?(i)
        end
        cfg["actions"] = new_actions
        IO.write($FS_INITCFG, JSON.pretty_generate(cfg))
        puts "Initial configuration created: #{$FS_INITCFG}"
        puts ""
    end
    # }}}
    # {{{ phase 2: ADAPT instrumentation (optional)
    if not Dir.exist?($FS_ADRUN) then
        if not $FS_BATCHMODE then
            puts "If you wish, now we can run your program with ADAPT"
            puts "instrumentation. This will most likely cause the search to"
            puts "converge faster, but your program must be compilable using"
            puts "'-std=c++11' and you must have included all of the appropriate"
            puts "pragmas (see documentation)."
        end
        run_adapt = ARGV.include?("--adapt")
        if not run_adapt then
            run_adapt = input_boolean("Do you wish to run ADAPT?", false)
        end
        if run_adapt then
            puts "Instrumenting and running with ADAPT."

            # setup ADAPT run w/ hard-coded TypeForge plugin
            Dir.mkdir $FS_ADRUN
            Dir.chdir $FS_ADRUN
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
            File.open("#{$FS_ADRUN}/instrument.json", "w") do |f|
                script.each { |line| f.puts line }
            end
            exec_cmd $FS_ACQUIRE

            # create phase reproducibility script and run it
            File.open("#{$FS_ADRUN}/run.sh", "w") do |f|
                f.puts "export CXX=\"typeforge --plugin instrument.json --compile" +
                       " -std=c++11 -I${CODIPACK_HOME}/include -I${ADAPT_HOME}" +
                       " -DCODI_EnableImplicitConversion -DCODI_DisableImplicitConversionWarning" +
                       " -DCODI_ZeroAdjointReverse=0\""
                f.puts "#{$FS_BUILD}"
                f.puts "#{$FS_RUN}"
                f.puts "cp adapt_recommend.json #{$FS_ADOUT}"
            end
            File.chmod(0700, "#{$FS_ADRUN}/run.sh")
            exec_cmd("#{$FS_ADRUN}/run.sh", true, true, false, $FS_PHASE2)

            # see if ADAPT generated the expected output file
            if File.exist?($FS_ADOUT) then
                puts "AD instrumentation results created: #{$FS_ADOUT}"
            else
                puts "AD instrumentation results were NOT created!"
            end
            puts ""
        end
    end
    # }}}
    # {{{ phase 3: mixed-precision search
    if Dir.exist?($FS_SEARCH) then
        run_search = input_boolean("There are existing (possibly incomplete) search results.\n" +
                                   "Do you wish to erase them and run again?", true)
    else
        run_search = true
    end
    if run_search then
        FileUtils.rm_rf $FS_SEARCH
        Dir.mkdir $FS_SEARCH if not Dir.exist?($FS_SEARCH)
        Dir.chdir $FS_SEARCH

        # set up craft_builder and craft_driver scripts needed by CRAFT
        File.open("#{$FS_SEARCH}/craft_builder", "w") do |f|
            f.puts IO.read($FS_ACQUIRE)
            f.puts "export CC=\"typeforge --plugin $1 --compile\""
            f.puts "export CXX=\"typeforge --plugin $1 --compile\""
            f.puts IO.read($FS_BUILD)
            f.puts "typeforge --cast-stats rose_*"
        end
        File.chmod(0700, "#{$FS_SEARCH}/craft_builder")
        File.open("#{$FS_SEARCH}/craft_driver", "w") do |f|
            f.puts "#!/usr/bin/env bash"
            f.puts "t_start=$(date +%s.%3N)"
            f.puts IO.read($FS_RUN)
            f.puts "t_stop=$(date +%s.%3N)"
            f.puts "echo \"time:    $(echo \"$t_stop - $t_start\" | bc)\""
            f.puts IO.read($FS_VERIFY)
            # TODO: handle 'error' output
        end
        File.chmod(0700, "#{$FS_SEARCH}/craft_driver")

        # determine CRAFT search parameters and build invocation string (cmd)
        cmd = "craft search -V -c #{$FS_INITCFG}"
        if File.exist?($FS_ADOUT) then
            cmd += " -A #{$FS_ADOUT}"
        end
        if ARGV.include?("-s") then
            cmd += " -s #{ARGV[ARGV.find_index("-s")+1]}"
        else
            if not $FS_BATCHMODE then
                puts "CRAFT supports several search strategies:"
                puts "  a) Compositional - try individuals then try to compose passing configurations"
                puts "  b) Delta debugging - binary search on the list of variables"
                puts "  c) Combinational - try all combinations (very expensive!)"
                puts "  d) Hierarchical - breadth-first search on program structure to find passing configurations"
                puts "  e) Hierarchical + Compositional"
            end
            opt = input_option("Which strategy do you wish to use for the search? ", "abcde", "a")
            cmd += " -s compositional" if opt == "a"
            cmd += " -s ddebug"        if opt == "b"
            cmd += " -s combinational" if opt == "c"
            cmd += " -s simple"        if opt == "d"
            cmd += " -s comp_simple"   if opt == "e"
        end
        if ARGV.include?("-t") then
            cmd += " -t #{ARGV[ARGV.find_index("-t")+1]}"
        else
            ntrials = input_integer("How many trials of each configuration do you want to run?", "10")
            cmd += " -t #{ntrials}" if ntrials.to_i > 1
        end
        if ARGV.include?("-T") then
            cmd += " -T #{ARGV[ARGV.find_index("-T")+1]}"
        end
        if ARGV.include?("-J") then
            cmd += " -J #{ARGV[ARGV.find_index("-J")+1]}"
        else
            if not $FS_BATCHMODE then
                puts "If you have a cluster with the SLURM job manager installed, CRAFT can submit"
                puts "configuration runs as jobs using the 'sbatch' command instead of running them locally."
            end
            slurm = input_boolean("Do you wish to submit configuration runs using 'sbatch'?", false)
            cmd += " -J slurm -j -1" if slurm
        end
        if ARGV.include?("-j") then
            cmd += " -j #{ARGV[ARGV.find_index("-j")+1]}"
        elsif not slurm then
            cpus = exec_cmd("cat /proc/cpuinfo | grep processor | wc -l", false, false, true).chomp
            nworkers = input_integer("How many configurations should be run simultaneously?", "#{cpus}")
            cmd += " -j #{nworkers}" if nworkers.to_i > 1
        end
        if not $FS_BATCHMODE then
            puts "TypeForge reports 'sets' of variables that should only be converted together, and"
            puts "CRAFT can automatically use this information to test fewer configurations if possible."
        end
        if ARGV.include?("-g") then
            cmd += " -g #{ARGV[ARGV.find_index("-g")+1]}"
            if ARGV.include?("-M") then
                cmd += " -M"
            end
        else
            use_clustering = input_boolean("Do you wish to use typechain clustering to test fewer configurations?", false)
            cmd += " -g typechain:cluster" if use_clustering
        end
        if ARGV.include?("-C") then
            cmd += " #{ARGV[ARGV.find_index("-C")+1]}"
        end

        # create phase reproducibility script and run it
        File.open("#{$FS_SEARCH}/run.sh", "w") do |f|
            f.puts "#!/usr/bin/env bash"
            f.puts cmd
        end
        File.chmod(0700, "#{$FS_SEARCH}/run.sh")
        exec_cmd("#{$FS_SEARCH}/run.sh", true, true, false, $FS_PHASE3)

        # clean up final configuration folder
        fdir = "#{$FS_SEARCH}/final"
        if File.exists?(fdir) then

            # delete anything that's not a Rose output file
            # (and save those in a lookup table for later)
            rose_files = {}
            Dir.foreach(fdir) do |fn|
                if fn =~ /^rose_(.*)$/ then
                    rose_files[fn] = $1
                elsif not (fn == "." or fn == "..")
                    FileUtils.rm_rf("#{fdir}/#{fn}")
                end
            end

            # re-acquire the project
            Dir.chdir(fdir)
            exec_cmd $FS_ACQUIRE

            # replace the old source files with the new ones
            rose_files.each do |src,dest|
                FileUtils.mv("#{fdir}/#{src}", "#{fdir}/#{dest}")
            end
        end

        # print final output
        puts "Search results are located in #{$FS_SEARCH}"
        puts "If found, the recommended configuration is located in #{$FS_SEARCH}/final"
        puts ""
    end
    # }}}

    puts "== FloatSmith complete =="
end

run_driver

