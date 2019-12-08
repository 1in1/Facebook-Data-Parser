require 'rest-client'

### Header ###
#Defining all the constants used here, quite a few
#Regexp objects as well as strings

BANNER = <<BAN




                      bbbbbbbb                        dddddddd
    ffffffffffffffff  b::::::b                        d::::::d                            ))))))
   f::::::::::::::::f b::::::b                        d::::::d                           )::::::))
  f::::::::::::::::::fb::::::b                        d::::::d                            ):::::::))
  f::::::fffffff:::::f b:::::b                        d:::::d                              )):::::::)
  f:::::f       ffffff b:::::bbbbbbbbb        ddddddddd:::::dppppp   ppppppppp               )::::::)
  f:::::f              b::::::::::::::bb    dd::::::::::::::dp::::ppp:::::::::p   ::::::      ):::::)
 f:::::::ffffff        b::::::::::::::::b  d::::::::::::::::dp:::::::::::::::::p  ::::::      ):::::)
 f::::::::::::f        b:::::bbbbb:::::::bd:::::::ddddd:::::dpp::::::ppppp::::::p ::::::      ):::::)
 f::::::::::::f        b:::::b    b::::::bd::::::d    d:::::d p:::::p     p:::::p             ):::::)
 f:::::::ffffff        b:::::b     b:::::bd:::::d     d:::::d p:::::p     p:::::p             ):::::)
  f:::::f              b:::::b     b:::::bd:::::d     d:::::d p:::::p     p:::::p             ):::::)
  f:::::f              b:::::b     b:::::bd:::::d     d:::::d p:::::p    p::::::p ::::::     )::::::)
 f:::::::f             b:::::bbbbbb::::::bd::::::ddddd::::::ddp:::::ppppp:::::::p ::::::   )):::::::)
 f:::::::f             b::::::::::::::::b  d:::::::::::::::::dp::::::::::::::::p  ::::::  ):::::::))
 f:::::::f             b:::::::::::::::b    d:::::::::ddd::::dp::::::::::::::pp          )::::::)
 fffffffff             bbbbbbbbbbbbbbbb      ddddddddd   dddddp::::::pppppppp             ))))))
                                                              p:::::p
                                                              p:::::p
                                                             p:::::::p
                                                             p:::::::p
                                                             p:::::::p
                                                             ppppppppp




