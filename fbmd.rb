require 'rest-client'


#Defining all the constants used here, quite a few
#Regexp objects as well as strings

TERM_STR = '&#064;facebook.com'
TARG_STR = 'www.facebook.com/'
HTML_REGEX_NAME = /(?<pre>\"Person\",\"name\":\")(?<inner>[\w\s]*)(?<post>\",\")/
MSG_REGEX_BODY = /(?<pre><p>)(?<inner>.*)(?<post><\/p>)/
MSG_REGEX_SNDR = /(?<pre><span class="user">)(?<inner>[\w\s\d&#;.]*)(?<post><\/span>)/
MSG_REGEX_DATETIME = /(?<pre><span class="meta">)(?<inner>[\w\s\d,:+-]*)(?<post><\/span>)/
XML_REGEX_PUNCT_CAPTURE = /&(#039|quot);/     #add more as I find them...
XML_REGEX_PUNCT_REPLACE = {'&#039;' => "'", '&quot;' => '"'}


#FMmsgdata object holds the data and acts as an interface
class FBmsgdata
  class FBmsg
    def initialize(xmlmsg)
      @message = xmlmsg[MSG_REGEX_BODY, "inner"]
      @message.gsub!(XML_REGEX_PUNCT_CAPTURE, XML_REGEX_PUNCT_REPLACE) unless @message == nil
      @sender = xmlmsg[MSG_REGEX_SNDR, "inner"]   #rip resolved names from the hash table at print time
      dt = xmlmsg[MSG_REGEX_DATETIME, "inner"].split(" at ")
      @date = dt[0]
      @time = dt[1]
    end

    def msg
      @message end
    def sender
      @sender end
    def date
      @date end
    def time
      @time end
  end



  def initialize(file_path, request_resolve = false)
      STDERR.print 'Initializing... '
      @data = Array.new()
      @id_names = Hash.new()
      @threads_parsed = Hash.new()
      File.read(file_path).split('<div class="thread">').each_with_index do |thread, index|
        @data[index] = thread.split('<div class="message">')
      end
      @preamble = @data[0]  #could shift this out, but it makes thread number and index
                            #the same if I leave it in
      parse_names(request_resolve)
      #parse_messages()
      warn "Ready."
  end

  def resolve_name(id)
    #add in capabilities to grab a cookie to use for private facebooks, add error handling
    return RestClient.get(TARG_STR + id).body[HTML_REGEX_NAME, "inner"]
  end

  private :resolve_name



  def parse_names(request_resolve = false)
    for i in 1..@data.size - 1 do
      @data[i][0] = @data[i][0].split(", ")
        #hash acts to avoid multiple resolves
        @data[i][0].each_with_index do |name, j|
          if name.include? TERM_STR
            if @id_names.has_key? name
              @data[i][0][j] = @id_names[name]
            else
              @data[i][0][j] = resolve_name(name.sub(TERM_STR, "")) if request_resolve
              @data[i][0][j] = 'FB_USER ' + name.sub(TERM_STR, "") if (request_resolve && @data[i][0][j] == nil) || !request_resolve
              @id_names[name] = @data[i][0][j]
            end
          else
            @data[i][0][j] = name
            @id_names[name] = name
          end
        end
    end
  end

  def resolve_names()
    @id_names.each do |k, v|
      @id_names[k] = resolve_name(k.sub(TERM_STR, "")) if k != v
      print k
      print ' = '
      puts @id_names[k]
    end
  end

  def parse_messages()  ##TODO check the bounds here, have now shifted out the preamble so need to check this
    warn 'Processing all messages...'
    for i in 1..@data.size - 1 do
      for j in 1..@data[i].size - 1 do
        @data[i][j] = FBmsg.new(@data[i][j])
      end
    end
  end

  def parse_thread(i)
    #TODO check thread number is legit
    for j in 1..@data[i].size - 1 do
      @data[i][j] = FBmsg.new(@data[i][j])
    end

    @threads_parsed[i] = true
  end

  def list_threads(first = 1, last = -1)
    if first == nil || first < 1
      warn 'Var "first" out of bounds. Setting to 1.'
      first = 1
    end
    if last == nil || last < 1 || last >= @data.size
      warn 'Var "last" out of bounds. Setting to last thread.'
      last = @data.size - 1
    end
    for i in first..last
      puts i.to_s + ": " + @data[i][0].join(", ")
    end
  end


  def print_thread(thread, reverse=false, first = 1, last = -1)
    begin

      parse_thread(thread) if !@threads_parsed.include? thread

      if first == nil || first < 1
        warn 'Var "first" out of bounds. Setting to 1.'
        first = 1
      end
      if last == nil || last < 1 || last >= @data[thread].size
        warn 'Var "last" out of bounds. Setting to last message.'
        last = @data[thread].size - 1
      end

      puts 'Participants: ' + @data[thread][0].join(", ")
      puts 'Conversation follows: '
      range = first..last
      range = range.to_a.reverse if reverse
      for i in range do
        if i == first || i == last || @data[thread][i].date != @data[thread][i-1].date
          puts @data[thread][first].date
        end
        print @data[thread][i].time
        print " - "
        if @id_names[@data[thread][i].sender] == nil
          print @data[thread][i].sender
        else
          print @id_names[@data[thread][i].sender]
        end
        print ": "
        puts @data[thread][i].msg
      end

    rescue Interrupt => e
      puts "\nInterrupted."
      return
    end
  end

  def output_thread(path, thread, reverse=false, first = 1, last = -1)
    parse_thread(thread) if !@threads_parsed.include? thread

    if first == nil || first < 1
      warn 'Var "first" out of bounds. Setting to 1.'
      first = 1
    end
    if last == nil || last < 1 || last >= @data[thread].size
      warn 'Var "last" out of bounds. Setting to last message.'
      last = @data[thread].size - 1
    end

    f = File.open(path, 'w')


    f.puts 'Participants: ' + @data[thread][0].join(", ")
    f.puts 'Conversation follows: '
    range = first..last
    range = range.to_a.reverse if reverse
    for i in range do
      if i == first || i == last || @data[thread][i].date != @data[thread][i-1].date
        f.puts @data[thread][first].date
      end
      f.print @data[thread][i].time
      f.print " - "
      f.print @data[thread][i].sender
      f.print ": "
      f.puts @data[thread][i].msg
    end
  end

  def list_users(r = nil)
    if r == nil
      @id_names.each do |k, v|
        puts v
      end
    else
      @id_names.each do |k, v|
        puts v if v.match?(r)
      end
    end
  end

  #accepts an array of users, or a regexp, and returns array of all messages from them
  #TODO get this to check the id_names hash
  def search_users(users)
    results = Array.new()

    if users == nil
      for i in 1..@data.size - 1 do
        parse_thread(i) if !@threads_parsed.include? i
        for j in 1..@data[i].size - 1 do
          results.push([ i, j ])
        end
      end
    else
      if users.is_a? Array
        for i in 1..@data.size - 1 do
          common = @data[i][0] & users
          if common.empty?
            next
          else
            parse_thread(i) if !@threads_parsed.include? i
            for j in 1..@data[i].size - 1 do
              if common.include? @data[i][j].sender
                results.push([ i, j ]) #format is [thread, #, FBmsg]
              end
            end
          end
        end
      elsif users.is_a? Regexp
        for i in 1..@data.size - 1 do
          common = @data[i][0].map { |name| name if name.match?(users)}
          if common.empty?
            next
          else
            parse_thread(i) if !@threads_parsed.include? i
            for j in 1..@data[i].size - 1 do
              if common.include? @data[i][j].sender
                results.push([ i, j ]) #format is [thread, #, FBmsg]  ???
              end
            end
          end
        end
      end
    end

    return results
  end

  #accepts an array of strings, or a regexp, and returns array of all messages containing
  def search_msgs(text, presearch = nil)
    puts text
    results = Array.new()
    if text == nil || text == []
      return presearch
    else
      if text.is_a? Array
        presearch.each do |r|
          text.each do |string|
            if (@data[r[0]][r[1]].msg != nil) && (@data[r[0]][r[1]].msg.include? string)
              results.push(r)
              break
            end
          end
        end
      elsif text.is_a? Regexp
        presearch.each do |r|
          if (@data[r[0]][r[1]].msg != nil) && (@data[r[0]][r[1]].msg.match? text)
            results.push(r)
            break
          end
        end
      end
    end
    return results
  end


  def print_search(users, text, reverse = false) #TODO time range
    begin
      results = search_msgs(text, search_users(users))
      results.reverse! if reverse
      results.each_with_index do |r, index|
        if index == 0 || results[index][0] != results[index - 1][0]
          puts 'Thread ' + r[0].to_s
          puts 'Participants: ' + @data[r[0]][0].join(", ")
          puts @data[r[0]][r[1]].date
        elsif @data[r[0]][r[1]].date != @data[results[index-1][0]][results[index-1][1]].date
          puts @data[r[0]][r[1]].date
        end
        print @data[r[0]][r[1]].time
        print " - "
        print @data[r[0]][r[1]].sender
        print ": "
        puts @data[r[0]][r[1]].msg
      end
    rescue Interrupt => e
      puts "\nInterrupted."
      return
    end
  end

  def output_search(path, users, text, reverse = false) #TODO time range
    begin
      f = File.open(path, 'w')
      print 'Working... '
      results = search_msgs(text, search_users(users))
      results.reverse! if reverse
      results.each_with_index do |r, index|
        if index == 0 || results[index][0] != results[index - 1][0]
          f.puts 'Thread ' + r[0].to_s
          f.puts 'Participants: ' + @data[r[0]][0].join(", ")
          f.puts @data[r[0]][r[1]].date
        elsif @data[r[0]][r[1]].date != @data[results[index-1][0]][results[index-1][1]].date
          f.puts @data[r[0]][r[1]].date
        end
        f.print @data[r[0]][r[1]].time
        f.print " - "
        f.print @data[r[0]][r[1]].sender
        f.print ": "
        f.puts @data[r[0]][r[1]].msg
      end
      puts 'Done.'
    rescue Interrupt => e
      f.puts "\nInterrupted."
      puts "Interrupted."
      return
    end
  end
end
