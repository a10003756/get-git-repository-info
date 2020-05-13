require './lib/class/github_data_collector.rb'

class Command
  
  def initialize(arguments)
    @arguments = arguments
  end
  
  def judgment_command(arguments = @arguments)
    if arguments.size == 0 || arguments.size > 1 || arguments[0] == "-h" 
      puts "第1引数に調べたいGithubのアカウント名を入力してください"
    elsif arguments.size == 1
      GithubDataCollector.receive_github_http_response(@arguments)
    end
  end
end