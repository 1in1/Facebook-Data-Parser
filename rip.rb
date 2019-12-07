
require 'rest-client'

BANNER = 'FB Message Parser'
P_MESS = 'D:\Other\facebook data\html\messages.htm'
TERM_STR = '&#064;facebook.com'
TARG_STR = 'www.facebook.com/'
HTML_REGEX_NAME = /(?<pre>\"Person\",\"name\":\")(?<inner>[\w\s]*)(?<post>\",\")/
MSG_REGEX_BODY = /(?<pre><p>)(?<inner>.*)(?<post><\/p>)/
MSG_REGEX_SNDR = /(?<pre><span class="user">)(?<inner>[\w\s\d&#;.]*)(?<post><\/span>)/
MSG_REGEX_DATETIME = /(?<pre><span class="meta">)(?<inner>[\w\s\d,:+-]*)(?<post><\/span>)/
HTML_CODE_APOS = '&#039;'

#object holds the data and acts as an interface
class FBmsgdata
  class FBmsg
    def initialize(xmlmsg)
      @message = xmlmsg[MSG_REGEX_BODY, "inner"]#.gsub(HTML_CODE_APOS, "\'")
      @sender = xmlmsg[MSG_REGEX_SNDR, "inner"]   #rip resolved names from the hash table
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
      parse_names(request_resolve)
      #parse_messages()
      STDERR.puts "Ready."
  end

  def threads
    @data end

  def resolve_name(id)
    #add in capabilities to grab a cookie to use for private facebooks, add error handling
    return RestClient.get(TARG_STR + id).body[HTML_REGEX_NAME, "inner"]
  end

  private :resolve_name



  def parse_names(request_resolve = false)
    @data.each_with_index do |t, i|
      @data[i][0] = @data[i][0].split(", ")
        #hash acts to avoid multiple resolves
        @data[i][0].each_with_index do |name, j|
          if name.include? TERM_STR
            if @id_names.has_key? name
              @data[i][0][j] = @id_names[name]
            else
              @data[i][0][j] = resolve_name(name.sub(TERM_STR, "")) if request_resolve
              @data[i][0][j] = 'FB_USER: ' + name.sub(TERM_STR, "") if (request_resolve && @data[i][0][j] == nil) || !request_resolve
              @id_names[name] = @data[i][0][j]
            end
          else
            @data[i][0][j] = name
          end
        end
    end
  end

  def parse_messages()
    STDERR.puts 'Processing all messages...'
    for i in 1..@data.size - 1 do
      for j in 1..@data[i].size - 1 do
        STDERR.puts i.to_s + " " + j.to_s
        @data[i][j] = FBmsg.new(@data[i][j])
      end
    end
  end

  def parse_thread(i)
    #check thread number is legit

    for j in 1..@data[i].size - 1 do
      @data[i][j] = FBmsg.new(@data[i][j])
    end

    @threads_parsed[i] = true
  end

  def list_threads(first = 1, last = -1)
    if first < 1
      STDERR.puts 'Var "first" out of bounds. Setting to 1.'
      first = 1
    end
    if last < 1 || last >= @data.size
      STDERR.puts 'Var "last" out of bounds. Setting to last thread.'
      last = @data.size - 1
    end
    @data.each_with_index do |t, i|
      puts i.to_s + ": " + t[0].join(", ") if (i >= first && i <= last)
    end
  end


  def print_thread(num, first = 1, last = 20)
    parse_thread(num) if !@threads_parsed.include? num

    if first < 1
      STDERR.puts 'Var "first" out of bounds. Setting to 1.'
      first = 1
    end
    if last < 1 || last >= @data[num].size
      STDERR.puts 'Var "last" out of bounds. Setting to last message.'
      last = @data[num].size - 1
    end
    puts 'Participants: ' + @data[num][0].join(", ")
    puts 'Conversation follows: '
    for i in first..last do
      print @data[num][i].time
      print " - "
      print @data[num][i].sender
      print ": "
      puts @data[num][i].msg
    end
  end
end


class Menu
  def initialize(options, desc)
    puts BANNER
    puts 'Options: '
    options.each do |k, v|
      puts '\"' + k + '\" - ' + desc[k]
    end
  end

  def idle()

  end
end


x = FBmsgdata.new(P_MESS)
loop do
  n = gets.strip.to_i
  x.print_thread(n)
end
