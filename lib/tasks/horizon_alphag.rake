require 'net/http'
require 'nokogiri'

namespace :horizon_alphag do

  desc "Mass index from Horizon, with replication"
  task "mass_index" do
    solr_master = replicate_master_url
    if solr_master.nil?
      puts "This task requires replicate_master_url set in solr.yml / #{Rails.env}, not found."
      exit 1
    end
    
    
    # Make a lock file. This task will run a long time, we don't want to
    # run it twice overlapping. We also want to capture the start time for
    # later deleting records older than start time, in a safe way, so we
    # have it for manual recovery even if we crash. 
    #
    # important we keep lockfile in tmp/pids, a directory that capistrano
    # keeps in shared -- if it's just in a capistrano single app releases
    # directory, it won't be noticed for collisions! 
    lockfile = File.join(Rails.root, "tmp", "pids", "horizon_mass_index.pid")
    if File.exist?(lockfile)
      puts "Lock file exists, is another process running? Manually delete if you know what you're doing: #{lockfile}"
      exit 1
    end    
    start_time = Time.now
    
    puts "Registered start time: #{start_time}  (#{start_time.utc.iso8601})"
    
    
    File.open(lockfile, "w") do |f|
      f.write( {'pid' => Process.pid, 'start_time' => start_time}.to_yaml )
    end
    
    #Delete the lockfile even if we die weirdly
    at_exit do
      if File.exists?( lockfile )
        File.delete(lockfile)
        puts "Lock file still existed at exit, exit abnormal? Removed #{lockfile}"
      end
    end
    
    # Mass index to replication master 
    puts
    puts "Running horizon:export_to_index to master"    
    Rake::Task["horizon:export_to_index"].invoke    
    puts "Done importing all horizon to master #{Time.now}"
    
    # Now delete any records OLDER than when we started from
    # source=horizon, cause if the record wasn't replaced with a newer
    # one, that means it's been deleted from horizon.
    puts
    puts "Deleting old records prior to our current import"
    dq = "<delete><query>source:horizon AND timestamp:[* TO #{start_time.utc.iso8601}]</query></delete>"
    get_and_print("#{solr_master}/update?stream.body=#{CGI.escape(dq)}"  )
    get_and_print(solr_master + "/update?stream.body=%3Ccommit/%3E")
    puts "Done deleting old records at #{Time.now}"
    

    # And optimize the master guy please
    get_and_print( solr_master + "/update?stream.body=%3Coptimize/%3E" )
    puts "Done optimizing master at #{Time.now}"
    
    
    # Sanity check, if master doens't have at least ENV["SANITY_CHECK_COUNT"]
    # records, abort abort abort! (default two million)
    puts   
    sanity_check_count = (ENV["SANITY_CHECK_COUNT"] || 2000000).to_i
    puts "Sanity check, won't replicate unless at least #{sanity_check_count} records in master..."
    # q=*:* encoded
    response = get_and_print("#{solr_master}/select?defType=lucene&q=%2A%3A%2A&rows=0&facet=false")    
    xml = Nokogiri::XML response.body if response.kind_of?(Net::HTTPOK)
    if xml && (count = xml.at_xpath("//result/@numFound").to_s.to_i) && count >= sanity_check_count
      puts "...Passed!"
    else
      puts "....FAILED!! #{count}"
      exit(1)
    end    
   
    

    # And replicate it to slave!
    puts
    puts "Replicating master to slave"
    Rake::Task["solr:replicate"].invoke
    puts "Done sending replicate command at #{Time.now}. (Replication itself may still be ongoing)"
    
    
    # Delete lockfile, and we're done
    File.delete(lockfile)
    
    puts "Done at #{Time.now}"
  end
    
  
  desc "Export from Horizon to file"
  task :export do  
    timestamp = now_timestamp

    logfile = hzn_export_logfile(timestamp)
    
    command_line = hzn_export_command_line(:timestamp => timestamp, :output_file => (ENV['OUTPUT'] || :auto), :logfile => logfile)
    puts "Executing:\n#{command_line.sub(/--dbPassword [^ ]+/, '--dbPassword ******')}"
    puts
    system( command_line )

    # look for errors in the log

    errors = hznexportmarc_log_errors( logfile )
    if errors.length > 0
      puts
      puts "Errors discoverd: #{logfile} "
      puts
      puts errors.split("\n")
      exit(1)
    end

    puts "Deleting log, no errors detected"
    FileUtils.rm( logfile )
  end  
  namespace :export do
    desc "usage info for horizon:export"
    task :info do
      puts
      puts "Call this task with arguments to show exactly what java command line would be executed, without executing it:\n\n"
      puts "Would execute:\n#{hzn_export_command_line(:output_file => (ENV['OUTPUT'] || :auto))}\n"
      puts
      puts "If called with bib restricting options, all public bibs from db are included."
      puts
      puts "OPTIONS:"
      puts
      puts "OUTPUT => file path to output marc to. If left blank, will use a timestamped default name in rails app home directory."
      puts
      puts "FIRST =>  min bib num to start with"
      puts
      puts "LAST => max bib num to end with"
      puts
      puts "CONDITIONS => string sql WHERE clause to apply to bib table to define bibs to include for export."
      puts
      puts "EXPORT_DEBUG => true ;  include debugging information from Horizon Marc Exporter in log"
      puts
      puts "FROM => environment ; pull from a Horizon in specified environment rather than current Rails.env.  For export_to_index, the solr the changes are pushed to will still be Rails.env"
    end
  end

  desc "pipe straight from exporter to SolrMarc, no marc file on disk"
  task :export_to_index do
    # Really cheesy way to use individual methods defined in the solr_marc rake task,
    # to pipe to solr_marc. Probably ought to extract them into an actual class
    # instead.
    load File.join(Blacklight.root, "lib/railties/solr_marc.rake")

    # solrmarc spews stderr with it's log, save that in a log file
    # instead.
    timestamp = now_timestamp
    solr_marc_log = File.join(Rails.root, "log", "solrmarc-#{timestamp}.log")
    
    
    # Use #solrmarc_command_line and #compute_arguments from BL solr tasks, 
    # but look up the replicate_master_url from solr.yml ourselves as where
    # to index to, because we want to index to our master, not the slave.
    
    our_solrmarc_args = compute_arguments
    our_solrmarc_args.merge!(:solr_url => replicate_master_url)  if replicate_master_url
    
    
    complete_command = "#{hzn_export_command_line(:timestamp => timestamp)} | #{solrmarc_command_line(our_solrmarc_args)} 2>#{solr_marc_log}"
    
    puts "Executing:\n#{complete_command.sub(/--dbPassword [^ ]+/, '--dbPassword ******')}\n\n"
    system(complete_command)

    #check for errors in log files
    export_errors = hznexportmarc_log_errors(hzn_export_logfile(timestamp))
    if export_errors.length > 0
      puts
      puts "HznExport Errors: #{hzn_export_logfile(timestamp)}"
      puts
      puts export_errors.join("\n")
    else
      puts "Deleting HznExport log file, no errors discovered."
      FileUtils.rm( hzn_export_logfile(timestamp) )
    end
    
    solrmarc_errors = solrmarc_log_errors(solr_marc_log)
    if solrmarc_errors.length > 0
      puts
      puts "SolrMarc Errors: #{solr_marc_log}"
      puts
      puts solrmarc_errors.join("\n")
    else
      puts "Deleting SolrMarc log file, no errors discovered."
      FileUtils.rm( solr_marc_log )
    end
    if solrmarc_errors.length > 0 or export_errors.length > 0
      puts
      puts "EXITING rake task, subsequent tasks in pipeline like replication may not have occured."      
      exit(1)
    end
  end
  