BAN
TERM_STR = '&#064;facebook.com'
TARG_STR = 'www.facebook.com/'
HTML_REGEX_NAME = /(?<pre>\"Person\",\"name\":\")(?<inner>[\w\s]*)(?<post>\",\")/
MSG_REGEX_BODY = /(?<pre><p>)(?<inner>.*)(?<post><\/p>)/
MSG_REGEX_SNDR = /(?<pre><span class="user">)(?<inner>[\w\s\d&#;.]*)(?<post><\/span>)/
MSG_REGEX_DATETIME = /(?<pre><span class="meta">)(?<inner>[\w\s\d,:+-]*)(?<post><\/span>)/
XML_REGEX_PUNCT_CAPTURE = /&(#039|quot);/
XML_REGEX_PUNCT_REPLACE = {'&#039;' => "'", '&quot;' => '"'}


### Begin classes ###


#FMmsgdata object holds the data and acts as an interface
class FBmsgdata
  class FBmsg
    def initialize(xmlmsg)
      @message = xmlmsg[MSG_REGEX_BODY, "inner"]
      @message.gsub!(XML_REGEX_PUNCT_CAPTURE, XML_REGEX_PUNCT_REPLACE) unless @message == nil
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
            @id_names[name] = name
          end
        end
    end
  end

  def resolve_names()
    @id_names.each do |k, v|
      @id_names[k] = resolve_name(k.sub(TERM_STR, "")) if k != v
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
    #TODO check thread number is legit
    for j in 1..@data[i].size - 1 do
      @data[i][j] = FBmsg.new(@data[i][j])
    end

    @threads_parsed[i] = true
  end

  def list_threads(first = 1, last = -1)
    if first == nil || first < 1
      STDERR.puts 'Var "first" out of bounds. Setting to 1.'
      first = 1
    end
    if last == nil || last < 1 || last >= @data.size
      STDERR.puts 'Var "last" out of bounds. Setting to last thread.'
      last = @data.size - 1
    end
    @data.each_with_index do |t, i|
      puts i.to_s + ": " + t[0].join(", ") if (i >= first && i <= last)
    end
  end


  def print_thread(num, first = 1, last = -1, reverse=false)
    parse_thread(num) if !@threads_parsed.include? num

    if first == nil || first < 1
      STDERR.puts 'Var "first" out of bounds. Setting to 1.'
      first = 1
    end
    if last == nil || last < 1 || last >= @data[num].size
      STDERR.puts 'Var "last" out of bounds. Setting to last message.'
      last = @data[num].size - 1
    end

    puts 'Participants: ' + @data[num][0].join(", ")
    puts 'Conversation follows: '
    range = first..last
    range = range.to_a.reverse if reverse
    for i in range do
      print @data[num][i].time
      print " - "
      print @data[num][i].sender
      print ": "
      puts @data[num][i].msg
    end
  end

  def output_thread(path, num, first = 1, last = -1, reverse=false)
    parse_thread(num) if !@threads_parsed.include? num

    if first == nil || first < 1
      STDERR.puts 'Var "first" out of bounds. Setting to 1.'
      first = 1
    end
    if last == nil || last < 1 || last >= @data[num].size
      STDERR.puts 'Var "last" out of bounds. Setting to last message.'
      last = @data[num].size - 1
    end

    f = File.open(path, 'w')


    f.puts 'Participants: ' + @data[num][0].join(", ")
    f.puts 'Conversation follows: '
    range = first..last
    range = range.to_a.reverse if reverse
    for i in range do
      f.print @data[num][i].time
      f.print " - "
      f.print @data[num][i].sender
      f.print ": "
      f.puts @data[num][i].msg
    end
  end
end


#q is a reserved option for quit
#other options can be defined by Procs supplied in
#the hash passed as options
class Menu
  def initialize(options, desc)
    @options = options
    @desc = desc
    print BANNER
    print_options()
  end

  def print_options()
    puts 'Options: '
    @desc.each do |k, v|
      puts ' ' + k + ' - ' + @desc[k]
    end
    puts ' q - Quit.'
  end

  def idle()
    loop do
      print '> '
      input = gets.strip.split
      if @options.include? input[0]
        @options[input[0]].call(input)
      elsif input[0] == 'q' || input[0] == 'Q'
        break
      else
        puts 'Unrecognised input'
        print_options()
      end
    end
  end
end




### SCRIPT RUNTIME BEGINS ###


print 'Path to messages.htm: '
path = gets.chomp
x = FBmsgdata.new(path)

print_thread = Proc.new do |args|
  if args[1] == 'r' || args[1] == 'R'
     x.print_thread(args[2].to_i, args[3].to_i, args[4].to_i, true)
   else
     x.print_thread(args[1].to_i, args[2].to_i, args[3].to_i, false)
   end
end

list_threads = Proc.new do |args|
  x.list_threads(args[1].to_i, args[2].to_i)
end

output_thread = Proc.new do |args|
  if args[2] == 'r' || args[2] == 'R'
     x.output_thread(args[1], args[3].to_i, args[4].to_i, args[5].to_i, true)
   else
     x.output_thread(args[1], args[2].to_i, args[3].to_i, args[4].to_i, false)
   end
end

#TODO COME BACK AND CHANGE THE IMPLEMENTATION OF THE PRINTING STUFF EARLIER
#SO THAT IT PRINTS THE VALUE STORED IN THE HASH, ALWAYS
resolve_post_init = Proc.new do |args|
  print 'Warning: this can take a while with lots of unique users. Proceed? (y/n) '
  confirm = gets.strip
  x.resolve_names() if confirm == 'y' or confirm == 'Y'
end


o = {'p' => print_thread, 'l' => list_threads, 'o' => output_thread, 'res' => resolve_post_init}
d = {'p' => 'Prints the messages in the given thread (default all). p x m n will print the xth thread from the mth to the nth message',
  'l' => 'Lists the available threads (default all), and participants. l m n will list from the mth the nth thread.',
  'o' => 'Output a thread to file. All p flags work. Must specify a valid path as the first argument, eg o %somepath%\out.txt x m n',
  'res' => "Attempts to resolve the names of users where the data wasn't provided, by GETing the URI.",
  'r' => 'Reverse the order of output. Works with p, o. Must be specified afterwards, eg p r x m n'}

m = Menu.new(o, d)
m.idle()
