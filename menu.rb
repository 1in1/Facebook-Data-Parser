#q is a reserved option for quit
#other options can be defined by Procs supplied in
#the hash passed as options
class Menu
  def initialize(options, desc, banner, indent = '')
    @options = options
    @desc = desc
    @indent = indent
    print banner
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
    begin
      loop do
        print @indent
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


end