end

# args:
# [:timestamp]  pass in a timestamp to use for creating filenames.
#               Can be useful for ensuring consistent timestamps with files created elsewhere.
# [:output_file]  string file path to write marc to. Or :auto to create one based on timestamp. Leave blank to write to stdout. 
def hzn_export_command_line(args = {})
  args[:timestamp] ||= now_timestamp
  args[:output_file] = "hzn_export_marc-#{args[:timestamp]}.mrc" if args[:output_file] == :auto
  args[:log_file] ||= 
  
  log_file = hzn_export_logfile(args[:timestamp])
  
  str = ""
  str << "java -classpath #{classpath} alphagconsulting.apps.marc.HznExportMarc"
  str << " --tolerant "  
  str << " --dbHost #{horizon_connection["host"]} --dbPort #{horizon_connection["port"]} --dbName #{horizon_connection["db_name"]}  --dbLogin #{horizon_connection["login"]} --dbPassword #{horizon_connection["password"]} --dbSrvrType #{horizon_connection["jdbcType"]} "

  # our records sometimes have LOTS of 998/999's taking up space; these are
  # item information, but they aren't up to date, and should probably be
  # deleted from the db, but in the meantime omit them from our output.
  # We also omit any 991 or 937, since we use that for our own dynamically
  # added item/copy info. 
  str << ' --bibConditions "tag NOT IN (\'998\', \'999\', \'991\',\'937\') "'

  str << " --bibMode PUBLIC --copyMode PUBLIC --itemMode PUBLIC "
  str << " --itemCopyMode DIRECT_ONLY " # currently errors, asked John for advice.  
  #str << " --holdSum true " # this is really slow, leaving off for now 
  str << " --nonMARCconfig itemData "

  
  str << " --testMode " if ENV['EXPORT_DEBUG']

  if args[:output_file]
    str << " --marcFile #{args[:output_file]} "
  end
  
  str << " --logFile #{log_file} "

  str << " --firstBib #{ENV['FIRST']} " if ENV['FIRST']
  str << " --lastBib #{ENV['LAST']} " if ENV['LAST']
  str << " --bibNums CONDITIONS --bibSpec \"#{ENV['CONDITIONS']}\"" if ENV['CONDITIONS']
  
  return str
