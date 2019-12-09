require '.\menu.rb'
require '.\fbmd.rb'


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


### SCRIPT RUNTIME BEGINS ###


print 'Path to messages.htm: '
path = gets.chomp
x = FBmsgdata.new(path)


### Define procedure calls, what we want our options to do ###


print_thread = Proc.new do |args|
  if args.length < 2
    warn 'print_thread: Not enough arguments.'
    next
  end

  args.shift  #remove the name of the command
  for i in 0..args.length do
    if args[i] == 'r' || args[i] == 'R'
      args.delete_at(i)
      args.insert(1, true)
      break
    end
  end
  args.map! { |f| (f.is_a?(String)) ? (f.to_i):f}
  x.print_thread(*args)
end

list_threads = Proc.new do |args|
  args.shift  #remove the name of the command
  args.map! { |f| (f.is_a?(String)) ? (f.to_i):f} if args != nil
  x.list_threads(*args)
end

list_users = Proc.new do |args|
  args.shift
  if args.empty?
    x.list_users()
  else
    x.list_users(Regexp.new(args.join(" ")))
  end
end

output_thread = Proc.new do |args|
  if args.length < 3
    warn 'output_thread: Not enough arguments.'
    next
  end

  args.shift  #remove the name of the command
  path = args.shift
  for i in 0..args.length do
    if args[i] == 'r' || args[i] == 'R'
      args.delete_at(i)
      args.insert(2, true)
      break
    end
  end
  args.map! { |f| (f.is_a?(String)) ? (f.to_i):f}
  x.print_thread(path, *args)
end

#TODO COME BACK AND CHANGE THE IMPLEMENTATION OF THE PRINTING STUFF EARLIER
#SO THAT IT PRINTS THE VALUE STORED IN THE HASH, ALWAYS
resolve_post_init = Proc.new do |args|
  print 'Warning: this can take a while with lots of unique users. Proceed? (y/n) '
  confirm = gets.strip
  x.resolve_names() if confirm == 'y' or confirm == 'Y'
end




### SEARCH REQUIRES ITS OWN MENU OBJECT ###



s_users = Array.new()
s_text = Array.new()

s_gop = Proc.new do |this, args|
  if args == 'r' || args == 'R'
    x.print_search(s_users, s_text, true)
  else
    x.print_search(s_users, s_text, false)
  end
end

s_goo = Proc.new do |this, args|
  if args[0] == 'r' || args[0] == 'R'
    x.output_search(args[1], s_users, s_text, true)
  elsif  args[1] == 'r' || args[1] == 'R'
    x.output_search(args[0], s_users, s_text, true)
  else
    x.output_search(args, s_users, s_text, true)
  end
end

search = Proc.new do |args|
  begin
    sd = {'go' => 'Runs search with current settings, without printing.',
      'gop' => 'Runs and prints search with current settings.',
      'goo' => 'Runs and outputs search with current settings to file (first arg).',
      '?' => 'Prints current search settings',
      'setu' => 'Populates the users array with the arguments given, COMMA SEPARATED.',
      'setregu' => 'Sets users to a regex, the first argument given.',
      'sett' => 'Populates the "text to search" array with the arguments given, COMMA SEPARATED.',
      'setregt' => 'Sets the match regex to the first argument given.',
      'u' => "Lists participants. Can optionally pass a regex to match against, eg u \bA.* matches everyone who has a name starting with an A.",
      'r' => 'Reverse the order of output.'}

    so = {'gop' => s_gop,
    'goo' => s_goo,
    '?' => Proc.new do
      print 'Users: '
      (!(s_users.is_a?(Array) && s_users.empty?)) ? (puts s_users) : (puts 'Any.')
      print 'Text: '
      (!(s_text.is_a?(Array) && s_text.empty?)) ? (puts s_text) : (puts 'Any.') end,
    'setu' => Proc.new do |args|
      args.shift
      names = args.join(" ").split(",")
      s_users = names
    end,
    'setregu' => Proc.new do |args|
      args.shift
      s_users = Regexp.new(args.join(" "))
    end,
    'sett' => Proc.new do |args|
      args.shift
      words = args.join(" ").split(",")
      s_text = words
    end,
    'setregt' => Proc.new do |args|
      args.shift
      s_text = Regexp.new(args.join(" "))
    end,
    'u' => list_users
    }


    sm = Menu.new(so, sd, '', 'search')
    sm.idle()
  rescue Interrupt => e
    return
  end
end


o = {'p' => print_thread, 'l' => list_threads, 'o' => output_thread, 'res' => resolve_post_init, 'u' => list_users, 's' => search}
d = {'p' => 'Prints the messages in the given thread. p x m n will print the xth thread from the mth to the nth message',
  'l' => 'Lists the available threads (default all), and participants. l m n will list from the mth the nth thread.',
  'o' => 'Output a thread to file. All p flags work. Must specify a valid path as the first argument, eg o %somepath%\out.txt x m n',
  'res' => "Attempts to resolve the names of users where the data wasn't provided, by GETing the URI.",
  'r' => 'Reverse the order of output. Works with p, o, gop, goo. Eg: p r x m n',
  'u' => "Lists participants. Can optionally pass a regex to match against, eg u \bA.* matches everyone who has a name starting with an A.",
  's' => 'Open search mode.'}

m = Menu.new(o, d, BANNER)
m.idle()
