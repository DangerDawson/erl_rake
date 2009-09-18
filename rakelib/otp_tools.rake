# -*-ruby-*-
# Copyright 2009 Nicolas Charpentier
# Distributed under BSD licence
namespace :otp do

  
  directory "bin"
  directory "log"
  directory "pipes"

  require 'rake/clean'

  CLEAN.include "bin"
  CLEAN.include "log"
  CLEAN.include "pipes"

  file 'bin/connect_local' do
    File.open("bin/connect_local",'w') do |file|
      file.write("#!/bin/sh \n")
      file.write("#{ERL_TOP}/bin/to_erl pipes/ \n")
      file.chmod(0755)
    end
  end

  file 'bin/start_local' do
    File.open("bin/start_local",'w') do |file|
      lines = ["# $1 = boot file to use",
               "# $2 = config_file to use",
               "# $3 = -daemon or nothing",
               "#!/bin/sh ",
               "ROOTDIR=#{ERL_TOP}",
               "boot=$1",
               "shift",
               "config=$1",
               "shift",
               "daemon=$1",
               "shift",
               "$ROOTDIR/bin/run_erl $daemon pipes/ log/ \"exec bin/start_erl_local"\
               " #{ERL_TOP} $boot $config $*\""]
      lines.each do |line|
        file.write(line)
        file.write("\n")
      end
      file.chmod(0755)
    end
  end

  file 'bin/start_erl_local' do
    File.open("bin/start_erl_local",'w') do |file|
      erts = FileList.new("#{ERL_TOP}/erts-*")
      lines = ["ROOTDIR=$1",
               "RELDIR=$1",
               "BINDIR=#{erts}/bin",
               "EMU=beam",
               "PROGNAME=`echo $0`",
               "export EMU",
               "export ROOTDIR",
               "export BINDIR",
               "export PROGNAME",
               "export RELDIR",
               "shift",
               "boot=$1",
               "shift",
               "config=$1",
               "shift",
               "exec $BINDIR/erlexec -boot $boot -config $config $*"]
      lines.each do |line|
        file.write(line)
        file.write("\n")
      end
      file.chmod(0755)
    end
  end

  desc "Start a erlang system from a local release"
  task :start_local, :name, :daemon, :needs => ["bin", "log", "pipes",
                                                "bin/connect_local",
                                                "bin/start_local",
                                                "bin/start_erl_local"] do |t, args|
    
    opt = if args.daemon 
            "\"-daemon\""
          else
            "\" \""
          end
    rel = ERL_RELEASE_FILES.include("#{args.name}-*.rel").first
    puts rel
    
    boot = rel.ext("").pathmap("release_local/%f")
    conf = rel.pathmap("%d/../release_config/sys")
    sh "bin/start_local #{boot} #{conf} #{opt} #{ERL_FLAGS}"
  end

  desc "Create a new OTP application"
  task :new_application, :name do |t, args|
    app_name = args.name
    root_directory = "lib/#{app_name}"
    app_file_name = app_name + ".app.src"
    rel_file_name = app_name + ".rel.src"
    mkdir root_directory
    mkdir root_directory + "/src"
    mkdir root_directory + "/test"
    mkdir root_directory + "/include"
    mkdir root_directory + "/priv"
    mkdir root_directory + "/doc"
    mkdir root_directory + "/release_config"
    File.open(root_directory + "/vsn.config", 'w') do |file| 
      file.write("{vsn,\"0.1\"}.\n")
      file.write("{release_name,\"initial\"}.\n")
    end
  
    File.open(root_directory + "/src/" + app_file_name, 'w') do |file|
      lines = ["{application, " + app_name + ",\n",
               "[{description, \"\"},\n",
               "{author, \"\"},\n",
               "{vsn, %VSN%},\n",
               "{modules, [%MODULES%]},\n",
               "{registered, []},\n",
               "{applications, [kernel, stdlib, sasl]}\n",
               "]}."]
      lines.each do |line|
        file.write(line)
      end
    end

    File.open(root_directory + "/src/" + rel_file_name, 'w') do |file|
      lines = ["{release,\n",
        "{\"#{app_name}\", \"\"},\n",
        "{erts, \"_\"},\n",
        "[{kernel, \"_\"},\n",
        "{stdlib, \"_\"},\n",
        "{sasl, \"_\"},\n",
        "{mnesia, \"_\"},\n",
        "{#{app_name}, \"_\"}]\n",
        "}.\n" ]
      lines.each do |line|
        file.write(line)
      end
    end

    # Create some deafult startup scripts
    File.open(root_directory + "/release_config/startup.conf", 'w') do |file| 
      file.write("ERL_FLAGS=\"-pa patches +K true -sname #{app_name} -smp auto\"\n")
      file.write("export ERL_FLAGS\n")
    end
    File.open(root_directory + "/release_config/sys.config", 'w') do |file| 
      file.write("[].")
    end

  end

  CLEAN.include('tmp')
  CLEAN.include('targets')
  
  desc "Build an initial empty target system"
  task :initial_target, :name, :version, :needs => ["erlang:releases"] do |t,args|
    release_name = FileList.new("lib/*/ebin/"+File.join(args.name+'-'+args.version+'.rel'))
    release_archive = File.join('tmp',args.name+'-'+args.version+'.tar.gz')
    
    if release_name.empty? or !File.file?(release_name[0])
      puts "The release #{args.name}-#{args.version} doesn't exist"
      exit(-1)
    end

    FileUtils.makedirs('tmp')
    FileUtils.makedirs('targets')
    run_script("make_target", [release_name.ext(""),"tmp","targets",ERL_TOP] +
               ERL_DIRECTORIES)
    
  FileUtils.rm_r('tmp')
  end
end