end

def now_timestamp
  Time.now.strftime("%d%b%Y-%H%M")
end

def hzn_export_logfile(timestamp)
  File.join(Rails.root, "log", "HznExportMarc-#{timestamp}.log")
end

def classpath
  base_dir = File.join(Rails.root, "HznExportMarc")
  [ File.join(base_dir, "HznExportMarc.jar"),
    File.join(base_dir, "lib", "jopt-simple-3.2.jar"),
    File.join(base_dir, "lib", "jTDS.jar"),
    File.join(base_dir, "lib", "lib/Marc4j.jar")

  ].join(":")
end


def horizon_connection
  @horizon_connection ||= begin
    horizon_yml_path = File.join(Rails.root, "config", "horizon.yml")
    hash = YAML::load(File.open(horizon_yml_path))    
    hash[ENV['FROM'] || Rails.env]
  end
end

# Returns array of error lines to report.
# Side-effect: stores lines indicating bad marc tag values in instance variable
# @bad_tag_numbers. 
def hznexportmarc_log_errors(logfile)
  errors = []
  bad_tag_numbers = []
  
  line_num = 0;
  record_line = nil
  File.open(logfile) do |io|
    io.each do |line|
      line_num += 1
      # Track "invalid tag number" errors seperately, we have a LOT of them
      # but the records are exported anyway, they are 'expected' errors at
      # the moment.
      #if line =~ /^invalid tag number/
      #  bad_tag_numbers << line
      # Actual unexpected errors. 
      if line !~ /^((rec\# \:)|(Exported)|(^$))/
        if record_line
          errors << record_line
          record_line = nil
        end
        errors << "Line #{line_num}: #{line}"       
      end
      record_line = line if line =~ /^rec\# \:/
    end
  end

  return errors
end

def solrmarc_log_errors(logfile)
  errors = []
  last_bib_num = nil
  File.open(logfile) do |io|
    io.each do |line|
      if line =~ /error/i
        errors << "Last bib number encountered: #{last_bib_num}" if last_bib_num
        errors << line if line =~ /error/i
        bib_num = nil
      end

      if line =~ /Added record \d+ read from file: (\d+)/
        last_bib_num = $1
      end
      
    end
  end
  return errors
end
