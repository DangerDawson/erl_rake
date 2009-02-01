# -*-ruby-*-
# Copyright 2009 Nicolas Charpentier
# Distributed under BSD licence
namespace :otp do

  
  desc "Start a erlang system from a local release"
  task :start_local, :name do |t, args|
    sh "#{ERL_TOP}/bin/erl #{ERL_FLAGS} -boot release_local/#{args.name}/start"
  end

  desc "Create a new OTP application"
  task :new_application, :name do |t, args|
    root_directory = "lib/#{args.name}"
    app_file_name = args.name + ".app.src"
    mkdir root_directory
    mkdir root_directory + "/src"
    mkdir root_directory + "/test"
    mkdir root_directory + "/include"
    mkdir root_directory + "/priv"
    mkdir root_directory + "/doc"
    File.open(root_directory + "/vsn.config", 'w') do |file| 
      file.write("{vsn,\"0.1\"}.")
    end
  
    File.open(root_directory + "/src/" + app_file_name, 'w') do |file|
      lines = ["{application, " + args.name + ",\n",
               "[{description, \"\"},\n",
               "{author, \"\"},\n",
               "{vsn, %VSN%},\n",
               "{modules, %MODULES%},\n",
               "{registered, []},\n",
               "{applications, [kernel, stdlib, sasl]}\n",
               "]}."]
      lines.each do |line|
        file.write(line)
      end
    end
  end

  CLEAN.include('tmp')
  CLEAN.include('targets')
  
  desc "Build an initial empty target system"
  task :initial_target, :name, :version, :needs => ["erlang:releases"] do |t,args|
    release_name = FileList.new("lib/*/ebin/"+File.join(args.name+'-'+args.version+'.rel'))
    release_archive = File.join('tmp',args.name+'-'+args.version+'.tar.gz')
    
    if not File.file?(release_name[0])
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
